# Output the AMI ID used for the EC2 instance
output "aws_ami_id" {
  value = module.myapp-server.instance.ami
}

# output the public IP of the EC2 instance
output "ec2_public_ip" {
  value = module.myapp-server.instance.public_ip
}