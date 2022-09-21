# tf-hcp-transit-gateway
The intent of this demo is to guide you through a way to set up communication between your EC2 instances inside of a Private subnet inside of a VPC in AWS and a Vault cluster inside of the same region in an HVN in HCP. The method used is via a Transit Gateway in the region selected and configuring the necessary routes to do so. A few EC2 instances are created in this demo to simulate a means to SSH into the private instances without a public IP and then configuring the needed pieces inside of vault from one and then retrieving the secret from another. The second private instance will utilize the vault agent to invoke a role created in vault to retrieve a secret created in vault as well. Keep in mind that not all regions are currently supported by HCP (i.e. us-east-2).

## Prep:

1) Identify an ssh key in the desired region you will be deploying this to so that you can ssh into the instances created. If you do not have one already, create one via the AWS UI and store it in your preferred directory for SSH.

2) Configure AWS CLI, and/or any environment variables necessary to use aws CLI so that Terraform can utilize the appropriate credentials for the desired environment.

3) Download the latest version of Terraform. This repo was designed on v1.1.9, in case you run into incompatibilities with newer versions. https://learn.hashicorp.com/tutorials/terraform/install-cli

4) Create an HCP Service Principal to use in the Terraform var.tfvars file: https://cloud.hashicorp.com/docs/hcp/admin/service-principals

## Walkthrough:

1) Download the repo to your local machine.

2) Once downloaded, you will notice a var.tfvars file in the root of the directory. Make sure to fill this out with information respective to your AWS environment, and your desired HCP environment. You may need to create your HCP credentials first here: https://cloud.hashicorp.com/docs/hcp/admin/service-principals

3) The terraform template is set up in a fashion that expects the user to have their AWS CLI config set up in their environment so that the credentials are available to Terraform. More information on that here: https://registry.terraform.io/providers/hashicorp/aws/latest/docs

4) Run the following to verify that everything looks good from the root of your recently downloaded repo directory:
```
terraform plan --var-file=var.tfvars
```

5) If the above does not return any errors and shows all of what it expects to deploy, then run the following and type ‘yes’ when prompted followed by the enter key:
```
terraform apply --var-file=var.tfvars
```

6) This is going to take a while to set everything up, so go have a tea or coffee.

7) Once terraform has spun all of the necessary pieces up it’s time to ssh from your local machine to the jump box and then into the vault management instance, so navigate to the instances in AWS and grab the private IP for the vault management instance and the public IP of the jumpbox instance.
- a) SSH to the jumpbox instance: 
```
ssh -A -i /path/to/ssh/key.pem ec2-user@<your-jumbox-public-ip>
```
- b) SSH to the vault management instance: 
```
ssh ec2-user@<your-vault-management-private-ip>
```

8) Install Vault: https://learn.hashicorp.com/tutorials/vault/getting-started-install?in=vault/getting-started

9) Identify the private vault address by navigating to the Overview page for your cluster in HCP and selecting the ‘Private’ hyperlink to the right of Cluster URLs. This will copy it to clipboard.

10) Create an Admin token to be used in future steps. Select the ‘+Generate token’ button and then copy the token created.

11) Configure necessary environment variables:
```
export VAULT_ADDR='<copied-text-from-step9>'
export VAULT_TOKEN="<copied-token-from-step10>"
export VAULT_NAMESPACE='admin'
```

12) Check to make sure you can run the following and get information similar returned:
```
[ec2-user@]$ vault status
Key                      Value
---                      -----
Recovery Seal Type       shamir
Initialized              true
Sealed                   false
Total Recovery Shares    1
Threshold                1
Version                  1.10.3+ent
Build Date               n/a
Storage Type             raft
Cluster Name             vault-cluster-b51d4933
Cluster ID               00000000-0000-0000-0000-000000000000
HA Enabled               true
HA Cluster               https://172.12.34.123:8201
HA Mode                  active
Active Since             2022-09-14T00:23:17.619055147Z
Raft Committed Index     52687
Raft Applied Index       52687
Last WAL                 13195
[ec2-user@]$ vault secrets list
Path          Type            Accessor                 Description
----          ----            --------                 -----------
cubbyhole/    ns_cubbyhole    ns_cubbyhole_847f2ea2    per-token private secret storage
identity/     ns_identity     ns_identity_0991c2be     identity store
sys/          ns_system       ns_system_088f5f3a       system endpoints used for control, policy and debugging
```

- **If you get similar responses to the above, then your environment variables were set correctly!**

