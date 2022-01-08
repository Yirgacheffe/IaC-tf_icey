# ------------------------------------------------------------
# Create AWS Web LB, in front of all component
# ------------------------------------------------------------
resource "aws_lb" "web_lb" {
    load_balancer_type = "application"
    name               = "web-lb"
    internal           = false
    subnets            = [for value in aws_subnet.public: value.id]
    security_groups    = [aws_security_group.web_lb_sg.id]
    enable_http2       = false
    
    enable_deletion_protection = true

    tags = {
        Name = format("%s-web-alb", "icey-dev")
    }
}

resource "aws_lb_target_group" "web_target_grp" {
    name       = "web-target-grp"
    port       = "80"
    protocol   = "HTTP"
    vpc_id     = aws_vpc.default.id

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
        type             = "forward"
        target_group_arn = "${aws_lb_target_group.web_target_grp.arn}"
    }
}

resource "aws_lb_listener" "web_redirect" {
    load_balancer_arn = aws_lb.web_lb.arn
    port              = "80"
    protocol          = "HTTP"

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
# Create AWS Application LB, in front of application server
# ------------------------------------------------------------
resource "aws_lb" "app_lb" {
    name               = "app-lb"
    load_balancer_type = "application"
    internal           = true

    subnets            = [for value in aws_subnet.private: value.id]
    security_groups    = ["${aws_security_group.app_lb_sg.id}"]
}

resource "aws_lb_target_group" "app_target_grp" {
    name         = "app-target-grp"
    port         = "80"
    protocol     = "HTTP"
    vpc_id       = "${aws_vpc.default.id}"

    health_check {
        port     = "80"
        protocol = "HTTP"
    }
}

resource "aws_lb_listener" "app_listener" {
    load_balancer_arn    = aws_lb.app_lb.arn
    port                 = "80"
    protocol             = "HTTP"

    default_action {
        type             = "forward"
        target_group_arn = "${aws_lb_target_group.app_target_grp.arn}"
    }
}

# ------------------------------------------------------------
