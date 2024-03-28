# Resource Group
resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = "${random_pet.prefix.id}-rg"
  tags = {
  owner_email = var.owner_email
  }
}

resource "azurerm_network_security_group" "sg" {
  name                = "sitta-sg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Virtual Network
resource "azurerm_virtual_network" "tf_network" {
  name                = "sitta-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Subnet 1
resource "azurerm_subnet" "tf_subnet_1" {
  name                 = "sitta-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.tf_network.name
  address_prefixes     = ["10.0.0.0/24"]
  private_link_service_network_policies_enabled = true
}

resource "azurerm_public_ip" "sitta" {
  name                = "sitta-public-ip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
  allocation_method   = "Static"
  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_network_interface" "sitta" {
  #count=3
  name                = "sitta-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.tf_subnet_1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.sitta.id
  }
}

resource "azurerm_network_interface_security_group_association" "sitta" {
  network_interface_id      = azurerm_network_interface.sitta.id
  network_security_group_id = azurerm_network_security_group.sg.id
}

resource "azurerm_network_security_rule" "sitta-out" {
  name                        = "sitta-nsr-out"
  priority                    = 1001
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges      = [443,9092]
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.sg.name
}

resource "azurerm_network_security_rule" "sitta-in" {
  name                        = "sitta-nsr-in"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges      = [22,443,9092]
  source_address_prefix       = var.source_address_prefix
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.sg.name
 # apparently not thread-safe? No, name must to be unique, as it will be overwritten otherwise
#  depends_on = [ azurerm_network_security_rule.sitta-out ] 
}


resource "azurerm_linux_virtual_machine" "sitta" {
  #count=1
  name                = "sitta-machine"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  #size                = "Standard_F2"
  size                = "Standard_B2als_v2"
  for_each = local.zones
  zone = each.value
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.sitta.id,

  ]
  
  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

resource "random_pet" "prefix" {
  prefix = var.resource_group_name_prefix
  length = 1
}

locals {
# use a single zone
  zones = toset(["1"])
}