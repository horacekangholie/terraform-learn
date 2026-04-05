# Create default security group and add rules
resource "aws_security_group" "myapp-sg" {
    vpc_id = var.vpc_id
    name = "myapp-sg"

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
        values = [var.image_name]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }
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
    subnet_id = var.subnet_id
    vpc_security_group_ids = [aws_security_group.myapp-sg.id]
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