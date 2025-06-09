provider "aws" {
  region  = var.region
  profile = var.profile
}

# Test Case 1: Single AZ + Single NAT GW
# --------------------------------------
module "vpc_single_az_single_nat" {
 source          = "./modules/vpc/"
 vpc_cidr        = "10.0.0.0/16"
 multi_az        = false
 egress_strategy = "single"
 region          = var.region
 name_prefix     = "qa-challenge"
}

# Test Case 2: Multi AZ + Single NAT GW
# -------------------------------------
# module "vpc_multi_az_single_nat" {
#  source          = "./modules/vpc/"
#  vpc_cidr        = "10.1.0.0/16"
#  multi_az        = true
#  egress_strategy = "single"
#  region          = var.region
#  name_prefix     = "qa-challenge"
# }


# Test Case 3: Multi AZ + Multi NAT GW
# ------------------------------------
# module "vpc_multi_az_multi_nat" {
#   source          = "./modules/vpc/"
#   vpc_cidr        = "10.2.0.0/16"
#   multi_az        = true
#   egress_strategy = "multi"
#   region          = var.region
#   name_prefix     = "qa-challenge"
# }