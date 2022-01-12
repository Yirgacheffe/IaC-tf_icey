# ------------------------------------------------------------
# NACLs - Public Subnet
# ------------------------------------------------------------
resource "aws_network_acl" "public" {
    vpc_id     = aws_vpc.default.id    
    subnet_ids = [for value in aws_subnet.public: value.id]
    tags       = local.tags

    depends_on = [
        aws_subnet.public
    ]

    // Ingress rules - Allow internal traffic
    ingress {
        rule_no    = 100
        action     = "allow"
        from_port  = 0
        to_port    = 0
        protocol   = -1
        cidr_block = aws_vpc.default.cidr_block
    }

    # HTTPS traffic from the internet
    ingress {
        rule_no    = 105
        action     = "allow"
        from_port  = 443
        to_port    = 443
        protocol   = "tcp"
        cidr_block = "0.0.0.0/0"
    }

    # HTTP traffic from the internet
    ingress {
        rule_no    = 110
        action     = "allow"
        from_port  = 80
        to_port    = 80
        protocol   = "tcp"
        cidr_block = "0.0.0.0/0"
    }

    # AThe ephemeral ports from the internet
    ingress {
        rule_no    = 120
        action     = "allow"
        from_port  = 1025
        to_port    = 65534
        protocol   = "tcp"
        cidr_block = "0.0.0.0/0"
    }

    ingress {
        rule_no    = 125
        action     = "allow"
        from_port  = 1025
        to_port    = 65534
        protocol   = "udp"
        cidr_block = "0.0.0.0/0"
    }

    # Allow SSH Connection
    ingress {
        rule_no    = 130
        action     = "allow"
        from_port  = 22
        to_port    = 22
        protocol   = "tcp"
        cidr_block = "0.0.0.0/0"
    }

    # Egress rules - outbound ports and IPs
    egress {
        rule_no    = 100
        action     = "allow"
        from_port  = 0
        to_port    = 0
        protocol   = -1
        cidr_block = "0.0.0.0/0"
    }
}

# ------------------------------------------------------------
# NACLs - Private Subnet
# ------------------------------------------------------------
resource "aws_default_network_acl" "default" {
    default_network_acl_id = aws_vpc.default.default_network_acl_id
    tags                   = local.tags
}

resource "aws_network_acl" "app" {
    vpc_id     = aws_vpc.default.id
    subnet_ids = [for value in aws_subnet.private: value.id]
    tags       = local.tags

    depends_on = [
        aws_subnet.private
    ]

    # Ingress rules, allow internal traffic
    ingress {
        rule_no    = 100
        action     = "allow"
        from_port  = 0
        to_port    = 0
        protocol   = -1
        cidr_block = aws_vpc.default.cidr_block
    }

    # Egress rules all ports, protocols, and IPs outbound
    egress {
        rule_no    = 100
        action     = "allow"
        from_port  = 0
        to_port    = 0
        protocol   = -1
        cidr_block = "0.0.0.0/0"
    }
}

# ------------------------------------------------------------
# NACLs - Database Subnet (DB, Cache)
# ------------------------------------------------------------

resource "aws_network_acl" "data" {
    vpc_id     = aws_vpc.default.id
    subnet_ids = [for value in aws_subnet.database: value.id]
    tags       = local.tags

    depends_on = [
        aws_subnet.database
    ]

    # Ingress rules - MySql, Redis Cache
    ingress {
        rule_no    = 100
        action     = "allow"
        from_port  = 3306
        to_port    = 3306
        protocol   = "tcp"
        cidr_block = aws_vpc.default.cidr_block
    }

    ingress {
        rule_no    = 105
        action     = "allow"
        from_port  = 6379
        to_port    = 6379
        protocol   = "tcp"
        cidr_block = aws_vpc.default.cidr_block
    }

    # Egress rules all ports, protocols, and IPs outbound
    egress {
        rule_no    = 100
        action     = "allow"
        from_port  = 0
        to_port    = 0
        protocol   = -1
        cidr_block = "0.0.0.0/0"
    }
}

# ------------------------------------------------------------
