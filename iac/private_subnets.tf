resource "aws_subnet" "privates" {
  count                   = length(var.private_subnet)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false
  tags = merge(
    {
      Name = "${local.environment_name}_private_${replace(data.aws_availability_zones.available.names[count.index], "-", "_")}"
      Tier = "Private"
    },
  local.tags_map)
}

resource "aws_route_table" "privates" {
  count  = length(aws_subnet.privates)
  vpc_id = aws_vpc.main.id
  tags = merge(
    { Name = "${local.environment_name}_private_${replace(aws_subnet.privates[count.index].availability_zone, "-", "_")}" },
  local.tags_map)
}

resource "aws_route_table_association" "privates" {
  count          = length(aws_subnet.privates)
  subnet_id      = aws_subnet.privates[count.index].id
  route_table_id = aws_route_table.privates[count.index].id
}
