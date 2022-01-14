# IaC-tf_icey
This project demostrate how to use IaC tool terraform provisioning on AWS cloud.

This repo show how to build a 3 tier AWS VPC network architecture using Terraform. This network architecture has 3 subnet tiers split across 2 availability zones. 

## Usage

To sun this you need to execute:

- Follow the `Usage` in aws-provisioning folder to build your infrastructure on aws.
- Deploy project `web` into EC2 web instance.
- Deploy project `api` into EC2 application instance.

## Others

TBD...

## Tips

```bash
eval ${ssh-agent -s}

ssh-add <${YOUR_PRIVATE_KEY}>
ssh-add -L

ssh -A ${USER}@${SERVER_IP}
```