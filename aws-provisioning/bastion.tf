# ------------------------------------------------------------
# Create "Bastion Server"
# ------------------------------------------------------------

resource "aws_key_pair" "bastion_key" {
    key_name   = "icey-bastion"
    public_key = file("${var.ec2_auth_key}")
    
    tags       = local.tags
}

resource "aws_instance" "bastion" {
    name = "bastion-server"

    instance_type = "${var.inst_type}"
    ami           = "${var.inst_ami}"
    key_name      = "${aws_key_pair.bastion_key.key_name}"

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