terraform {
  required_version = ">= 0.14.0"
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "1.76.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.55.0"
    }
  }
}

provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}

# pick existing environment
data "confluent_environment" "cc_env" {
  id = var.confluent_environment_id
}

# create a PL attachment
resource "confluent_private_link_attachment" "main" {
  cloud        = "AZURE"
  region       = var.region
# displayed in CC console, better 'enterprise-ntwrk'
  display_name = "Private Link Attachment"
  environment {
    id = data.confluent_environment.cc_env.id
  }
}

# create a PL attachment connection
resource "confluent_private_link_attachment_connection" "main" {
# displayed in CC console, better 'enterprise-ntwkr-conn'
  display_name = "Private Link Attachment Connection"
  environment {
    id = data.confluent_environment.cc_env.id
  }
  azure {
    private_endpoint_resource_id = module.privatelink.vpc_endpoint_id
  }

  private_link_attachment {
    id = confluent_private_link_attachment.main.id
  }
}

resource "confluent_kafka_cluster" "private_cluster" {
  display_name = "azr-clstr-dd"
# for dedicated
#  availability = "SINGLE_ZONE"
# for enterprise
  availability = "LOW"
  cloud        = confluent_private_link_attachment.main.cloud
  region       = confluent_private_link_attachment.main.region

#  dedicated {
#    cku = 1
#  }
  enterprise {
  }
  environment {
    id = data.confluent_environment.cc_env.id
  }
}


# https://docs.confluent.io/cloud/current/networking/private-links/azure-privatelink.html
# Set up Private Endpoints for Azure Private Link in your Azure subscription
# Set up DNS records to use Azure Private Endpoints
provider "azurerm" {
  features {
  }
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

module "privatelink" {
  source                     = "./azure-privatelink-endpoint"
  resource_group             = var.resource_group
  vnet_region                = confluent_private_link_attachment.main.region
  vnet_name                  = var.vnet_name
  bootstrap                  = confluent_kafka_cluster.private_cluster.bootstrap_endpoint
  private_link_service_alias = confluent_private_link_attachment.main.azure[0].private_link_service_alias
  subnet_name_by_zone        = var.subnet_name_by_zone
  dns_domain_name            = confluent_private_link_attachment.main.dns_domain
}
