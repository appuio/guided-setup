Given I have all prerequisites installed
And I download the `openshift-install` binary for version "4.22"
And a lieutenant cluster
And a Keycloak service
And a cloudscale API token
And a personal VSHN GitLab access token
And basic cluster information
Then I download the OpenShift image for version "4.22.0"
And I set up required S3 buckets
And I import the image in Cloudscale
Then I set secrets in Vault
And I check the cluster domain
And I prepare the cluster repository
Then I configure the OpenShift installer
And I configure Terraform for team "aldebaran"
And I configure Terraform for Cloudscale
Then I provision the cloudscale LBs and router
And I provision the bootstrap node and control plane
And I store the subnet ID and floating IP in the Syn hierarchy
Then I deploy initial manifests
And I wait for bootstrap to complete
Then I remove the bootstrap node
And I configure initial deployments
And I wait for installation to complete
Then I synthesize the cluster
Then I set acme-dns CNAME records
And I verify emergency access
And I configure the cluster alerts
And I enable Opsgenie alerting
And I verify the image registry config
And I wait until all ArgoCD apps are synced and healthy
And I schedule the first maintenance
And I remove the bootstrap bucket
And I wait for maintenance to complete
