configure_installer() {
  cloud_provider="$1"

  if [ "$cloud_provider" == "cloudscale" ]; then
    echo "Configuring OpenShift installer for cloudscale ..."
  elif [ "$cloud_provider" == "exoscale" ]; then
    echo "Configuring OpenShift installer for Exoscale ..."
    export EXOSCALE_API_KEY="${INPUT_exoscale_key}"
    export EXOSCALE_API_SECRET="${INPUT_exoscale_secret}"
  else
    echo "Configuring OpenShift installer for ${cloud_provider} NYI!"
    exit 1
  fi

  openshift-install() {
    "${INPUT_openshift_install_bin}" "${@}"
  }

  export VAULT_ADDR="${INPUT_vault_address}"
  vault login -method="${INPUT_vault_login_method}"

  ssh_private_key="$(pwd)/ssh_${INPUT_commodore_cluster_id}"
  ssh_public_key="${ssh_private_key}.pub"

  env -i "ssh_public_key_path=$ssh_public_key" >> "$OUTPUT"

  if vault kv get -format=json "clusters/kv/${INPUT_commodore_tenant_id}/${INPUT_commodore_cluster_id}/${cloud_provider}/ssh" >/dev/null 2>&1; then
    echo "SSH keypair for cluster ${INPUT_commodore_cluster_id} already exists in Vault, skipping generation."

    vault kv get -format=json "clusters/kv/${INPUT_commodore_tenant_id}/${INPUT_commodore_cluster_id}/${cloud_provider}/ssh" | \
      jq -r '.data.data.private_key|@base64d' > "${ssh_private_key}"

    chmod 600 "${ssh_private_key}"
    ssh-keygen -f "${ssh_private_key}" -y > "${ssh_public_key}"

  else
    echo "Generating new SSH keypair for cluster ${INPUT_commodore_cluster_id}."

    ssh-keygen -C "vault@${INPUT_commodore_cluster_id}" -t ed25519 -f "$ssh_private_key" -N ''

    base64_no_wrap='base64'
    if [[ "$OSTYPE" == "linux"* ]]; then
      base64_no_wrap='base64 --wrap 0'
    fi

    vault kv put "clusters/kv/${INPUT_commodore_tenant_id}/${INPUT_commodore_cluster_id}/${cloud_provider}/ssh" \
      private_key="$($base64_no_wrap "$ssh_private_key")"
  fi

  echo Adding SSH private key to ssh-agent...
  echo You might need to start the ssh-agent first using: eval "\$(ssh-agent)"
  echo ssh-add "$ssh_private_key"
  ssh-add "$ssh_private_key"

  installer_dir="$(pwd)/target"
  rm -rf "${installer_dir}"
  mkdir -p "${installer_dir}"

  echo "Adding Cilium registry mirror pull secret to cluster pull secret"
  if [[ "${INPUT_vault_address}" == "https://vault-prod.syn.vshn.net"* ]]; then
    prefix=""
  elif [[ "${INPUT_vault_address}" == "https://vault-int.syn.vshn.net"* ]]; then
    prefix="int_"
  elif [[ "${INPUT_vault_address}" == "https://vault-dev.syn.vshn.net"* ]]; then
    prefix="dev_"
  else
    echo "Unknown Vault instance ${INPUT_vault_address}, Cilium registry mirror pull secret may be incorrect."
    prefix=""
  fi
  registry_password=$(vault kv get -format=json \
    "clusters/kv/${INPUT_commodore_tenant_id}/${INPUT_commodore_cluster_id}/steward" \
    | jq -r '.data.data.token' | tr -d '\n' | sha256sum | cut -d ' ' -f1)
  pull_secret=$(jq -r -n -c \
    --argjson pull "${INPUT_redhat_pull_secret}" \
    --arg registry_password "$registry_password" \
    --arg cluster_id "${prefix}${INPUT_commodore_cluster_id}" \
    '{
      "auths": $pull.auths + {"icr-mirror.vshn.net":{"auth":"\($cluster_id):\($registry_password)"|@base64}}
    }')

  cat > "${installer_dir}/install-config.yaml" <<EOF
  apiVersion: v1
  metadata:
    name: ${INPUT_commodore_cluster_id} 
  baseDomain: ${INPUT_base_domain} 
  platform:
    external:
      platformName: ${cloud_provider}
      cloudControllerManager: External
  networking: 
    networkType: Cilium
  pullSecret: |
    ${pull_secret}
  sshKey: "$(cat "$ssh_public_key")"
EOF

  echo Running OpenShift installer to create manifests...
  openshift-install --dir "${installer_dir}" create manifests

  echo Copying machineconfigs...
  machineconfigs=catalog/manifests/openshift4-nodes/10_machineconfigs.yaml
  if [ -f $machineconfigs ];  then
    yq --no-doc -s \
      "\"${installer_dir}/openshift/99x_openshift-machineconfig_\" + .metadata.name" \
      $machineconfigs
  fi

  if [ "$cloud_provider" == "cloudscale" ]; then
    echo Copying Cloudscale CCM manifests...
    for f in catalog/manifests/cloudscale-cloud-controller-manager/*; do
      cp "$f" "${installer_dir}/manifests/cloudscale_ccm_$(basename "$f")"
    done
    yq -i e ".stringData.access-token=\"${INPUT_cloudscale_token}\"" \
      "${installer_dir}/manifests/cloudscale_ccm_01_secret.yaml"
  elif [ "$cloud_provider" == "exoscale" ]; then
    echo Copying Exoscale CCM manifests...
    for f in catalog/manifests/exoscale-cloud-controller-manager/manager/*; do
      cp "$f" "${installer_dir}/manifests/exoscale_ccm_$(basename "$f")"
    done

    yq -i e ".stringData.api-key=\"${INPUT_ccm_key}\",.stringData.api-secret=\"${INPUT_ccm_secret}\"" \
      "${installer_dir}/manifests/exoscale_ccm_01_secret.yaml"
  fi

  echo Copying Cilium OLM manifests...
  cilium_manifests="catalog/manifests/cilium/olm/[a-z]*"
  # shellcheck disable=2086
  if [ "$(yq eval-all '[.kind=="Deployment"]|any' $cilium_manifests)" == "false" ]; then
    # shellcheck disable=2016
    echo 'Cilium clife-controller-manager deployment missing. Double check that `cilium.olm.generate_olm_deployment=true` in the cluster config'
    exit 1
  fi
  for f in $cilium_manifests; do
    cp "$f" "${installer_dir}/manifests/cilium_$(basename "$f")"
  done

  cilium_mirror_config=catalog/manifests/cilium/80_enterprise_isovalent_registry_mirror_config.yaml
  if [ -f "$cilium_mirror_config" ]; then
    echo "Copying Cilium registry mirror manifests..."
    yq --no-doc -s \
      "\"${installer_dir}/manifests/cilium_\" + (.kind|downcase)" \
      "$cilium_mirror_config"
  fi

  # shellcheck disable=2016
  # We don't want the shell to execute network.operator.openshift.io as a
  # command, so we need single quotes here.
  echo 'Generating initial `network.operator.openshift.io` resource...'
  yq '{
  "apiVersion": "operator.openshift.io/v1",
  "kind": "Network",
  "metadata": {
    "name": "cluster"
  },
  "spec": {
    "deployKubeProxy": false,
    "clusterNetwork": .spec.clusterNetwork,
    "externalIP": {
      "policy": {}
    },
    "networkType": "Cilium",
    "serviceNetwork": .spec.serviceNetwork
  }}' "${installer_dir}/manifests/cluster-network-02-config.yml" \
  > "${installer_dir}/manifests/cilium_cluster-network-operator.yaml"

  gen_cluster_domain=$(yq e '.spec.baseDomain' \
    "${installer_dir}/manifests/cluster-dns-02-config.yml")
  if [ "$gen_cluster_domain" != "$INPUT_cluster_domain" ]; then
    echo -e "\033[0;31mGenerated cluster domain doesn't match expected cluster domain: Got '$gen_cluster_domain', want '$INPUT_cluster_domain'\033[0;0m"
    exit 1
  else
    echo -e "\033[0;32mGenerated cluster domain matches expected cluster domain.\033[0;0m"
  fi

  echo Running OpenShift installer to create ignition configs...
  openshift-install --dir "${installer_dir}" \
    create ignition-configs

  if [ "$cloud_provider" == "cloudscale" ]; then
    mc alias set \
      "${INPUT_commodore_cluster_id}" "https://objects.${INPUT_csp_region}.cloudscale.ch" \
      "$(echo "$INPUT_bucket_user" | jq -r '.keys[0].access_key')" \
      "$(echo "$INPUT_bucket_user" | jq -r '.keys[0].secret_key')"

    mc cp "${installer_dir}/bootstrap.ign" "${INPUT_commodore_cluster_id}/${INPUT_commodore_cluster_id}-bootstrap-ignition/"

    ignition_bootstrap=$(mc share download \
      --json --expire=24h \
      "${INPUT_commodore_cluster_id}/${INPUT_commodore_cluster_id}-bootstrap-ignition/bootstrap.ign" | jq -r '.share')

  elif [ "$cloud_provider" == "exoscale" ]; then
    exo storage upload "${installer_dir}/bootstrap.ign" "sos://${INPUT_commodore_cluster_id}-bootstrap" --acl private
    ignition_bootstrap=$(exo storage presign "sos://${INPUT_commodore_cluster_id}-bootstrap/bootstrap.ign" --expires "24h" --method "get")
  fi
  env -i "ignition_bootstrap=$ignition_bootstrap" >> "$OUTPUT"

  echo "✅ OpenShift installer configured successfully."
}
