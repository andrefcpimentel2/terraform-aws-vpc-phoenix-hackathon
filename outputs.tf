output "vpc_main_id" {
  value       = aws_vpc.main.id
  description = "AWS VPC: VPC ID"
}

output "VPC_region" {
  value       = aws_vpc.main.region
  description = "AWS VPC: VPC region passed back out for stacks use"
}

output "pub_subnet_id" {
  value       = aws_subnet.public.id
  description = "AWS VPC: VPC public subnet ID"
}

output "priv_subnet_id" {
  value       = aws_subnet.private.id
  description = "AWS VPC: VPC private subnet ID"
}

output "security_group_id" {
  value       = aws_security_group.def.id
  description = "AWS Security Group ID"
}