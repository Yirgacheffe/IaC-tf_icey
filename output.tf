# Outputs definition ------------------------------

# VPC
output "vpc_id" {
    description = "The ID of VPC"
    value       = aws_vpc.default.id
}
