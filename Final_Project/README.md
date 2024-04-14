--------------------------------------------------------------------------------------------------------------------------------------------

### Steps to use this infra automation framework
1. Go to main.tf and uncomment/comment out the modules you don't want and fill in the values accordingly
2. Open variables.tf file and fill in the values
4. Open terminal in the same folder and run terraform init to initiate following with terraform validate to see for any errors and then terraform plan to cross
   check if everything will go smooth on your AWS Infra and then finally do terraform run

After the `terraform apply` is run, it will create a bash file an `ssh_config` file which you can use to ssh into any hosts without worrying about port forwarding.
```bash
ssh -F ssh_config bastion       # to ssh into bastion host
ssh -F ssh_config evilginx      # to ssh into evilginx host
ssh -F ssh_config gophish       # to ssh into gophish host
ssh -F ssh_config redelk        # to ssh into redelk host
```

When you ssh into gophish or redelk host, it will also setup a portforwarding for you automatically

### RedELK Interface (https://127.0.0.1) 
### Credentials
Username: redelk
Password: redelk@123

#### PHISHING #####
### Gophish Interface (https://127.0.0.1:3333) 
### Credentials
Username: admin
Password: gophish@123

### Command to replace/taint a resource
terraform apply -replace aws_instance.httpredir-host

