// define the providers and versions
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.63.0"
    }
  }
}

// define the variables
variable "awsprops" {
    type =  map(string)
    default = {
    region = "us-east-1"
    vpc = "vpc-5234832d" //-> mesti bikin
    ami = "ami-0c1bea58988a989155" // ec2 ami locator : https://cloud-images.ubuntu.com/locator/ec2/
    itype = "t2.micro"
    subnet = "subnet-81896c8e" //-> mesti bikin
    publicip = true
    keyname = "myseckey"
    secgroupname = "IAC-Sec-Group"
  }
}

resource "aws_vpc" "vpc" {
  cidr_block              = "10.0.1.0/24"
  instance_tenancy     = "default" #default,dedicated
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Environment = "DEV"
    Managed = "IAC"
  }
}


# Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"

  tags = {
    Environment = "DEV"
    Managed = "IAC"
  }
  depends_on = [ aws_vpc.vpc ]
  }

provider "aws" {
  region = lookup(var.awsprops, "region")
}


// https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "project-iac-sg" {
  name = lookup(var.awsprops, "secgroupname")
  description = lookup(var.awsprops, "secgroupname")
  vpc_id = aws_vpc.vpc.id // lookup(var.awsprops, "vpc")

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
  depends_on = [ aws_vpc.vpc ]  
}

// https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
resource "aws_instance" "project-iac" {
  ami = lookup(var.awsprops, "ami")
  instance_type = lookup(var.awsprops, "itype")
  subnet_id = aws_subnet.public_subnet.id //lookup(var.awsprops, "subnet") #FFXsubnet2
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

  depends_on = [ aws_security_group.project-iac-sg, aws_subnet.public_subnet ]
}


output "ec2instance" {
  value = aws_instance.project-iac.public_ip
}
output "dumymy-value" {
  value = "hello here is dummy"
}