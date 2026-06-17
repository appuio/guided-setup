Given I have all prerequisites installed
And I download the `openshift-install` binary for version "4.21"
And Cloudscale API tokens
And Xelon API tokens
And a personal VSHN GitLab access token
Then I download the OpenShift OVA image for version "4.21.0"
And I import the image into Xelon
And I set up required S3 buckets
Then I configure the OpenShift installer
Then I prepare for terraform
Then I create the bootstrap node
Then I fix the load balancer
Then I create the control plane nodes
