# ------------------------------------------------------------
# Create AWS Instance
# ------------------------------------------------------------
resource "aws_launch_template" "web_lt" {
    name_prefix    = "web-lt"
    instance_type  = "${var.inst_type}"
    image_id       = "${var.inst_ami}"
#   key_name       = aws_key_pair.app_inst_kp.key_name
    
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
    desired_capacity = 0 # 1
    max_size         = 0 # 2
    min_size         = 0 # 1

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
    # key_name     = aws_key_pair.app_inst_kp.key_name

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
    desired_capacity = 0
    max_size         = 0
    min_size         = 0

    target_group_arns   = ["${aws_lb_target_group.app_target_grp.arn}"]
    vpc_zone_identifier = [for value in aws_subnet.private: value.id]

    launch_template {
        id      = "${aws_launch_template.app_lt.id}"
        version = "$Latest"
    }
}

# ------------------------------------------------------------