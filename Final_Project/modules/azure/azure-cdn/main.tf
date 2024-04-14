terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "cdn_resource_group" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_cdn_profile" "cdn_profile" {
  name                = var.cdn_profile_name
  location            = "Global"
  resource_group_name = azurerm_resource_group.cdn_resource_group.name
  sku                 = "Standard_Microsoft"  
}

resource "azurerm_cdn_endpoint" "cdn" {
    // subdomain for the ${var.cdn_name}.azureeedge.net 
    name                   = var.cdn_endpoint_name
    profile_name           = azurerm_cdn_profile.cdn_profile.name
    location               = azurerm_resource_group.cdn_resource_group.location
    resource_group_name    = azurerm_resource_group.cdn_resource_group.name
    is_http_allowed        = true
    is_https_allowed       = true
    is_compression_enabled = false
    optimization_type      = "GeneralWebDelivery"
    querystring_caching_behaviour = "BypassCaching"

    origin {
        name       = var.origin_name
        //host_name  = digitalocean_droplet.http_rdir.ipv4_address
        host_name  = var.host_name
        http_port  = 80
        https_port = 443
    }

    delivery_rule {
        name = "RedirectRule"
        order = 1
        request_header_condition {            
            selector = "X-ASPNET-VERSION"
            operator = "Equal"
            match_values = ["1.7"] 
            negate_condition = true
        }
        url_redirect_action {
            redirect_type = "Found"
            protocol = "Https"
            hostname = var.url_redirect_host
            path = "/"
        }
    }
}
