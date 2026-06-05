output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id
  ]
}

output "igw_id" {
  value = aws_internet_gateway.main.id
}

output "route_table_id" {
  value = aws_route_table.public.id
}
