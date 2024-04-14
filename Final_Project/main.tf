provider "aws" {
  region = "us-east-1" # You can change this to your preferred region
}

provider "local" {
  # Configuration options
}


//transfer domains in namecheap to route53 
# module "namecheap_to_route53" {
#   source = "./modules/aws/namecheap-to-route53"

#   domains = var.domains
# }

//resource that generates a new RSA private key
resource "tls_private_key" "terra_sshkey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# This will save the private key to a file
resource "local_file" "private_key_pem" {
  content  = tls_private_key.terra_sshkey.private_key_pem
  filename = "${path.module}/generated_key.pem" # This will save the key in the current directory as 'generated_key.pem'
}

# resource that uploads the generated public key to AWS
resource "aws_key_pair" "generated_key" {
  key_name   = "terra-sshkey"
  public_key = tls_private_key.terra_sshkey.public_key_openssh
}

data "aws_ami" "latest_ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's owner ID for Ubuntu images

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

module "redteamvpc" {
  source   = "./modules/aws/create_vpc"
  avl_zone = var.avl_zone
}

module "redteambastion" {
  // while the bastion host is being created, it will copy the ssh key file onto it and set the necessary permission (for more info check the main.tf of bastion-host)
  source         = "./modules/aws/bastion_host"
  ami_id         = data.aws_ami.latest_ubuntu.id
  install_redelk = true
  vpc_id         = module.redteamvpc.vpc_id
  subnet_id      = module.redteamvpc.subnet1_id
  avl_zone       = var.avl_zone
  key_name       = aws_key_pair.generated_key.key_name
  private_key    = tls_private_key.terra_sshkey.private_key_pem
  ssh_user       = var.ssh_user
}

module "redelk_server" {
    count                   = module.redteambastion.install_redelk ? 1 : 0
    depends_on              = [ module.teamserver]
    source                  = "./modules/aws/redelk"
    ami_id                  = data.aws_ami.latest_ubuntu.id
    vpc_id                  = module.redteamvpc.vpc_id
    subnet_id               = module.redteamvpc.subnet2_id // private subnet
    avl_zone                = var.avl_zone
    key_name                = aws_key_pair.generated_key.key_name
    private_key             = tls_private_key.terra_sshkey.private_key_pem
    bastionhostprivateip    = module.redteambastion.bastion-private-ip // for whitelisting 
    bastionhostpublicip     = module.redteambastion.bastion-public-ip
    teamserver_hostname     = "teamserver"
    teamserver_private_ip   = module.teamserver.teamserver_private_ip
    ssh_user                = var.ssh_user
}

module "teamserver" {
    depends_on           = [ module.redteambastion ]

    source               = "./modules/aws/teamserver"
    ami_id               = data.aws_ami.latest_ubuntu.id
    install_redelk       = module.redteambastion.install_redelk
    vpc_id               = module.redteamvpc.vpc_id
    subnet_id            = module.redteamvpc.subnet2_id // private subnet
    avl_zone             = var.avl_zone
    key_name             = aws_key_pair.generated_key.key_name
    private_key          = tls_private_key.terra_sshkey.private_key_pem
    bastionhostprivateip = module.redteambastion.bastion-private-ip // for whitelisting 
    bastionhostpublicip  = module.redteambastion.bastion-public-ip
    ssh_user             = var.ssh_user
}

module "redteamhttpredir" {
    depends_on = [
        module.redteambastion, module.teamserver
    ]

    source               = "./modules/aws/http-redir"
    mycount              = 1
    vpc_id               = module.redteamvpc.vpc_id
    subnet_id            = module.redteamvpc.subnet1_id // public subnet
    ami_id               = data.aws_ami.latest_ubuntu.id
    avl_zone             = var.avl_zone
    key_name             = aws_key_pair.generated_key.key_name
    private_key          = tls_private_key.terra_sshkey.private_key_pem
    bastionhostprivateip = module.redteambastion.bastion-private-ip // for whitelisting 
    bastionhostpublicip  = module.redteambastion.bastion-public-ip
    cs_private_ip        = module.teamserver.teamserver_private_ip
    ssh_user             = var.ssh_user
    install_redelk       = true
    redirect_url         = "www.google.com"
    my_uri               = "hackspacecon"
}

# module "gophish" {
#     depends_on = [
#         module.redteambastion
#     ]

