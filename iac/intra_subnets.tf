resource "aws_subnet" "intras" {
  count                   = length(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.intra_subnet[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false
  tags = merge(
    {
      Name = "${local.environment_name}_intra_${replace(data.aws_availability_zones.available.names[count.index], "-", "_")}"
      Tier = "Intra"
    },
  local.tags_map)
}
