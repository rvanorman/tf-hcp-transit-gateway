# Create the Primary HVN in HCP.
resource "hcp_hvn" "primary" {
  hvn_id         = "${var.resource_prefix}-hcp-vault-hvn"
  cloud_provider = var.cloud_provider
  region         = var.primary_vpc_region
  cidr_block     = var.hvn_cidr
}

resource "aws_ec2_transit_gateway" "primary" {
  provider = aws.primary_vpc
  tags = {
    Name = "${var.resource_prefix}-gateway-primary"
  }
}

resource "aws_ram_resource_share" "primary" {
  provider = aws.primary_vpc
  name                      = "${var.resource_prefix}-ram-resource-primary"
  allow_external_principals = true
}

resource "aws_ram_principal_association" "primary" {
  provider = aws.primary_vpc
  resource_share_arn = aws_ram_resource_share.primary.arn
  principal          = hcp_hvn.primary.provider_account_id
}

resource "aws_ram_resource_association" "primary" {
  provider = aws.primary_vpc
  resource_share_arn = aws_ram_resource_share.primary.arn
  resource_arn       = aws_ec2_transit_gateway.primary.arn
}

resource "hcp_aws_transit_gateway_attachment" "primary" {
  depends_on = [
    aws_ram_principal_association.primary,
    aws_ram_resource_association.primary,
  ]

  hvn_id                        = hcp_hvn.primary.hvn_id
  transit_gateway_attachment_id = "${var.resource_prefix}-transit-attach-primary"
  transit_gateway_id            = aws_ec2_transit_gateway.primary.id
  resource_share_arn            = aws_ram_resource_share.primary.arn
}

resource "hcp_hvn_route" "primary_hvn_route" {
  hvn_link         = hcp_hvn.primary.self_link
  hvn_route_id     = "${var.resource_prefix}-hvn-to-tgw-route-primary"
  destination_cidr = var.primary_vpc_cidr
  target_link      = hcp_aws_transit_gateway_attachment.primary.self_link
}

resource "aws_ec2_transit_gateway_vpc_attachment_accepter" "primary_hvn" {
  provider = aws.primary_vpc
  transit_gateway_attachment_id = hcp_aws_transit_gateway_attachment.primary.provider_transit_gateway_attachment_id
}

resource "aws_ec2_transit_gateway_vpc_attachment" "primary_vpc_gateway_attach" {
  subnet_ids         = [aws_subnet.primary_private_subnet_a.id,aws_subnet.primary_private_subnet_b.id]
  transit_gateway_id = aws_ec2_transit_gateway.primary.id
  vpc_id             = aws_vpc.primary_vpc.id
}

#resource "aws_ec2_transit_gateway_vpc_attachment_accepter" "primary_vpc" {
#  provider = aws.primary_vpc
#  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.primary_vpc_gateway_attach.id
#}