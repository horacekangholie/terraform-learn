# Create VPC
resource "aws_vpc" "myapp-vpc" {
    cidr_block = var.vpc_cidr_blocks
    tags = {
        Name: "${var.env_prefix}-vpc"
    }
}

# Create subnet using a module
module "myapp-subnet" {
    source = "./modules/subnet"

    # Pass VPC ID and default route table ID from the created VPC to the module
    vpc_id = aws_vpc.myapp-vpc.id
    default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id

    # Pass variables to the module
    subnet_cidr_blocks = var.subnet_cidr_blocks
    avail_zone = var.avail_zone
    env_prefix = var.env_prefix
}

# Create EC2 instance using a module
module "myapp-server" {
    source = "./modules/webserver"

    # Pass the VPC ID from the created VPC to the module
    vpc_id = aws_vpc.myapp-vpc.id
    
    # Pass the IP address for SSH access, environment prefix, 
    # image name, public key location, instance type, and availability zone from the variables
    my_ip = var.my_ip
    env_prefix = var.env_prefix
    image_name = var.image_name
    public_key_location = var.public_key_location
    instance_type = var.instance_type
    avail_zone = var.avail_zone

    # Pass the subnet ID from the created subnet to the module
    subnet_id = module.myapp-subnet.subnet.id
}














