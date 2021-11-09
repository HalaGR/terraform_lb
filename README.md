# Terraform Load Balancer Demo
## What is Terraform?
### Terraform is an open-source infrastructure as code software tool that provides a consistent CLI workflow to manage hundreds of cloud services. Terraform codifies cloud APIs into declarative configuration files.
you can download TF on your pc [here](https://www.terraform.io/downloads.html)

## About this project:
### In this project the main.tf code creats 2 EC2 Instances with Nginx installed on them on the default VPC and a Load Blancer that that forwards the users traffic to the servers (EC2 Instances).
![system image](/images/system.png)

## To Run on your pc do:
* you need to add your key valuse to your aws account in main.tf.

* Have Terraform installed on your pc, and path set up.
* In cmd at the directory in which this code is saved do:
```
terraform init
terraform plan
terraform apply
```
## Running the code would creat the following AWS resources:

* EC2 instances:
![ec2 image](/images/EC2.png)

* Load Balancer:
![lb image](/images/LB.png)

*  Target Group with the 2 EC2 instances created above:
![tg image](/images/SG.png)




