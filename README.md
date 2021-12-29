# IaC-tf_icey
IaC tool terraform project provisioning on AWS cloud

This repo show how to build a 3 tier AWS VPC network architecture using Terraform. This network architecture has 3 subnet tiers split across 2 availability zones. 
</br>
The web subnets also have a VPC routing table that will provide it access to the internet. The application and database tiers will not have such access; their routing tables will only allow internal network communication.

## Usage
To sun this you need to execute:

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

Note: this project create resources which can cost money (AWS Elastic IP, for example). Run `terraform destroy` when you don't need these resources.

## Requirements

| Name                                                                      | Version   | Description  |
|---------------------------------------------------------------------------|-----------|--------------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.1 |              |
| <a name="requirement_aws"></a> [aws](#requirement\_aws)                   | >= 3.63   | AWS Provider |

## Inputs

| Name | Description |
|------|-------------|

No inputs.

## Outputs

| Name                                                     | Description       |
|----------------------------------------------------------|-------------------|
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The ID of the VPC |


## Enchancement

- Environment variables, key variables.
- Outputs after apply.
- Route53, CloudFront, Amazon S3, S3 Glacier, CloudWatch not include by default.