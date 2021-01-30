provider "aws" {
  region = var.aws_region
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

module "cluster" {
  source             = "../.."
  env_name           = "demo"
  subnet_id          = element(data.aws_subnet_ids.default.ids[*], 1)
  vpc_id             = data.aws_vpc.default.id
  instance_type      = "t3a.large"
  instance_disk_size = "25"
}
