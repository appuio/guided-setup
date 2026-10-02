Given I have all prerequisites installed
And a lieutenant cluster
And a personal VSHN GitLab access token
And I have the cluster's cloudscale token
And a dummy control.vshn.net API token
And I have emergency cluster access
Then I confirm cluster deletion
Then I disable the OpsGenie heartbeat
And I disable Project Syn
And I delete all Load Balancer services and Load Balancers
And I disable machine autoscaling
And I delete all persistent volumes
And I delete all machinesets
Then I compile the cluster catalog
And I decommission Terraform resources
Then I delete Cloudscale server groups
And I delete all S3 buckets
And I delete the cluster backup
And I delete the cluster's API tokens
And I remove the cluster's DNS entries
Then I delete the cluster's Vault secrets
And I delete the cluster's OpsGenie heartbeat
And I delete the cluster from Lieutenant
And I delete the Keycloak service
