# ------------------------------------------------------------
# Create "Bastion Server"
# ------------------------------------------------------------

# resource "aws_key_pair" "app_inst_kp" {
#     key_name   = "app-inst-kp"
#     public_key = file("${var.ec2_auth_key}")   # Import key for ssh access
# }

resource "aws_instance" "bastion" {
    name = "bastion-server"

    instance_type = "${var.inst_type}"
    ami           = "${var.inst_ami}"

    block_device_mappings {
        device_name     = "/dev/sda1"
        ebs {
            volume_size = 20 // Giga bytes
            encrypted   = true
        }
    }

    vpc_security_group_ids      = ["${aws_security_group.bastion_sg.id}"]
    subnet_id                   = aws_subnet.public["${local.zone_a}"].id
    associate_public_ip_address = true

    tags = local.tags
}

# ------------------------------------------------------------