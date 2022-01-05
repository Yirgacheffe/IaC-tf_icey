# Create terraform template of AWS Provider to demo a solution
provider "aws" {
    region     = "${var.aws_region}"
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
resource "aws_subnet" "public_subnet" {
    for_each = local.az_pub_subnet

    cidr_block              = each.value
    availability_zone       = each.key
    vpc_id                  = "${aws_vpc.default.id}"
    map_public_ip_on_launch = true
    tags                    = local.tags
}

resource "aws_subnet" "private_subnet" {
    for_each = local.az_prv_subnet

    cidr_block              = each.value
    availability_zone       = each.key
    vpc_id                  = "${aws_vpc.default.id}"
    map_public_ip_on_launch = true
    tags                    = local.tags
}

resource "aws_subnet" "database_subnet" {
    for_each = local.az_dbs_subnet

    cidr_block              = each.value
    availability_zone       = each.key
    vpc_id                  = "${aws_vpc.default.id}"
    map_public_ip_on_launch = true
    tags                    = local.tags
}

# ------------------------------------------------------------
# Internet gateway added inside VPC
# ------------------------------------------------------------
resource "aws_internet_gateway" "igw" {
    vpc_id = "${aws_vpc.default.id}"
    tags   = local.tags
}

resource "aws_route_table" "rtb_public" {
    vpc_id = "${aws_vpc.default.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.igw.id}"
    }

    tags   = local.tags
}

resource "aws_route_table_association" "rta_web_subnet" {
    for_each = local.az_pub_subnet

    subnet_id = aws_subnet.public_subnet[each.key].id
    route_table_id = aws_route_table.rtb_public.id
}

# ------------------------------------------------------------
# Create AWS Web LB, in front of all component
# ------------------------------------------------------------
resource "aws_security_group" "web_lb_sg" {
    name = "web-lb-sg"
    description = "TLS inbound traffic to web Load Balancer"

    vpc_id = "${aws_vpc.default.id}"

    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = local.tags
}

resource "aws_lb" "web_lb" {
    load_balancer_type = "application"

    name               = "web-lb"
    internal           = false
    subnets            = [for value in aws_subnet.public_subnet: value.id]
    security_groups    = [aws_security_group.web_lb_sg.id]
}

resource "aws_lb_target_group" "web_target_grp" {
    name     = "web-target-grp"
    port     = "80"
    protocol = "HTTP"
    vpc_id   = aws_vpc.default.id

    health_check {
      port     = 80
      protocol = "HTTP"
    }
}

resource "aws_lb_listener" "web_https" {
    load_balancer_arn = aws_lb.web_lb.arn
    port              = "443"
    protocol          = "HTTPS"

    ssl_policy        = "ELBSecurityPolicy-2016-08"
    certificate_arn   = "${aws_acm_certificate.default.arn}"

    default_action {
        type = "forward"
        target_group_arn = "${aws_lb_target_group.web_target_grp.arn}"
    }
}

resource "aws_lb_listener" "web_redirect" {
    load_balancer_arn   = aws_lb.web_lb.arn
    port                = "80"
    protocol            = "HTTP"

    default_action {
        type = "redirect"
     
        redirect {
            protocol    = "HTTPS"
            port        = "443"

            status_code = "HTTP_301"
        }
    }
}

# ------------------------------------------------------------
# Create AWS Web Security Group & Instance
# ------------------------------------------------------------
resource "aws_security_group" "web_inst_sg" {
    name        = "web-inst-sg"
    description = "Allow HTTP inbound traffic to Web server"
    vpc_id      = aws_vpc.default.id

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        security_groups = [aws_security_group.web_lb_sg.id]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = local.tags
}

resource "aws_launch_template" "web_lt" {
    name_prefix    = "web-lt"
    instance_type  = "${var.inst_type}"
    image_id       = "${var.inst_ami}"

    vpc_security_group_ids = ["${aws_security_group.web_inst_sg.id}"]

    user_data = filebase64("${path.module}/web-init.sh")
}

resource "aws_autoscaling_group" "web_as_grp" {
    desired_capacity = 1 # 1
    max_size         = 2 # 2
    min_size         = 1 # 1

    target_group_arns   = ["${aws_lb_target_group.web_target_grp.arn}"]
    vpc_zone_identifier = [for value in aws_subnet.public_subnet: value.id]

    launch_template {
        id = "${aws_launch_template.web_lt.id}"
        version = "$Latest"
    }
}

