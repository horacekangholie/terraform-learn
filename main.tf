terraform {
    required_version = ">= 0.12"
    backend "s3" {
        bucket = "myapp-bucket-horace"
        key = "myapp/state.tfstate"
        region = "ap-southeast-1"
    }
}

# Create VPC using a module
module "vpc" {
    source = "terraform-aws-modules/vpc/aws"

    name = "my-vpc"
    cidr = var.vpc_cidr_blocks

    azs             = [var.avail_zone]
    public_subnets  = [var.subnet_cidr_blocks]
    public_subnet_tags = { Name = "${var.env_prefix}-public-subnet-1" }

    tags = {
        Name = "${var.env_prefix}-vpc"
    }
}

# Create EC2 instance using a module
module "myapp-server" {
    source = "./modules/webserver"

    # Pass the VPC ID from the created VPC to the module
    vpc_id = module.vpc.vpc_id
    
    my_ip = var.my_ip
    env_prefix = var.env_prefix
    image_name = var.image_name
    public_key_location = var.public_key_location
    instance_type = var.instance_type
    avail_zone = var.avail_zone

    # Pass the first public subnet ID from the created VPC to the module
    subnet_id = module.vpc.public_subnets[0]
}














