# ------------------------------------------------------------
# NACLs - Default Setting
# ------------------------------------------------------------

resource "aws_default_network_acl" "default" {
    default_network_acl_id = aws_vpc.default.default_network_acl_id

    # Ingress rules, allow internal traffic
    ingress {
        rule_no    = 100
        action     = "allow"
        from_port  = 0
        to_port    = 0
        protocol   = -1
        cidr_block = "0.0.0.0/0"
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

    tags = local.tags
}

# ------------------------------------------------------------