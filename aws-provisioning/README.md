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

Note: this project create resources which may cost money (AWS Elastic IP, for example). Run `terraform destroy` when you don't need these resources.

## Requirements

| Name                                                                      | Version   | Description  |
|---------------------------------------------------------------------------|-----------|--------------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.1 |              |
| <a name="requirement_aws"></a> [aws](#requirement\_aws)                   | >= 3.63   | AWS Provider |

## Inputs

| Name         | Description                   | Mandatory | Default   |
|--------------|-------------------------------|-----------|-----------|
| DB Name      | Mysql database name.          | No        | `icey_DB` |
| Username     | Mysql database `username`.    | No        | `admin`   |
| Password     | Mysql database `password`.    | Yes       |           |


## Outputs

| Name                                                                                                       | Description                             |
|------------------------------------------------------------------------------------------------------------|-----------------------------------------|
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id)                                                   | The ID of the VPC                       |
| <a name="output_private_subnet"></a> [private\_subnet](#output\_private\_subnet)                           | The IDs of the Private Subnet           |
| <a name="output_public_subnet"></a> [public\_subnet](#output\_public\_subnet)                              | The IDs of the Public Subnet            |
| <a name="output_database_subnet"></a> [database\_subnet](#output\_database\_subnet)                        | The IDs of the Database Subnet          |
| <a name="output_database_inst_endpoint"></a> [database\_inst\_endpoint](#output\_database\_inst\_endpoint) | The Database Instance Endpoint          |
| <a name="output_cache_cluster_address"></a> [cache\_cluster\_address](#output\_cache\_cluster\_address)    | The cache cluster address               |
| <a name="output_web_lb_dns"></a> [web\_lb\_dns](#output\_web\_lb\_dns)                                     | The DNS of Web load balancer            |
| <a name="output_bastion_public_ip"></a> [bastion\_public\_ip](#output\_bastion\_public\_ip)                | The Public IP address of Bastion Server |

## Enchancement

- Environment variables, Access key variables.
- Outputs after apply.
- Route53, CloudFront, Amazon S3, S3 Glacier, CloudWatch not include by default.