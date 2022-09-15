# Create the Main Vault Cluster in the Primary Region
resource "hcp_vault_cluster" "primary_hcp_vault" {
  hvn_id     = hcp_hvn.primary.hvn_id
  cluster_id = "${var.resource_prefix}-primary-hcp-vault-cluster"
  tier       = var.tier
}