# ------------------------------------------------------------
# Variables declarations
# ------------------------------------------------------------
variable "aws_access_key" {
    description = "AWS account access key."
    type        = string
}

variable "aws_secret_key" {
    description = "AWS account secret key."
    type        = string
}

variable "aws_region" {
    description = "AWS region to lauch the services."
    type        = string
}

variable "inst_ami" {
    description = "AMI  for AWS EC2 instance."
    type        = string
}

variable "inst_type" {
    description = "Type for AWS EC2 instance."
    type        = string
}

# --------------------------------------------------
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
        # empty value, merge value in main.tf
    }
}

variable "vpc_cidr_block" {
    description = "Default CIDR block for VPC settings."
    type        = string
    default     = "20.10.0.0/16"
}

variable "db_name" {
    description = "Database name, provide from ENV."
    type        = string
    default     = "icey_DB"
}

variable "db_username" {
    description = "DB 'username', provide from ENV."
    type        = string
    default     = "admin"
}

variable "db_password" {
    description = "DB 'password', provide from ENV."
    type        = string
}

variable "ec2_auth_key" {
    description = "RSA public key path, key-pair for EC2."
    type        = string
    default     = "~/.ssh/ec2_rsa.pub"
}

# ------------------------------------------------------------