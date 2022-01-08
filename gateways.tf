# ------------------------------------------------------------
# Internet gateway added inside VPC
# ------------------------------------------------------------
resource "aws_internet_gateway" "igw" {
    vpc_id = "${aws_vpc.default.id}"
    tags   = local.tags
}

# ------------------------------------------------------------
# EIP May Charge FEE !!!
# ------------------------------------------------------------
# Reserve EIPs
resource "aws_eip" "nat_a" {
    vpc  = true
    tags = local.tags
}

# NAT Gateway in AZ A
resource "aws_nat_gateway" "zone_a" {
    allocation_id = aws_eip.nat_a.id
    subnet_id     = aws_subnet.public["${local.zone_a}"].id

    tags = local.tags

    depends_on = [
        aws_subnet.public
    ]
}

# Reverse another EIPs
resource "aws_eip" "nat_b" {
    vpc  = true
    tags = local.tags
}

resource "aws_nat_gateway" "zone_b" {
    allocation_id = aws_eip.nat_b.id
    subnet_id     = aws_subnet.public["${local.zone_b}"].id

    tags = local.tags

    depends_on = [
        aws_subnet.public
    ]
}

# ------------------------------------------------------------