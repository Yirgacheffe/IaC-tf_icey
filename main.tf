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
# Create AWS Instance
# ------------------------------------------------------------
resource "aws_key_pair" "app_inst_kp" {
  key_name   = "app-inst-kp"
  public_key = file("~/.ssh/ec2_rsa.pub")   # Import key for ssh access
}

resource "aws_launch_template" "web_lt" {
    name_prefix    = "web-lt"
    instance_type  = "${var.inst_type}"
    image_id       = "${var.inst_ami}"
    key_name       = aws_key_pair.app_inst_kp.key_name
    
    block_device_mappings {
        device_name = "/dev/sda1"

        ebs {
            volume_size = 20 // Giga bytes
            encrypted   = true
        }
    }

    vpc_security_group_ids = ["${aws_security_group.web_inst_sg.id}"]
    user_data              = filebase64("${path.module}/apache_init.sh")
}

resource "aws_autoscaling_group" "web_as_grp" {
    desired_capacity = 1 # 1
    max_size         = 2 # 2
    min_size         = 1 # 1

    target_group_arns   = ["${aws_lb_target_group.web_target_grp.arn}"]
    vpc_zone_identifier = [for value in aws_subnet.public: value.id]

    launch_template {
        id = "${aws_launch_template.web_lt.id}"
        version = "$Latest"
    }
}

# ------------------------------------------------------------
# Create AWS Application
# ------------------------------------------------------------
resource "aws_launch_template" "app_lt" {
    name_prefix    = "app-lt"
    instance_type  = "${var.inst_type}"
    image_id       = "${var.inst_ami}"
    key_name       = aws_key_pair.app_inst_kp.key_name

    block_device_mappings {
        device_name = "/dev/sda1"

        ebs {
            volume_size = 20 // Giga bytes
            encrypted   = true
        }
    }

    vpc_security_group_ids = ["${aws_security_group.app_inst_sg.id}"]
}

resource "aws_autoscaling_group" "app_as_grp" {
    desired_capacity = 1
    max_size         = 2
    min_size         = 1

    target_group_arns   = ["${aws_lb_target_group.app_target_grp.arn}"]
    vpc_zone_identifier = [for value in aws_subnet.private: value.id]

    launch_template {
        id      = "${aws_launch_template.app_lt.id}"
        version = "$Latest"
    }
}

# ------------------------------------------------------------
# Create AWS Instance for DB instance
# ------------------------------------------------------------
resource "aws_db_subnet_group" "db_subnet_grp" {
    name       = "db-subnet-grp"
    subnet_ids = [for value in aws_subnet.database: value.id]
    tags       = local.tags
}

resource "aws_db_instance" "db_inst_mysql" {

    identifier      = "mysql-icey-1"
    engine          = "mysql"
    engine_version  = "8.0.23"
    instance_class  = "db.t3.small"

    name            = "${var.db_name}"
    username        = "${var.db_username}"
    password        = "${var.db_password}"
    port            = 3306
    storage_type    = "gp2"

    # set multi_za to true enabled standby mode
    # multi_az      = true

    db_subnet_group_name    = "${aws_db_subnet_group.db_subnet_grp.name}"

    maintenance_window      = "Mon:01:00-Mon:03:00"
    allocated_storage       = 10    # Gigabytes
    max_allocated_storage   = 50
    
    # StorageEncrypted set to 'true', KMS key identifier for encrypted
    storage_encrypted       = true
    backup_retention_period = 7

 #    kms_key_id              = aws_kms_key.rds.arn
    skip_final_snapshot     = true
    vpc_security_group_ids  = ["${aws_security_group.db_inst_sg.id}"]

    iam_database_authentication_enabled = true

    # monitoring_interval   = 30
    tags                    = local.tags
}

# ------------------------------------------------------------
# Create AWS Instance for Elasticache
# ------------------------------------------------------------

resource "aws_elasticache_subnet_group" "cache_subnet_grp" {
    name       = "cache-subnet-grp"
    subnet_ids = [for value in aws_subnet.database: value.id]
    tags       = local.tags
}

resource "aws_elasticache_cluster" "cache_cluster" {
    cluster_id           = "redis-cluster"
    engine               = "redis"

    node_type            = "cache.t2.micro"
    engine_version       = "6.x"
    num_cache_nodes      = 1
    port                 = 6379
    parameter_group_name = "default.redis6.x"

    subnet_group_name    = "${aws_elasticache_subnet_group.cache_subnet_grp.name}"
    security_group_ids   = ["${aws_security_group.cache_inst_sg.id}"]
    tags                 = local.tags
}

# ------------------------------------------------------------
