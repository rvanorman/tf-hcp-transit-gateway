variable "hvn_cidr" {
  description = "The CIDR range of the HCP HVN."
  type        = string
}

variable "kms_alias" {
  description = "The alias desired to be used for the KMS key (auto unseal)"
}

variable "ssh_key_name" {
  description = "Key name of the SSH key desired to use for the jump box"
}

variable "resource_prefix" {
  description = "The prefix used to add to resources created."
  type        = string
}

variable "cloud_provider" {
  description = "The cloud provider of the HCP HVN and Vault cluster."
  type        = string
}

variable "tier" {
  description = "Tier of the HCP Vault cluster. Valid options for tiers."
  type        = string
}

variable "availability_zone_one" {
  type        = string
  description = "The first desired availability zone to deploy to"
}

variable "availability_zone_two" {
  type        = string
  description = "The second desired availability zone to deploy to"
}

variable "primary_vpc_cidr" {
  description = "CIDR range of the VPC you wish to peer to."
  type        = string
}

variable "primary_public_subnet_a_cidr" {
  description = "CIDR range of Primary Public Subnet A you wish to create."
  type        = string
}

variable "primary_public_subnet_b_cidr" {
  description = "CIDR range of Primary Public Subnet B you wish to create."
  type        = string
}

variable "primary_private_subnet_a_cidr" {
  description = "CIDR range of Primary Private Subnet A you wish to create."
  type        = string
}

variable "primary_private_subnet_b_cidr" {
  description = "CIDR range of Primary Private Subnet B you wish to create."
  type        = string
}

variable "peer_account_id" {
  description = "AWS Account ID that the VPC belongs to that you wish to peer."
  type        = string
}

variable "primary_vpc_region" {
  description = "The Region that the primary VPC belongs to that you wish to peer."
  type        = string
}

variable "secondary_vpc_region" {
  description = "The Region that the secondary VPC belongs to that you wish to peer."
  type        = string
}

variable "hcp_client_id" {
  description = "The Client ID to be used for the HCP."
  type        = string
}

variable "hcp_client_secret" {
  description = "The Client Secret to be used for the HCP."
  type        = string
}

variable "jumpbox_instance_size" {
  description = "Instance size of the jumpbox instance to spin up"
}

variable "jumpbox_instance_storage" {
  description = "The size on disk of the jumpbox instance"
}

variable "jumpbox_ssh_ingress_cidr" {
  description = "The desired CIDR range for allowing to access your jumpbox from the internet"
}