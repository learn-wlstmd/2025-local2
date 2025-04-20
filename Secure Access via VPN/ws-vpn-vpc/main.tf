module "vpc" {
  source = "./modules"

  vpc_name = local.vpc.name
  vpc_cidr = local.vpc.cidr

  public_subnet_a_name  = "ws-public-subnet-a"
  public_subnet_a_cidr  = "10.99.0.0/24"

  public_subnet_b_name  = "ws-public-subnet-b"
  public_subnet_b_cidr  = "10.99.1.0/24"

  private_subnet_a_name =  "ws-private-subnet-a"
  private_subnet_a_cidr = "10.99.10.0/24"

  private_subnet_b_name =  "ws-private-subnet-b"
  private_subnet_b_cidr = "10.99.11.0/24"

  igw_name = "ws-igw"

  nat_a_name = "ws-natgw-a"
  nat_b_name = "ws-natgw-b"

  public_rt_name = "ws-public-rt"
  private_a_rt_name = "ws-private-rt-a"
  private_b_rt_name = "ws-private-rt-b"
}