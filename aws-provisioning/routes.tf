# ------------------------------------------------------------
# Route table
# ------------------------------------------------------------
resource "aws_route_table" "rtb_public" {
    vpc_id = "${aws_vpc.default.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.igw.id}"
    }

    tags = local.tags

    depends_on = [
        aws_internet_gateway.igw
    ]
}

resource "aws_route_table_association" "rta_web_subnet" {
    for_each = local.az_pub_subnet

    subnet_id      = aws_subnet.public[each.key].id
    route_table_id = aws_route_table.rtb_public.id
}

# ------------------------------------------------------------
# Create a route table for the app subnets in AZ A, B
# ------------------------------------------------------------

# Uses NAT gateway in AZ A
resource "aws_route_table" "private_aza" {
    vpc_id = aws_vpc.default.id

    route {
        cidr_block     = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.zone_a.id
    }

    tags = local.tags

    depends_on = [
        aws_nat_gateway.zone_a
    ]
}

resource "aws_route_table" "private_azb" {
    vpc_id = aws_vpc.default.id

    route {
        cidr_block     = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.zone_b.id
    }

    tags = local.tags

    depends_on = [
        aws_nat_gateway.zone_b
    ]
}

resource "aws_route_table_association" "app_aza" {
    subnet_id      = aws_subnet.private["${local.zone_a}"].id
    route_table_id = aws_route_table.private_aza.id
}

resource "aws_route_table_association" "app_azb" {
    subnet_id      = aws_subnet.private["${local.zone_b}"].id
    route_table_id = aws_route_table.private_azb.id
}

# ------------------------------------------------------------

resource "aws_route_table" "database" {
    vpc_id = aws_vpc.default.id
    tags   = local.tags
}

resource "aws_route_table_association" "database" {
    for_each = local.az_dbs_subnet

    subnet_id      = aws_subnet.database[each.key].id
    route_table_id = aws_route_table.database.id
}

# ------------------------------------------------------------
