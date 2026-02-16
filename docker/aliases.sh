
guided-setup-raw() {
  local pubring="${HOME}/.gnupg/pubring.kbx"
  if command -v gpgconf &>/dev/null && test -f "${pubring}"; then
    gpg_opts=(--volume "${pubring}:/app/.gnupg/pubring.kbx:ro" --volume "$(gpgconf --list-dir agent-extra-socket):/app/.gnupg/S.gpg-agent:ro")
  else
    gpg_opts=
  fi

  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
      open="xdg-open"
  elif [[ "$OSTYPE" == "darwin"* ]]; then
      open="open"
  fi

  rm -rf /run/user/$(id -u)/guided-setup-open-browser.sock
  socat \
    unix-listen:/run/user/$(id -u)/guided-setup-open-browser.sock,fork \
    system:"xargs $open" &

  # NOTE(aa): Host network is required for the Vault OIDC callback, since Vault only binds the callback handler to 127.0.0.1
  # cf. https://github.com/hashicorp/vault/issues/29064
  docker run \
    --interactive=true \
    --tty \
    --rm \
    --user="$(id -u)" \
    --env SSH_AUTH_SOCK=/tmp/ssh_agent.sock \
    --network host \
    --volume "${SSH_AUTH_SOCK}:/tmp/ssh_agent.sock" \
    --volume "${HOME}/.ssh/config:/app/.ssh/config:ro" \
    --volume "${HOME}/.ssh/known_hosts:/app/.ssh/known_hosts:ro" \
    --volume "${HOME}/.gitconfig:/app/.gitconfig:ro" \
    --volume "${HOME}/.cache:/app/.cache" \
    --volume "${HOME}/.gandalf:/app/.gandalf" \
    --volume "/run/user/$(id -u)/guided-setup-open-browser.sock:/run/user/$(id -u)/guided-setup-open-browser.sock" \
    ${gpg_opts[@]} \
    --volume "${PWD}:${PWD}" \
    --workdir "${PWD}" \
    2731be73adfe \
    gandalf ${@}
  
  kill $(jobs -p)
  rm -rf /run/user/$(id -u)/guided-setup-open-browser.sock
}

guided-setup() {
  guided-setup-raw run /workflows/${1}.workflow /workflows/${1}/*.yml /workflows/shared/*.yml "${@:2}"
}
