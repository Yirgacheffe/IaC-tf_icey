# 1. Create VPC
# 2. Internet gateway associated with VPC
# 3. Subnet inside VPC
# 4. Route Table inside VPC with a route that directs internet-bound traffic to the internet gateway
# 5. Route table association with our subnet to make it a public subnet
# 6. Security group inside VPC
# 7. Key pair used for SSH access
# 8. EC2 instance inside our public subnet with an associated security group and a generated key pair

# Create terraform template of AWS Provider to demo a solution
provider "aws" {
    region  = "${var.aws_region}"
}

# ------------------------------------------------------------
# Local variables
# ------------------------------------------------------------
locals {
    region      = "${var.aws_region}"
    name_suffix = "${var.proj_name}-${var.env}"

    required_tags = {
        proj = var.proj_name
        env  = var.env
    }
    
    tags = merge(var.resource_tags, local.required_tags)
}

# ------------------------------------------------------------
# Create VPC
# ------------------------------------------------------------
resource "aws_vpc" "default" {
    cidr_block           = "${var.vpc_cidr_block}"
    enable_dns_support   = true
    enable_dns_hostnames = true
    tags                 = local.tags
}

# ------------------------------------------------------------
# Internet gateway added inside VPC
# ------------------------------------------------------------
resource "aws_internet_gateway" "igw" {
    vpc_id = "${aws_vpc.default.id}"
    tags   = local.tags
}

# ------------------------------------------------------------
# Create subnet on available zone (a, b)
# ------------------------------------------------------------
resource "aws_subnet" "web_subnet" {
    vpc_id                  = "${aws_vpc.default.id}"
    cidr_block              = "20.10.10.0/24"
    map_public_ip_on_launch = true
    availability_zone       = "${local.region}a"
    tags                    = local.tags
}

resource "aws_subnet" "app_subnet" {
    vpc_id                  = "${aws_vpc.default.id}"
    cidr_block              = "20.10.40.0/24"
    map_public_ip_on_launch = true
    availability_zone       = "${local.region}a"
    tags                    = local.tags
}

resource "aws_subnet" "db_subnet" {
    vpc_id                  = "${aws_vpc.default.id}"
    cidr_block              = "20.10.60.0/24"
    map_public_ip_on_launch = true
    availability_zone       = "${local.region}a"
    tags                    = local.tags
}

resource "aws_subnet" "web_subnet_ha" {
    vpc_id                  = "${aws_vpc.default.id}"
    cidr_block              = "20.10.20.0/24"
    map_public_ip_on_launch = true
    availability_zone       = "${local.region}b"
    tags                    = local.tags
}

resource "aws_subnet" "app_subnet_ha" {
    vpc_id                  = "${aws_vpc.default.id}"
    cidr_block              = "20.10.50.0/24"
    map_public_ip_on_launch = true
    availability_zone       = "${local.region}b"
    tags                    = local.tags
}

resource "aws_subnet" "db_subnet_ha" {
    vpc_id                  = "${aws_vpc.default.id}"
    cidr_block              = "20.10.70.0/24"
    map_public_ip_on_launch = true
    availability_zone       = "${local.region}b"
    tags                    = local.tags
}

# ------------------------------------------------------------
# Create public route table
# ------------------------------------------------------------
resource "aws_route_table" "rtb_public" {
    vpc_id = "${aws_vpc.default.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.igw.id}"
    }

    tags   = local.tags
}
resource "aws_route_table_association" "rta_web_subnet" {
    subnet_id = aws_subnet.web_subnet.id
    route_table_id = aws_route_table.rtb_public.id
}

resource "aws_route_table_association" "rta_web_subnet_ha" {
    subnet_id = aws_subnet.web_subnet_ha.id
    route_table_id = aws_route_table.rtb_public.id
}

# resource "aws_route_table_association" "rta_app_subnet" {
#    subnet_id = aws_subnet.app_subnet.id
#    route_table_id = aws_route_table.rtb_public.id
# }

# resource "aws_route_table_association" "rta_app_subnet_ha" {
#    subnet_id = aws_subnet.app_subnet_ha.id
#    route_table_id = aws_route_table.rtb_public.id
# }

# ------------------------------------------------------------
# Create AWS Security Group - Web
# ------------------------------------------------------------
resource "aws_security_group" "sg_tls" {
    name        = "tls_sg"
    description = "Allow TLS inbound traffic"
    vpc_id      = aws_vpc.default.id

    ingress {
        description = "TLS from VPC"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = [aws_vpc.default.cidr_block]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = local.tags
}

resource "aws_security_group" "sg_http" {
    name        = "http_sg"
    description = "Allow HTTP inbound traffic"
    vpc_id      = aws_vpc.default.id

    ingress {
        description = "TLS from VPC"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = [aws_vpc.default.cidr_block]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = local.tags
}

# ------------------------------------------------------------
# Create AWS Instance for Web server
# Ubuntu Server 20.04 LTS (HVM), SSD Volume Type
# ------------------------------------------------------------
resource "aws_instance" "web_az_a" {
    ami                    = "ami-055d15d9cfddf7bd3"
    instance_type          = "t2.micro"
    vpc_security_group_ids = ["${aws_security_group.sg_tls.id}", "${aws_security_group.sg_http.id}"]
    subnet_id              = "${aws_subnet.web_subnet.id}"
    
}

resource "aws_instance" "web_az_b" {
    ami                    = "ami-055d15d9cfddf7bd3"
    instance_type          = "t2.micro"
    vpc_security_group_ids = ["${aws_security_group.sg_tls.id}", "${aws_security_group.sg_http.id}"]
    subnet_id              = "${aws_subnet.web_subnet_ha.id}"    
}
