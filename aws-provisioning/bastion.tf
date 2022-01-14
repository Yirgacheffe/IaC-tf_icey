# ------------------------------------------------------------
# Create "Bastion Server"
# ------------------------------------------------------------

resource "aws_key_pair" "ec2_ssh_key" {
    key_name   = "ec2-ssh-key"
    public_key = file("${var.ec2_auth_key}")
    tags       = local.tags
}

resource "aws_instance" "bastion" {
    key_name        = "${aws_key_pair.ec2_ssh_key.key_name}"
    ami             = "${var.inst_ami}"
    instance_type   = "${var.inst_type}"
    
#    ebs_block_device {
#        device_name = "/dev/sda1"
#        volume_size = 20
#        volume_type = "gp2"
#        encrypted   = true
#        delete_on_termination = true
#    }

    vpc_security_group_ids      = ["${aws_security_group.bastion_sg.id}"]
    subnet_id                   = aws_subnet.public["${local.zone_a}"].id
    associate_public_ip_address = true

    tags = local.tags
}
# ------------------------------------------------------------
