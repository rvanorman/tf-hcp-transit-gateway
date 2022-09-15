provider "aws" {
  region  = var.primary_vpc_region
}

provider "aws" {
  alias   = "primary_vpc"
  region  = var.primary_vpc_region
}

provider "aws" {
  alias   = "secondary_vpc"
  region  = var.secondary_vpc_region
}

provider "hcp" {
  client_id = var.hcp_client_id
  client_secret = var.hcp_client_secret
}

provider "hcp" {
  alias = "secondary_hvn"
  region = var.secondary_vpc_region
  client_id = var.hcp_client_id
  client_secret = var.hcp_client_secret
}