
# Define variables
variable "default_region" {}
variable "vpc_cidr_blocks" {}
variable "subnet_cidr_blocks" {}
variable "avail_zone" {}
variable "env_prefix" {}
variable "my_ip" {}
variable "instance_type" {}
variable "public_key_location" {}

# Configure the AWS provider
provider "aws" {
    region = var.default_region
}

# Create VPC
resource "aws_vpc" "myapp-vpc" {
    cidr_block = var.vpc_cidr_blocks
    tags = {
        Name: "${var.env_prefix}-vpc"
    }
}

# Create Subnet
resource "aws_subnet" "myapp-subnet-1" {
    vpc_id = aws_vpc.myapp-vpc.id
    cidr_block = var.subnet_cidr_blocks
    availability_zone = var.avail_zone
    tags = {
        Name: "${var.env_prefix}-subnet-1"
    }
}

# Create Internet Gateway
resource "aws_internet_gateway" "myapp-igw" {
    vpc_id = aws_vpc.myapp-vpc.id
    tags = {
        Name: "${var.env_prefix}-igw"
    }
}

# Use default route table and add a route to the Internet Gateway
resource "aws_default_route_table" "main-rtb" {
    default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id
    }
    tags = {
        Name: "${var.env_prefix}-main-rtb"
    }    
}

# Associate the subnet with the route table to ensure public internet access
resource "aws_route_table_association" "a-rtb-subnet" {
    subnet_id      = aws_subnet.myapp-subnet-1.id
    route_table_id = aws_default_route_table.main-rtb.id
}

# Create default security group and add rules
resource "aws_default_security_group" "default-sg" {
    vpc_id = aws_vpc.myapp-vpc.id    

    # Allow SSH access from the specified IP
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.my_ip]
    }

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Allow all outbound traffic on all protocols and ports
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name: "${var.env_prefix}-default-sg"
    }
}

# Get the latest Amazon Linux 2023 AMI
data "aws_ami" "latest_amazon_linux-image" {
    most_recent = true
    owners = ["amazon"]    
    filter {
        name   = "name"
        values = ["al2023-ami-*-x86_64"]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }
}

# Output the AMI ID for verification
output "aws_ami_id" {
    value = data.aws_ami.latest_amazon_linux-image.id
}

# output the public IP of the EC2 instance
output "ec2_public_ip" {
  value = aws_instance.myapp-server.public_ip
}

# Create a key pair using the public key from the specified location
resource "aws_key_pair" "server-key-pair" {
    key_name = "server-key"
    public_key = file(var.public_key_location)
}

# Create EC2 instance
resource "aws_instance" "myapp-server" {
    ami = data.aws_ami.latest_amazon_linux-image.id
    instance_type = var.instance_type

    # Associate the instance with the subnet and security group
    subnet_id = aws_subnet.myapp-subnet-1.id
    vpc_security_group_ids = [aws_default_security_group.default-sg.id]
    availability_zone = var.avail_zone

    # Associate a public IP address to the instance
    associate_public_ip_address = true

    # Use an existing key pair for SSH access
    key_name = aws_key_pair.server-key-pair.key_name

    # Run script to install and start the web server
    user_data = file("entry-script.sh")

    tags = {
        Name: "${var.env_prefix}-server"
    }
}