13) Configure an approle role in vault, along with a secret id for the role to authenticate, make sure to copy down the role_id and secret_id for use in future steps:
```
[ec2-user@]$ vault auth enable approle
Success! Enabled approle auth method at: approle/
[ec2-user@]$ vault write auth/approle/role/my-role secret_id_ttl=10m token_num_uses=10 token_ttl=20m token_max_ttl=30m secret_id_num_uses=40
Success! Data written to: auth/approle/role/my-role
[ec2-user@]$ vault read auth/approle/role/my-role/role-id
Key        Value
---        -----
role_id    00000000-0000-0000-0000-000000000000
[ec2-user@]$ vault write -f auth/approle/role/my-role/secret-id
Key                   Value
---                   -----
secret_id             00000000-0000-0000-0000-000000000000
secret_id_accessor    00000000-0000-0000-0000-000000000000
secret_id_ttl         10m
```

14) Create a secret in the kv (version 2) secrets engine so that the agent has something to grab:
```
[ec2-user@]$ vault secrets enable kv-v2
Success! Enabled the kv-v2 secrets engine at: kv-v2/
[ec2-user@]$ vault kv put -mount=kv-v2 my-secret foo=a bar=b
==== Secret Path ====
kv-v2/data/my-secret

======= Metadata =======
Key                Value
---                -----
created_time       2022-09-15T22:05:25.086946974Z
custom_metadata    <nil>
deletion_time      n/a
destroyed          false
version            1
[ec2-user@]$ vault kv get kv-v2/my-secret
==== Secret Path ====
kv-v2/data/my-secret

======= Metadata =======
Key                Value
---                -----
created_time       2022-09-15T22:05:25.086946974Z
custom_metadata    <nil>
deletion_time      n/a
destroyed          false
version            1

=== Data ===
Key    Value
---    -----
bar    b
foo    a
```

15) Create a policy and add it to the role created earlier. The policy will allow the role permissions to read the secret’s values:
```
[ec2-user@]$ vault policy write my-secret-policy - << EOF
path "kv-v2/data/my-secret" {
capabilities = ["read"]
}
EOF
[ec2-user@]$vault write auth/approle/role/my-role token_policies=my-secret-policy
Success! Data written to: auth/approle/role/my-role
```

16) Now it’s time to ssh from the jump box into the other private instance, so navigate to the instances in AWS and grab the private IP for the web application instance.
- a) logout back to the jumpbox instance: 
```
$ exit
logout
Connection to <your-vault-management-private-ip> closed.
```
- b) SSH to the vault management instance: 
```
$ ssh ec2-user@<your-web-application-private-ip>
```

17) Install Vault: https://learn.hashicorp.com/tutorials/vault/getting-started-install?in=vault/getting-started

18) Configure necessary environment variables:
```
export VAULT_ADDR='<copied-text-from-step9>'
export VAULT_TOKEN="<copied-token-from-step10>"
export VAULT_NAMESPACE='admin'
```

19) Create the following folder structure under /home/ec2-user:
```
[ec2-user@]$ pwd
/home/ec2-user
[ec2-user@]$ mkdir vault
[ec2-user@]$ cd vault/
[ec2-user@]$ mkdir agent
[ec2-user@]$ cd agent
[ec2-user@]$ pwd
/home/ec2-user/vault/agent
[ec2-user@]$ mkdir outputs
[ec2-user@]$ mkdir 'sink-file'
[ec2-user@]$ mkdir keys
```

- **The folder structure should look like this under /home/ec2-user**
```
/home/ec2-user/vault
└── agent
    ├── keys
    ├── outputs

        └── sink-file
```

20) Navigate to /home/ec2-user/vault/agent and place the following into a file called agent-config.hcl:
```
vault {
  address = "<copied-text-from-step9>"
  retry {
    num_retries = 5
  }
}

auto_auth {
  method {
    type      = "approle"
    namespace = "admin"
    mount_path = "auth/approle"

    config = {
      role_id_file_path = "/home/ec2-user/vault/agent/keys/roleid"
      secret_id_file_path = "/home/ec2-user/vault/agent/keys/secretid"
      remove_secret_id_file_after_reading = false
    }
  }

  sink {
    type = "file"
    config = {
      path = "/home/ec2-user/vault/agent/sink-file/sink_file_unwrapped.txt"
    }
  }
}

cache {
  use_auto_auth_token = true
}

template_config {
  static_secret_render_interval = "10m"
  exit_on_retry_failure = true
}

template {
  contents     = "{{ with secret \"kv-v2/data/my-secret\" }}{{ .Data.data.foo }}{{ end }}"
  destination  = "/home/ec2-user/vault/agent/outputs/render-content.txt"
}
```

