provider "aws" {
  region  = var.region
}

module "vpc" {
  source   = "../../modules/vpc"
  prj_name = local.prj_name
  region   = var.region
  vpc_cidr = var.vpc_cidr
}

module "ssm" {
  source   = "../../modules/ssm"
  prj_name = local.prj_name
  vpc_id   = module.vpc.vpc_id
  vpc_cidr = module.vpc.vpc_cidr
  private_subnet_ids = module.vpc.private_subnet_ids
}

module "security-groups" {
  source   = "../../modules/security-groups"
  prj_name = local.prj_name
  vpc_id   = module.vpc.vpc_id
  vpc_cidr = module.vpc.vpc_cidr
}

module "auto-scaling" {
  source   = "../../modules/auto-scaling"
  prj_name           = local.prj_name
  ami_id             = var.web_ami_id
  instance_type      = var.web_instance_type
  instance_profile   = module.ssm.ssm_instance_profile
  vpc_id             = module.vpc.vpc_id
  public_sg_id       = module.security-groups.public_sg_id
  private_sg_id      = module.security-groups.private_sg_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
}