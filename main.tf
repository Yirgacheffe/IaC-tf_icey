# Create terraform template of AWS Provider to demo a solution
provider "aws" {
    region     = "${var.aws_region}"

    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
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

    zone_a = "${var.aws_region}a"
    zone_b = "${var.aws_region}b"

    az_pub_subnet = {
        "${local.zone_a}" = "20.10.10.0/24"
        "${local.zone_b}" = "20.10.20.0/24"
    }

    az_prv_subnet = {
        "${local.zone_a}" = "20.10.40.0/24"
        "${local.zone_b}" = "20.10.50.0/24"
    }

    az_dbs_subnet = {
        "${local.zone_a}" = "20.10.70.0/24"
        "${local.zone_b}" = "20.10.80.0/24"
    }
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
# Create subnet on available zone (a, b)
# ------------------------------------------------------------
resource "aws_subnet" "public" {
    for_each = local.az_pub_subnet

    cidr_block              = each.value
    availability_zone       = each.key
    vpc_id                  = "${aws_vpc.default.id}"
    map_public_ip_on_launch = true
    tags                    = local.tags
}

resource "aws_subnet" "private" {
    for_each = local.az_prv_subnet

    cidr_block              = each.value
    availability_zone       = each.key
    vpc_id                  = "${aws_vpc.default.id}"
    map_public_ip_on_launch = true
    tags                    = local.tags
}

resource "aws_subnet" "database" {
    for_each = local.az_dbs_subnet

    cidr_block              = each.value
    availability_zone       = each.key
    vpc_id                  = "${aws_vpc.default.id}"
    map_public_ip_on_launch = true
    tags                    = local.tags
}
# ------------------------------------------------------------
