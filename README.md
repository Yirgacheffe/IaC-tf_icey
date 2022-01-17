# IaC-tf_icey
This project demostrate how to use IaC tool terraform provisioning on AWS cloud.

This repo show how to build a 3 tier AWS VPC network architecture using Terraform. This network architecture has 3 subnet tiers split across 2 availability zones. 

## Usage

To sun this you need to execute:

- Follow the `Usage` in aws-provisioning folder to provision your infrastructure on aws.</br></br>
- Build and deploy project `web` into EC2 web instance.
    ```bash
    # Make binary, copy to target server, then jump
    make build
    sh 2_bastion.sh

    ssh USER@BASTION-IP

    # On bastion
    scp  -r web-binary USER@WEB-SERVER-IP

    # On Web Server
    cd web-binary
    sh launch.sh    # Correct the LB address
    ```
- Build and deploy project `api` into EC2 application instance.
    ```bash
     # Make binary, copy to target server, then jump
    make build
    sh 2_bastion.sh

    ssh USER@BASTION-IP

    # On bastion
    scp  -r api-binary USER@APP-SERVER-IP

    # On Application Server
    cd api-binary
    sh launch.sh    # DB env variables needed, ref db-env.sh
    ```

## Enchancement
- CI / CD Pipeline
- Code structure & Automation

## Tips
```bash
eval ${ssh-agent -s}

ssh-add <${YOUR_PRIVATE_KEY}>
ssh-add -L

ssh -A  ${USER}@${SERVER_IP}
```
