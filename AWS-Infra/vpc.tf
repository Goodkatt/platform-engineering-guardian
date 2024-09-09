provider "aws" {
    region = "eu-west-1"

}

module "vpc" {
    source = "terraform-aws-modules/vpc/aws"

    name = "guardian-task"
    cidr = "172.0.0.0/16"

    azs = local.azs_locals 
    private_subnets =  local.private_subnets_locals
    public_subnets = local.public_subnets_locals 

    enable_nat_gateway = true
    enable_vpn_gateway = false
    single_nat_gateway = true
    one_nat_gateway_per_az = false
    default_security_group_ingress = [ 
        {
            from_port = 0
            to_port = 0
            protocol = -1
            cidr_blocks = "0.0.0.0/0"
        }
     ]
    default_security_group_egress = [
        {
            from_port = 0
            to_port = 0
            protocol = -1
            cidr_blocks = "0.0.0.0/0"
        }
    ]


    tags = {
        Assignment = "true"
    }
    public_subnet_tags = {
        "kubernetes.io/role/elb" = 1
    }
    private_subnet_tags = {
        "kubernetes.io/role/internal-elb" = 1
    }
    
}