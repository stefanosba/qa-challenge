# Terraform AWS VPC Module

This Terraform module creates an AWS VPC with flexible configurations to support different environments. It allows:

- Create a VPC with a /16 CIDR block
- Choose between single or multi AZ deployment
- Provision public and private subnets in each AZ
- Configure NAT Gateway as a single or multiple instances, depending on the egress strategy

---

## Usage

```hcl
module "vpc" {
  source          = "./terraform-vpc-module"
  vpc_cidr        = "10.0.0.0/16"
  multi_az        = true
  egress_strategy = "multi"
  region          = "eu-central-1"
  name_prefix     = "qa-challenge"
}
```

---

## Variable Details

- **`vpc_cidr`**:  
  The primary IP block for the VPC.

- **`multi_az`**:  
  If true, deploys infrastructure across 3 AZ.  
  If false, deploys everything in a single AZ.

- **`egress_strategy`**:  
  Controls how NAT Gateways are configured for outbound traffic from private subnets:  
  - `"single"`: one NAT Gateway shared by all private subnets.  
  - `"multi"`: one NAT Gateway per Availability Zone.

- **`region`**:  
  AWS region to deploy the resources.

- **`name_prefix`**:  
  Prefix tag for custom resources name.