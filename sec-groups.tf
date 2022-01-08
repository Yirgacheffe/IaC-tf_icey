# ------------------------------------------------------------
# Create AWS Web LB, in front of all component
# ------------------------------------------------------------
resource "aws_security_group" "web_lb_sg" {
    name        = "web-lb-sg"
    description = "TLS inbound traffic to web Load Balancer"

    vpc_id      = "${aws_vpc.default.id}"

    ingress {
        description = "Allow web secure traffic from internet"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "Allow web traffic, then redirect to HTTPs"
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

resource "aws_security_group" "web_inst_sg" {
    name        = "web-inst-sg"
    description = "Allow HTTP inbound traffic to Web server"

    vpc_id      = aws_vpc.default.id

    ingress {
        description  = "Allow web traffic from LB"
        from_port    = 80
        to_port      = 80
        protocol     = "tcp"

        security_groups = [aws_security_group.web_lb_sg.id]
    }

    ingress {
        description = "Allow secure web traffic"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    // Template allowed 22, so the server become a Basion host
    ingress {
        description = "Allow SSH from all network"
        from_port   = 22
        to_port     = 22
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

# ------------------------------------------------------------
# Create AWS Application LB, in front of all component
# ------------------------------------------------------------

resource "aws_security_group" "app_lb_sg" {
    name        = "app-lb-sg"
    description = "Allow HTTP inbound traffic to Application Load Balancer"

    vpc_id      = "${aws_vpc.default.id}"

    ingress {
        description     = "Allow traffic from web instance"
        from_port       = 80
        to_port         = 80
        protocol        = "tcp"
        security_groups = [aws_security_group.web_inst_sg.id]
    }

    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    tags = local.tags
}

resource "aws_security_group" "app_inst_sg" {
    name        = "app-inst-sg"
    description = "Allow HTTP inbound traffic to Application server"

    vpc_id      = aws_vpc.default.id

    ingress {
        description     = "Allow traffic from application LB."
        from_port       = 80
        to_port         = 80
        protocol        = "tcp"
        security_groups = ["${aws_security_group.app_lb_sg.id}"]
    }

    ingress {
        description = "Allow SSH from local network"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["${aws_vpc.default.cidr_block}"]
    }

    egress  {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    tags = local.tags
}

# ------------------------------------------------------------
# Create AWS Database and Cache security group
# ------------------------------------------------------------
resource "aws_security_group" "db_inst_sg" {
    name        = "mysql-db-sg"
    description = "RDS Mysql instance server"

    vpc_id      = "${aws_vpc.default.id}"

    ingress {
        description     = "Allow traffic from application server"
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

resource "aws_security_group" "cache_inst_sg" {
    name        = "redis-sg"
    description = "Redis instance server"

    vpc_id      = "${aws_vpc.default.id}"

    ingress {
        description     = "Allow traffic from application server"
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

# ------------------------------------------------------------
