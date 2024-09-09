module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "demodb"

  engine            = "mysql"
  engine_version    = "5.7"
  instance_class    = "db.t3.small"
  allocated_storage = 5

  db_name  = "demodb"
  username = "admin"
  port     = "3306"


  vpc_security_group_ids = [ module.vpc.default_security_group_id ]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"
  
  manage_master_user_password = true
  

  tags = {
    Assignment       = "true"
  }

  
  create_db_subnet_group = true
  subnet_ids = module.vpc.private_subnets
  
  
  create_db_option_group = false
  create_db_parameter_group = false
  publicly_accessible = false
  
  family = "mysql5.7"


  major_engine_version = "5.7"

  
  deletion_protection = false

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8mb4"
    },
    {
      name  = "character_set_server"
      value = "utf8mb4"
    }
  ]

}

output "secret_arn" {
    value = module.db.db_instance_master_user_secret_arn
}
output "rds_endpoint" {
    value = module.db.db_instance_endpoint
}