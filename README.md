# cflt-azr-pl
Demonstrate CC private networking (PL) + public access
Setup local VNET (Terraform)
Set CC dedicated cluster + PL (Terraform)
Configure nginx proxy (manual)

## Content
* Creation / configuration of an Azure VNET
* Creation / configuration of a dedicated CC cluster + PL
* Creation / configuration of a TCP proxy in the previously created VNET
* Local adjustments to DNS
* Useful commands (kcat, open

## Prerequisites
* terraform
* Azure CLI
* CC account
* kcat

## Steps
* Create envvars for Azure 
```
export TF_VAR_subscription_id=<SUBSCRIPTION_ID>
export TF_VAR_tenant_id=<TENANT_ID>
export TF_VAR_client_id=<CLIENT_ID>
export TF_VAR_client_secret=<CLIENT_SECRET>
```
E.g. you can find out your subscription ID by running ```az account list```

E.g. you can get info on a new contributor by running 

```az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/<SUBSCRIPTION_ID>"```
* Create envvars for Confluent 
```
export TF_VAR_confluent_cloud_api_key=<CC_API_KEY>
export TF_VAR_confluent_cloud_api_secret=<CC_API_SECRET>
export TF_VAR_confluent_environment_id=<CC_ENV_ID>
```
* Create SSH key pair by executing
```
ssh-keygen -m PEM -t rsa -b 4096 -f ~/.ssh/azure/id_rsa
```
* Navigate to folder ```azr``` and run the commands
```
terraform init
terraform apply
```
* Navigate to folder ```cc``` and run the commands 
```
terraform init
terraform apply
```
* TBC
