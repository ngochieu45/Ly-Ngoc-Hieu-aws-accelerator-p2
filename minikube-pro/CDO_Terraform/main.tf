module "vpc" {
  source = "./modules/vpc"
}

module "security_groups" {
  source = "./modules/security_groups"

  vpc_id = module.vpc.vpc_id
}

module "rds" {
  source = "./modules/rds"

  private_subnet_1 = module.vpc.private_subnet_1_id
  private_subnet_2 = module.vpc.private_subnet_2_id

  db_sg_id = module.security_groups.db_sg_id

  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password
}

module "ec2" {
  source = "./modules/ec2"

  public_subnet_id = module.vpc.public_subnet_1_id
  web_sg_id        = module.security_groups.web_sg_id

  db_host     = module.rds.db_endpoint
  db_name     = var.db_name
  db_user     = var.db_username
  db_password = var.db_password
}
