# =====================================================================
#  Root configuration — wires the modules together (Task 6.5).
# =====================================================================

module "vpc" {
  source  = "./modules/vpc"
  project = var.project
  azs     = var.azs
}

module "security" {
  source  = "./modules/security"
  project = var.project
  vpc_id  = module.vpc.vpc_id
}

module "ecr" {
  source          = "./modules/ecr"
  repository_name = "flask-app"
}

module "eks" {
  source             = "./modules/eks"
  project            = var.project
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
}

module "rds" {
  source               = "./modules/rds"
  project              = var.project
  private_subnet_ids   = module.vpc.private_subnet_ids
  db_security_group_id = module.security.db_security_group_id
  db_password          = var.db_password
}