#     source               = "./modules/aws/gophish"
#     vpc_id               = module.redteamvpc.vpc_id
#     subnet_id            = module.redteamvpc.subnet2_id // private subnet
#     ami_id               = data.aws_ami.latest_ubuntu.id
#     avl_zone             = var.avl_zone
#     key_name             = aws_key_pair.generated_key.key_name
#     private_key          = tls_private_key.terra_sshkey.private_key_pem
#     bastionhostprivateip = module.redteambastion.bastion-private-ip // for whitelisting 
#     bastionhostpublicip  = module.redteambastion.bastion-public-ip
#     ssh_user             = var.ssh_user
# }

# module "evilginx" {
#     depends_on = [
#         module.redteambastion
#     ]

#     source               = "./modules/aws/evilginx"
#     vpc_id               = module.redteamvpc.vpc_id
#     subnet_id            = module.redteamvpc.subnet1_id // public subnet
#     ami_id               = data.aws_ami.latest_ubuntu.id
#     avl_zone             = var.avl_zone
#     key_name             = aws_key_pair.generated_key.key_name
#     private_key          = tls_private_key.terra_sshkey.private_key_pem
#     bastionhostprivateip = module.redteambastion.bastion-private-ip // for whitelisting 
#     bastionhostpublicip  = module.redteambastion.bastion-public-ip
#     ssh_user             = var.ssh_user
#     domain_name          = var.evilginx_domain_name
# }

# module "webclone-server" {
#     depends_on = [module.namecheap_to_route53]

#     mycount              = 1
#     source               = "./modules/aws/webserver-clone"
#     instance_type        = "t3.micro"
#     hostname             = "WebServer"
#     ami_id               = data.aws_ami.latest_ubuntu.id
#     ssh_user             = "ubuntu"
#     vpc_id               = module.redteamvpc.vpc_id
#     subnet_id            = module.redteamvpc.subnet1_id
#     avl_zone             = var.avl_zone
#     key_name             = aws_key_pair.generated_key.key_name
#     private_key          = tls_private_key.terra_sshkey.private_key_pem
#     bastionhostprivateip = module.redteambastion.bastion-private-ip
#     bastionhostpublicip  = module.redteambastion.bastion-public-ip
#     open_ports           = [443, 80]
#     domain_names         = ["newhireintro.com"]
#     website_url          = ["www.smartrecruiters.com"]
# }

# module "mailgun" {
#   source                 = "./modules/mailgun"
#   mailgun_domain_name    = ["newhireintro.com"]
#   mailgun_region         = "us"
#   mailgun_smtp_users     = ["dazzy"]
#   mailgun_smtp_passwords = ["hacker@123"]
# }

# module "plain-aws-instance" {
#   depends_on           = [module.namecheap_to_route53]
#   source               = "./modules/aws/plain-instance"
#   mycount              = 1
#   instance_type        = "t3.micro"
#   hostname             = "WebServer"
#   ami_id               = data.aws_ami.latest_ubuntu.id
#   ssh_user             = "ubuntu"
#   vpc_id               = module.redteamvpc.vpc_id
#   subnet_id            = module.redteamvpc.subnet1_id
#   avl_zone             = var.avl_zone
#   key_name             = aws_key_pair.generated_key.key_name
#   private_key          = tls_private_key.terra_sshkey.private_key_pem
#   bastionhostprivateip = module.redteambastion.bastion-private-ip
#   bastionhostpublicip  = module.redteambastion.bastion-public-ip
#   open_ports           = [443, 80]
#   domain_names         = ["newhireintro.com"]
#   ansible_playbook     =  "./Ansilble-Playbooks/website-cloner/main.yml"
# }

// we are creating an azure cdn with redirection rule based on the header (check the azure-ad module's main.tf for more info)
# module "azure-cdn" {
#     source              = "./modules/azure/azure-cdn"
#     resource_group_name = "RedTeamInfra"
#     cdn_profile_name    = "RedTeamInfraCDN"
#     cdn_endpoint_name   = "newhireintroinfo"
#     origin_name         = "newhireintroinfo"
#     host_name           = "newhireintro.com"
#     url_redirect_host   = "www.google.com"
# }

resource "null_resource" "ssh_config_cleanup" {
  # This triggers change on every apply, to ensure the destroy provisioner will run even if nothing else changes.
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    when = destroy
    command = "rm -f ${path.module}/ssh_config"
  }
}



