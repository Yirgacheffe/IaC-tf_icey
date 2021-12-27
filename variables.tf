# ------------------------------------------------------------
# Variables declarations
# ------------------------------------------------------------
variable "aws_region" {
    description = "AWS region to lauch the services."
    type        = string
    default     = "ap-southeast-1"
}

variable "proj_name" {
    description = "Name of the project."
    type        = string
    default     = "icey"
}

variable "env" {
    description = "Name of the project environment."
    type        = string
    default     = "dev"
}

variable "resource_tags" {
    description = "Tags to set for all resources."
    type        = map(string)
    default  = {
        # merge value in main.tf
    }
}

variable "instance_type" {
    description = "Type for AWS EC2 instance."
    default     = "t1.micro"
}

variable "vpc_cidr_block" {
    description = "Default CIDR block for VPC settings."
    type        = string
    default     = "20.10.0.0/16"
}

# variable "instance_ami" {
#    description = "AMI for AWS EC2 instance."
#    default     = "ami-0cf31d971a3ca20d6"
# }