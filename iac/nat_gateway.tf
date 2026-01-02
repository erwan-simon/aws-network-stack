resource "aws_nat_gateway" "instances" {
  count         = var.nat_gateways_count
  allocation_id = aws_eip.nat_eips[count.index].id
  subnet_id     = aws_subnet.publics[count.index].id
  depends_on    = [aws_internet_gateway.main]
  tags = merge(
    { Name = "${local.environment_name}_${replace(aws_subnet.publics[count.index].availability_zone, "-", "_")}" },
  local.tags_map)
}

resource "aws_eip" "nat_eips" {
  count  = var.nat_gateways_count
  domain = "vpc"
  tags = merge(
    { Name = "${local.environment_name}_${replace(aws_subnet.publics[count.index].availability_zone, "-", "_")}" },
  local.tags_map)
}

resource "aws_route" "private_nat_gateway" {
  count                  = length(aws_subnet.privates)
  route_table_id         = aws_route_table.privates[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.instances[
    count.index > var.nat_gateways_count - 1 ? var.nat_gateways_count - 1 : count.index
  ].id
}

