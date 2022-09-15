# The desired CIDR Range of the HCP HVN.
hvn_cidr = "172.25.16.0/20"

# The alias desired to be used for the KMS key (auto unseal)
kms_alias = ""

# Key name of the SSH key desired to use for the jump box
ssh_key_name = ""

# The prefix used to add to resources created.
resource_prefix = "learn"

# The cloud provider of the HCP HVN and Vault cluster.
cloud_provider = "aws"

# Tier of the HCP Vault cluster. Valid options for tiers.
tier = "dev"

# The first desired availability zone to deploy to
availability_zone_one = "us-east-1a"

# The second desired availability zone to deploy to
availability_zone_two = "us-east-1b"

# CIDR range of the VPC in your personal AWS account you wish to peer to.
primary_vpc_cidr = "10.0.0.0/16"

# CIDR range of Primary Public Subnet A you wish to create.
primary_public_subnet_a_cidr = "10.0.0.0/24"

# CIDR range of Primary Public Subnet B you wish to create.
primary_public_subnet_b_cidr = "10.0.1.0/24"

# CIDR range of Primary Private Subnet A you wish to create.
primary_private_subnet_a_cidr = "10.0.2.0/24"

# CIDR range of Primary Private Subnet B you wish to create.
primary_private_subnet_b_cidr = "10.0.3.0/24"

# AWS Account ID that the VPC belongs to that you wish to peer.
peer_account_id = ""

# The Region that the primary VPC belongs to that you wish to peer.
primary_vpc_region = "us-east-1"

# The Region that the secondary VPC belongs to that you wish to peer.
secondary_vpc_region = "us-west-2"

# The Client ID to be used for the HCP.
hcp_client_id = ""

# The Client Secret to be used for the HCP.
hcp_client_secret = ""

# Instance size of the jumpbox instance to spin up
jumpbox_instance_size = "t3.micro"

# The size on disk of the jumpbox instance
jumpbox_instance_storage = "30"

# The desired CIDR range for allowing to access your jumpbox from the internet
jumpbox_ssh_ingress_cidr = "0.0.0.0/0"
