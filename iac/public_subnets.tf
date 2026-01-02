resource "aws_subnet" "publics" {
  count                   = length(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = merge(
    {
      Name = "${local.environment_name}_public_${replace(data.aws_availability_zones.available.names[count.index], "-", "_")}"
      Tier = "Public"
    },
  local.tags_map)
}

resource "aws_route_table" "public_subnets_to_internet_gateway" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.tags_map, { Name = "${local.environment_name}_public_internet_gateway" })
}

resource "aws_route_table_association" "public_subnets_gateway_association" {
  count          = length(aws_subnet.publics)
  subnet_id      = aws_subnet.publics[count.index].id
  route_table_id = aws_route_table.public_subnets_to_internet_gateway.id
}
