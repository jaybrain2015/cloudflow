output "vpc_id" {
  description = "ID of the CloudFlow VPC"
  value       = aws_vpc.cloudflow.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = aws_subnet.private.id
}

output "nat_public_ip" {
  description = "Public IP of the NAT instance"
  value       = aws_instance.nat.public_ip
}

output "ecr_repository_url" {
  description = "URL of the Snipe-IT ECR repository"
  value       = aws_ecr_repository.snipeit.repository_url
}