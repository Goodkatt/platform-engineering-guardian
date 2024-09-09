module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "guardian-bastion"
  ami = var.ubuntu-2204
  instance_type          = "t3.small"
  key_name               = "guardians"
  monitoring             = false
  vpc_security_group_ids = [ module.bastion_host_sg.security_group_id ]
  subnet_id              = module.vpc.public_subnets[0]
  associate_public_ip_address = true

  tags = {
    Assignment = "true"
  }
}


module "bastion_host_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "guardian-bastion-host"
  
  vpc_id      = module.vpc.vpc_id

  
  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "Home-VPN"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  egress_with_cidr_blocks = [ 
    {
      from_port   = 0
      to_port     = 0
      protocol    = -1
      description = "Internet"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

output "bastion_host_public_ip" {
    value = module.ec2_instance.public_ip
}