21) Navigate to /home/ec2-user/vault/agent/keys and place the copied role-id from earlier in step 13 into a file labeled ‘roleid’.

22) Navigate to /home/ec2-user/vault/agent/keys and place the copied secret-id from earlier in step 13 into a file labeled ‘secretid’. If you took longer than 10 minutes to get from step 13 to here, you will likely need to create a new secret-id following the last part of step 13, copy the new secret-id and place it into the previously mentioned file in this step. You know fairly quickly if when you run the next step you get an error about invalid secretid.

23) Navigate to /home/ec2-user/vault/agent and run the following:
```
[ec2-user@]$ vault agent -config=agent-config.hcl
==> Vault agent started! Log data will stream in below:

==> Vault agent configuration:

           Api Address 1: http://bufconn
                     Cgo: disabled
               Log Level: info
                 Version: Vault v1.11.3, built 2022-08-26T10:27:10Z
             Version Sha: 17250b25303c6418c283c95b1d5a9c9f16174fe8

2022-09-19T22:09:03.032Z [INFO]  sink.file: creating file sink
2022-09-19T22:09:03.033Z [INFO]  sink.file: file sink configured: path=/home/ec2-user/vault/agent/sink-file/sink_file_unwrapped.txt mode=-rw-r-----
2022-09-19T22:09:03.033Z [INFO]  template.server: starting template server
2022-09-19T22:09:03.033Z [INFO] (runner) creating new runner (dry: false, once: false)
2022-09-19T22:09:03.033Z [INFO]  auth.handler: starting auth handler
2022-09-19T22:09:03.033Z [INFO]  auth.handler: authenticating
2022-09-19T22:09:03.034Z [INFO] (runner) creating watcher
2022-09-19T22:09:03.034Z [INFO]  sink.server: starting sink server
2022-09-19T22:09:03.077Z [INFO]  auth.handler: authentication successful, sending token to sinks
2022-09-19T22:09:03.077Z [INFO]  auth.handler: starting renewal process
2022-09-19T22:09:03.077Z [INFO]  sink.file: token written: path=/home/ec2-user/vault/agent/sink-file/sink_file_unwrapped.txt
2022-09-19T22:09:03.077Z [INFO]  template.server: template server received new token
2022-09-19T22:09:03.078Z [INFO] (runner) stopping
2022-09-19T22:09:03.078Z [INFO] (runner) creating new runner (dry: false, once: false)
2022-09-19T22:09:03.078Z [INFO] (runner) creating watcher
2022-09-19T22:09:03.078Z [INFO] (runner) starting
2022-09-19T22:09:03.080Z [INFO]  cache: received request: method=GET path=/v1/sys/internal/ui/mounts/kv-v2/data/my-secret
2022-09-19T22:09:03.080Z [INFO]  cache.apiproxy: forwarding request: method=GET path=/v1/sys/internal/ui/mounts/kv-v2/data/my-secret
2022-09-19T22:09:03.097Z [INFO]  auth.handler: renewed auth token
2022-09-19T22:09:03.099Z [INFO]  cache: received request: method=GET path=/v1/kv-v2/data/my-secret
2022-09-19T22:09:03.099Z [INFO]  cache.apiproxy: forwarding request: method=GET path=/v1/kv-v2/data/my-secret0
```
24) Cltr+C to exit out of the agent running:
```
^C==> Vault agent shutdown triggered
2022-09-19T22:09:05.674Z [INFO]  sink.server: sink server stopped
2022-09-19T22:09:05.674Z [INFO]  sinks finished, exiting
2022-09-19T22:09:05.674Z [INFO] (runner) stopping
2022-09-19T22:09:05.674Z [INFO]  template.server: template server stopped
2022-09-19T22:09:05.674Z [INFO]  auth.handler: shutdown triggered, stopping lifetime watcher
2022-09-19T22:09:05.674Z [INFO]  auth.handler: auth handler stopped
```

25) Navigate to /home/ec2-user/vault/agent/outputs and check the contents of the following file:
```
[ec2-user@]$ cd outputs/
[ec2-user@]$ cat render-content.txt 
a
```
- **The presence of the ‘a' in the contents of the file shows that the agent was able to use the approle role ‘my-role’ and grab the contents of Data.data.foo from the secret ‘my-secret’**