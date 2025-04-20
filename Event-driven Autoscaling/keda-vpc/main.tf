module "vpc" {
  source = "./modules"

  vpc_name = local.vpc.name
  vpc_cidr = local.vpc.cidr

  public_subnet_a_name  = "keda-public-subnet-a"
  public_subnet_a_cidr  = "10.0.0.0/24"

  public_subnet_b_name  = "keda-public-subnet-b"
  public_subnet_b_cidr  = "10.0.1.0/24"

  private_subnet_a_name =  "keda-private-subnet-a"
  private_subnet_a_cidr = "10.0.10.0/24"

  private_subnet_b_name =  "keda-private-subnet-b"
  private_subnet_b_cidr = "10.0.11.0/24"

  igw_name = "keda-igw"

  nat_a_name = "keda-natgw-a"
  nat_b_name = "keda-natgw-b"

  public_rt_name = "keda-public-rt"
  private_a_rt_name = "keda-private-rt-a"
  private_b_rt_name = "keda-private-rt-b"
}