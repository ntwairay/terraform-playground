# Terraform Assessment

## Create EC2 instance with Terraform - Terraform EC2

As we have crossed all the sections of basic and prerequisites. We are now ready to move forward to the practical application of Terraform and we are going to create an EC2 instance with terraform.

These are the list of steps we are going to perform

1. Create a Directory and Download the following file and save it as `main.tf`
2. Execute the command `terraform init` to initialize
3. Execute the command `terraform plan` to check what change would be made. ( Should always do it)
4. If you are happy with the changes it is claiming to make, then execute `terraform apply` to commit and start the build

### Step1: Creating a Configuration file for Terraform AWS

Copy the following content and save it as `main.tf`  and make sure that the directory has no other `*.tf` files present, as terraform would consider all the files ending with **.tf** extension

I have given some explanation before each block on the configuration to explain the purpose of the block.

In an overview, This is what we are doing in this configuration file.

- A Variable block where we define all the resource names that we are going to be using within the Terraform configuration
- The second block is to tell Terraform to choose the right provider, in our case it is `aws` and we are also defining the region in this block on which our resources should be created
- Creating a Security Group with **inbound** and **outbound** rules. We have two inbound rules and one outbound rule. we use **lifecycle** block to tell terraform to create the replacement resources first before destroying the live ones. this way we reduce downtime
- Creating an EC2 instance, The instance type would be picked up from the **variables** block and we give some meaningful `tags` for management and future identification
- Once the EC2 instance created, we would get the public IP of the instance. We are saving it as an output variable. The output variables would be saved locally and can be viewed anytime in the future with `terraform output` command

### The Terraform AWS Example configuration file

Here is the Terraform configuration file or manifest to create EC2 instance.

```
variable "awsprops" {
    type = "map"
    default = {
    region = "us-east-1"
    vpc = "vpc-5234832d"
    ami = "ami-0c1bea58988a989155"
    itype = "t2.micro"
    subnet = "subnet-81896c8e"
    publicip = true
    keyname = "myseckey"
    secgroupname = "IAC-Sec-Group"
  }
}

provider "aws" {
  region = lookup(var.awsprops, "region")
}

resource "aws_security_group" "project-iac-sg" {
  name = lookup(var.awsprops, "secgroupname")
  description = lookup(var.awsprops, "secgroupname")
  vpc_id = lookup(var.awsprops, "vpc")

  // To Allow SSH Transport
  ingress {
    from_port = 22
    protocol = "tcp"
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  // To Allow Port 80 Transport
  ingress {
    from_port = 80
    protocol = ""
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "project-iac" {
  ami = lookup(var.awsprops, "ami")
  instance_type = lookup(var.awsprops, "itype")
  subnet_id = lookup(var.awsprops, "subnet") #FFXsubnet2
  associate_public_ip_address = lookup(var.awsprops, "publicip")
  key_name = lookup(var.awsprops, "keyname")

  vpc_security_group_ids = [
    aws_security_group.project-iac-sg.id
  ]
  root_block_device {
    delete_on_termination = true
    iops = 150
    volume_size = 50
    volume_type = "gp2"
  }
  tags = {
    Name ="SERVER01"
    Environment = "DEV"
    OS = "UBUNTU"
    Managed = "IAC"
  }

  depends_on = [ aws_security_group.project-iac-sg ]
}

output "ec2instance" {
  value = aws_instance.project-iac.public_ip
}
```

### Step2: Initialize Terraform

Once we have saved the File in the newly created directory, we need to initialize terraform

If you have used `Git` this is similar to `git init`  where we set up some local repository and initialize

```
➜terraform init

Initializing the backend...

Initializing provider plugins...
- Checkingfor available provider plugins...
- Downloading pluginfor provider "aws" (hashicorp/aws) 2.44.0...

The following providersdo not have any version constraintsin configuration,
so the latest version was installed.

To prevent automatic upgrades to new major versions that may contain breaking
changes, it is recommended to add version = "..." constraints to the
corresponding provider blocksin configuration, with the constraint strings
suggested below.

* provider.aws: version = "~> 2.44"

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are requiredfor your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configurationfor Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you todo soif necessary.

```

Once the Initialization completed. You can execute the `terraform plan` command to see what changes are going to be made.

### Step3: Pre-Validate the change - A pilot run

Execute the `terraform plan` command and it would present some detailed info on what changes are going to be made into your AWS infra.

the `-out tfplan` is to save the result given by plan so that we can refer it later and apply it as it is without any modification.

It also guarantees that what we see in the planning phase would be applied when we go for committing it.

- Click to expand
    
    ```
    
    ```
    
    ```
    
    ```
    

You can verify the outputs shown and what resources are going to be created or destroyed. Sometimes while doing a modification to the existing resources, Terraform would have to destroy the resource first and recreate it. in such cases, It would mention that it is going to destroy.

You should always look for the `+` and `-` signs on the `terraform plan` output.

Besides that, you should also monitor this line every time you run this command to make sure that no unintended result happen

```
Plan: 2 to add, 0 to change, 0 to destroy.

```

### Step4: Go ahead and Apply it with Terraform apply

When you execute the `terraform apply` command the changes would be applied to the AWS Infra.

If `terraform plan` is a trial run and test.  `terraform apply` is real-time and production.

Since we have saved the plan output to a file named `tfplan` to guarantee the changes. we need to use this file as an input while running the `apply` command

```
➜  terraform apply "tfplan"
aws_security_group.project-iac-sg: Creating...
aws_security_group.project-iac-sg: Still creating... [10s elapsed]
aws_security_group.project-iac-sg: Creation complete after 15s [id=sg-0fd7db3ea267c2527]
aws_instance.project-iac: Creating...
aws_instance.project-iac: Still creating... [10s elapsed]
aws_instance.project-iac: Still creating... [20s elapsed]
aws_instance.project-iac: Still creating... [30s elapsed]
aws_instance.project-iac: Creation complete after 31s [id=i-0d93c366fb2c4a3eb]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Thestate of your infrastructure has been savedto the path
below. Thisstate is requiredto modify and destroy your
infrastructure, sokeep it safe. To inspect the completestate
use the `terraform show` command.

State path: terraform.tfstate

Outputs:

ec2instance = 18.207.239.217
```

From the preceding output, you can see the instance creation took only 31 seconds and it completed and gave us the `public ip` as an output

Whenever we want this IP, we can come to this directory and execute `terraform output` to get it.

Refer the following snapshot where I have successfully `SSHed` to the server using  the `public IP`

![https://www.middlewareinventory.com/wp-content/uploads/2020/01/Screenshot-2020-01-13-at-7.48.24-PM.png](https://www.middlewareinventory.com/wp-content/uploads/2020/01/Screenshot-2020-01-13-at-7.48.24-PM.png)

So we have Successfully created an EC2 instance and a Security Group and logged into the Server.

Since this is a test instance, I want to destroy the resources I have created and I can do it by executing `terraform destroy` command.

Hope this article helps you understand, How Terraform AWS or Terraform EC2 instance creation works in real-time.