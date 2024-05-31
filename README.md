# cflt-azr-pl

* Demonstrate CC private networking (PL) + additional public access
* Setup local VNET (Terraform)
* Setup CC Enterprise cluster + Private Link (Terraform) (alternatively: Dedicated)
* Configure nginx proxy (manual)
* Create API key / secret (CLI)

## Content
* Creation / configuration of an Azure VNET
* Creation / configuration of an Enterprise CC cluster + Private Link
* Creation / configuration of a TCP proxy in the previously created VNET
* Local adjustments to DNS
* Useful commands (kcat, openssl, Confluent CLI)

## Prerequisites
* terraform
* Azure CLI
* CC account
* kcat

## Steps
* Determine your public IP and create envvar
```
export TF_VAR_source_address_prefix=188.96.165.216
```
* Create priv/pub SSH key and store it in ~/.ssh/id_rsa
```
ssh-keygen -m PEM -t rsa -b 4096 
```
(Note: remember the passphrase!)

* In folder azr, run
```
terraform init
terraform apply 
```
This should take < 1min
Once finished, get public IP from the created Compute instance (e.g. via `grep public_ip_address terraform.tfstate`), in my example 172.173.254.108

* Validate cmdline connectivity from your local machine to the public IP endpoint of your Compute instance
```
ssh -i ~/.ssh/id_rsa adminuser@172.173.254.108
```
This will reuse the key pair you created above

* Create envvars for Azure TF
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
export CC_API_KEY=<YOUR_CONFLUENT_CLOUD_API_KEY>
export CC_API_SECRET=<YOUR_CONFLUENT_CLOUD_API_SECRET>
export CC_ENVIRONMENT_ID=<YOUR_EXISTING_ENVIRONMENT_ID>

```
* Create envvars for Confluent TF
```
export TF_VAR_confluent_cloud_api_key=<CC_API_KEY>
export TF_VAR_confluent_cloud_api_secret=<CC_API_SECRET>
export TF_VAR_confluent_environment_id=<CC_ENVIRONMENT_ID>
```
* In folder cc-enterprise
Adjust resource_group in file terraform.tfvars or add another envvar\
(Note that the resource_group is regenerated with a near-random value every time)\
Now run 
```
terraform init
terraform apply 
```
Again, this should run < 2 min
* Create another envvars for CLI
```
export CC_CLUSTER_ID=<YOUR_NEWLY_CREATED_CLUSTER_ID> (e.g. lkc-o56w8j)
```
* CLI commands to create API key / secret
```
confluent login
confluent environment use ${CC_ENVIRONMENT_ID}
confluent kafka cluster use ${CC_CLUSTER_ID}
confluent api-key create --resource ${CC_CLUSTER_ID} --description "SITTA demo enterprise PL"
+------------+------------------------------------------------------------------+
| API Key    | FOO_BAR_FOO_BARX                                                 |
| API Secret | FOO_BAR_FOO_BAR_FOO_BAR_FOO_BAR_FOO_BAR_FOO_BAR_FOO_BAR_FOO_BARX |
+------------+------------------------------------------------------------------+
confluent api-key store (values from above)
confluent api-key use (from above)
```
* Recycle envvars with cluster key/secret
```
export CC_BOOTSTRAP_SERVER=<YOUR_NEWLY_CREATED_BOOTSTRAP> (e.g. lkc-o56w8j.eastus.azure.private.confluent.cloud:9092)
export CC_KEY=FOO_BAR_FOO_BARX
export CC_SECRET=FOO_BAR_FOO_BAR_FOO_BAR_FOO_BAR_FOO_BAR_FOO_BAR_FOO_BAR_FOO_BARX
```
* Install nginx (and kafkacat) in Compute instance
```
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install -y nginx
sudo apt-get install kafkacat
```
Adjust /etc/nginx/nginx.conf (append from ./nginx.conf)\
Restart and validate nginx via
```
sudo nginx -t
sudo systemctl restart nginx (or sudo systemctl reload nginx)
sudo systemctl status nginx
```
* Use kcat to validate connectivity from your laptop
```
kcat -b ${CC_BOOTSTRAP_SERVER} -L -X security.protocol=SASL_SSL -X sasl.mechanisms=PLAIN -X sasl.username=$CC_KEY -X sasl.password=$CC_SECRET -X api.version.request=true -vvv
```
This should return something like 
```
Metadata for all topics (from broker -1: sasl_ssl://lkc-o56w8j.eastus.azure.private.confluent.cloud:9092/bootstrap):
 6 brokers:
  broker 0 at lkc-o56w8j-000b.eastus.azure.private.confluent.cloud:9092
  broker 1 at lkc-o56w8j-000e.eastus.azure.private.confluent.cloud:9092
  broker 2 at lkc-o56w8j-0008.eastus.azure.private.confluent.cloud:9092
  broker 3 at lkc-o56w8j-000a.eastus.azure.private.confluent.cloud:9092
  broker 4 at lkc-o56w8j-000d.eastus.azure.private.confluent.cloud:9092 (controller)
  broker 5 at lkc-o56w8j-0007.eastus.azure.private.confluent.cloud:9092
 0 topics:
```
If it does not, you should run a similar command from within the Compute instance after setting the envvars therein, namely
```
kafkacat -b ${CC_BOOTSTRAP_SERVER} -L -X security.protocol=SASL_SSL -X sasl.mechanisms=PLAIN -X sasl.username=$CC_KEY -X sasl.password=$CC_SECRET -X api.version.request=true -vvv
```
If this works, most likely the resolver 0.0.0.0 in nginx is incorrect.\
Try 
```
nslookup ${CC_BOOTSTRAP_SERVER} (without port)
```
in your Compute instance, note down the resolver IP and adjust nginx.

