# IaC-tf_icey
IaC tool terraform project provisioning on AWS cloud

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