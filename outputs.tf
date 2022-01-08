# Outputs definition --------------------------------------------------
output "vpc_id" {
    description = "The ID of VPC"
    value       = aws_vpc.default.id
}

# Subnets
output "private_subnet" {
    description = "The ID of private subnet"
    value       = [for value in aws_subnet.private: value.id]
}

output "public_subnet" {
    description = "The ID of public subnet"
    value       = [for value in aws_subnet.public: value.id]
}

output "database_subnet" {
    description = "The ID of database subnet"
    value       = [for value in aws_subnet.database: value.id]
}

output "web_lb_dns" {
    description = "The Web Load Balancer DNS name"
    value       = aws_lb.web_lb.dns_name
}

output "database_inst_endpoint" {
    description = "The DB instance endpoint"
    value       = aws_db_instance.db_inst_mysql.endpoint
}

output "cache_cluster_address" {
    description = "The Cache Cluster address"
    value       = aws_elasticache_cluster.cache_cluster.cache_nodes
}

# ---------------------------------------------------------------------