module "network" {
  source = "../../modules/network"

  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}


module "monitoring" {
  source = "../../modules/monitoring"

  project_name = var.project_name
  vpc_id       = module.network.vpc_id
  subnet_id    = module.network.public_subnet_ids[0]

  allowed_ssh_cidr = var.allowed_ssh_cidr
  instance_type    = var.instance_type
  key_name         = var.key_name
}