# ------------------------------------------------------------
# Create AWS Application LB, in front of application server
# ------------------------------------------------------------
resource "aws_security_group" "app_lb_sg" {
    name = "app-lb-sg"
    description = "Allow HTTP inbound traffic to Application Load Balancer"
    vpc_id = "${aws_vpc.default.id}"

    ingress {
        from_port       = 80
        to_port         = 80
        protocol        = "tcp"
        security_groups = [aws_security_group.web_inst_sg.id]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = local.tags
}

resource "aws_lb" "app_lb" {
    name               = "app-lb"
    load_balancer_type = "application"
    internal           = true

    subnets            = [for value in aws_subnet.private_subnet: value.id]
    security_groups    = ["${aws_security_group.app_lb_sg.id}"]
}

resource "aws_lb_target_group" "app_target_grp" {
    name     = "app-target-grp"
    port     = "80"
    protocol = "HTTP"
    vpc_id   = "${aws_vpc.default.id}"

    health_check {
        port     = "80"
        protocol = "HTTP"
    }
}

resource "aws_lb_listener" "app_listener" {
    load_balancer_arn = aws_lb.app_lb.arn
    port              = "80"
    protocol          = "HTTP"

    default_action {
        type              = "forward"
        target_group_arn = "${aws_lb_target_group.app_target_grp.arn}"
    }
}

# ------------------------------------------------------------
# Create AWS Application LB, in front of application server
# ------------------------------------------------------------
resource "aws_security_group" "app_inst_sg" {
    name        = "app-inst-sg"
    description = "Allow HTTP inbound traffic to Application server"
    vpc_id      = aws_vpc.default.id

    ingress {
        from_port       = 80
        to_port         = 80
        protocol        = "tcp"
        security_groups = ["${aws_security_group.app_lb_sg.id}"]
    }
    
    egress  {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    tags = local.tags
}

resource "aws_launch_template" "app_lt" {
    name_prefix    = "app-lt"
    instance_type  = "${var.inst_type}"
    image_id       = "${var.inst_ami}"

    vpc_security_group_ids = ["${aws_security_group.app_inst_sg.id}"]
}

resource "aws_autoscaling_group" "app_as_grp" {
    desired_capacity = 1
    max_size         = 2
    min_size         = 1

    target_group_arns   = ["${aws_lb_target_group.app_target_grp.arn}"]
    vpc_zone_identifier = [for value in aws_subnet.private_subnet: value.id]

    launch_template {
        id      = "${aws_launch_template.app_lt.id}"
        version = "$Latest"
    }
}


# ------------------------------------------------------------
# AWS KMS key for DB Instance 
# ------------------------------------------------------------
resource "aws_kms_key" "rds" {
    description              = "Encrypt and decrypt for RDS (mysql instance)"
    
    key_usage                = "ENCRYPT_DECRYPT"
    customer_master_key_spec = "SYMMETRIC_DEFAULT"
    deletion_window_in_days  = 10
}

resource "aws_kms_alias" "rds_alias" {
    name          = "alias/icey-rds"
    target_key_id = aws_kms_key.rds.key_id
}

# ------------------------------------------------------------
# Create AWS Instance for DB instance
# ------------------------------------------------------------
resource "aws_db_subnet_group" "db_subnet_grp" {
    name       = "db-subnet-grp"
    subnet_ids = [for value in aws_subnet.database_subnet: value.id]
    tags       = local.tags
}

resource "aws_security_group" "db_inst_sg" {
    name        = "mysql-db-sg"
    description = "RDS Mysql instance server"
    vpc_id      = "${aws_vpc.default.id}"

    ingress {
        from_port       = 3306
        to_port         = 3306
        protocol        = "tcp"
        security_groups = ["${aws_security_group.app_inst_sg.id}"]
    }

    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }
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
    kms_key_id              = aws_kms_key.rds.arn

    skip_final_snapshot     = true
    vpc_security_group_ids  = ["${aws_security_group.db_inst_sg.id}"]
    
    # monitoring_interval   = 30
    tags                    = local.tags
}

# ------------------------------------------------------------
# Create AWS Instance for Elasticache
# ------------------------------------------------------------
resource "aws_security_group" "cache_inst_sg" {
    name        = "redis-sg"
    description = "Redis instance server"

    vpc_id      = "${aws_vpc.default.id}"

    ingress {
        from_port       = 6379
        to_port         = 6379
        protocol        = "tcp"
        security_groups = ["${aws_security_group.app_inst_sg.id}"]
    }

    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }
}

resource "aws_elasticache_subnet_group" "cache_subnet_grp" {
    name       = "cache-subnet-grp"
    subnet_ids = [for value in aws_subnet.database_subnet: value.id]
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
