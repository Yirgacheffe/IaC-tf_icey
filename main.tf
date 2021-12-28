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
resource "aws_subnet" "web_subnet" {
    vpc_id                  = "${aws_vpc.default.id}"
    cidr_block              = "20.10.10.0/24"
    map_public_ip_on_launch = true
    availability_zone       = "${local.zone_a}"
    tags                    = local.tags
}

resource "aws_subnet" "web_subnet_ha" {
    vpc_id                  = "${aws_vpc.default.id}"
    cidr_block              = "20.10.20.0/24"
    map_public_ip_on_launch = true
    availability_zone       = "${local.zone_b}"
    tags                    = local.tags
}

resource "aws_subnet" "app_subnet" {
    vpc_id                  = "${aws_vpc.default.id}"
    cidr_block              = "20.10.40.0/24"
    map_public_ip_on_launch = true
    availability_zone       = "${local.zone_a}"
    tags                    = local.tags
}

resource "aws_subnet" "app_subnet_ha" {
    vpc_id                  = "${aws_vpc.default.id}"
    cidr_block              = "20.10.50.0/24"
    map_public_ip_on_launch = true
    availability_zone       = "${local.zone_b}"
    tags                    = local.tags
}

resource "aws_subnet" "db_subnet" {
    vpc_id                  = "${aws_vpc.default.id}"
    cidr_block              = "20.10.60.0/24"
    map_public_ip_on_launch = true
    availability_zone       = "${local.zone_a}"
    tags                    = local.tags
}

resource "aws_subnet" "db_subnet_ha" {
    vpc_id                  = "${aws_vpc.default.id}"
    cidr_block              = "20.10.70.0/24"
    map_public_ip_on_launch = true
    availability_zone       = "${local.zone_b}"
    tags                    = local.tags
}

# ------------------------------------------------------------
# Internet gateway added inside VPC
# ------------------------------------------------------------
resource "aws_internet_gateway" "igw" {
    vpc_id = "${aws_vpc.default.id}"
    tags   = local.tags
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

# ------------------------------------------------------------
# Create AWS Web LB, in front of all component
# ------------------------------------------------------------
resource "aws_security_group" "web_lb_sg" {
    name = "web-lb-sg"
    description = "Allow HTTP inbound traffic to web Load Balancer"
    vpc_id = "${aws_vpc.default.id}"

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
    name               = "web-lb"
    load_balancer_type = "application"
    internal           = false

    subnets            = ["${aws_subnet.web_subnet.id}", "${aws_subnet.web_subnet_ha.id}"]
    security_groups    = [aws_security_group.web_lb_sg.id]
}

resource "aws_lb_target_group" "web_target_grp" {
    name     = "web-target"
    port     = "80"
    protocol = "HTTP"
    vpc_id   = aws_vpc.default.id

    health_check {
      port     = 80
      protocol = "HTTP"
    }
}

resource "aws_lb_listener" "web_listener" {
    load_balancer_arn = aws_lb.web_lb.arn
    port              = "80"
    protocol          = "HTTP"

    default_action {
        type = "forward"
        target_group_arn = "${aws_lb_target_group.web_target_grp.arn}"
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
        description = "TLS from VPC"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        # cidr_blocks = [aws_vpc.default.cidr_block] # include web lb ?
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
}

resource "aws_autoscaling_group" "web_as_grp" {
    desired_capacity = 0 # 1
    max_size         = 0 # 2
    min_size         = 0 # 1

    target_group_arns   = ["${aws_lb_target_group.web_target_grp.arn}"]
    vpc_zone_identifier = ["${aws_subnet.web_subnet.id}", "${aws_subnet.web_subnet_ha.id}"]

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
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["${aws_subnet.web_subnet.id}", "${aws_subnet.web_subnet_ha.id}"]
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
    internal           = false

    subnets            = ["${aws_subnet.app_subnet.id}", "${aws_subnet.app_subnet_ha.id}"]
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
    desired_capacity = 0
    max_size         = 0
    min_size         = 0

    target_group_arns   = ["${aws_lb_target_group.app_target_grp.arn}"]
    vpc_zone_identifier = ["${aws_subnet.app_subnet.id}", "${aws_subnet.app_subnet_ha.id}"]

    launch_template {
        id      = "${aws_launch_template.app_lt.id}"
        version = "%Latest"
    }
}

# ------------------------------------------------------------
# Create AWS Instance for DB instance
# ------------------------------------------------------------
resource "aws_db_subnet_group" "db_subnet_grp" {
    name       = "db-subnet-grp"
    subnet_ids = ["${aws_subnet.db_subnet.id}", "${aws_subnet.db_subnet_ha.id}"]
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

        # cidr_blocks   = ["${aws_subnet.app_subnet.id}", "${aws_subnet.app_subnet_ha.id}"]
    }

    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }
}

resource "aws_db_instance" "db_inst_mysql" {

    identifier      = "mysql-icey"    
    engine          = "mysql"
    engine_version  = "5.7.19"
    instance_class  = "db.t2.small"

    name            = "Icey_DB"
    username        = "dbadmin"
    password        = "<set-your-own-password!>"
    port            = 3306
    
    storage_type    = "gp2"
    multi_az        = true

    db_subnet_group_name   = "${aws_db_subnet_group.db_subnet_grp.name}"

    maintenance_window     = "Mon:01:00-Mon:03:00"
    monitoring_interval    = 30

    allocated_storage      = 10 # Gigabytes
    max_allocated_storage  = 50
    character_set_name     = "utf8"

    storage_encrypted      = true
    skip_final_snapshot    = true

    vpc_security_group_ids = ["${aws_security_group.db_inst_sg.id}"]

}

# ------------------------------------------------------------
