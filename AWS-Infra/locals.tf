locals {
    azs_locals             = [ "eu-west-1a", "eu-west-1b", "eu-west-1c" ]
    private_subnets_locals = [ "172.0.59.0/24", "172.0.60.0/24", "172.0.61.0/24" ]
    public_subnets_locals  = [ "172.0.89.0/24", "172.0.90.0/24", "172.0.91.0/24" ]
}