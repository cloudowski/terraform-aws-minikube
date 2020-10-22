terraform {
  required_version = "~> 0.13.2"
}

locals {
  bootstrap_file_name = "${path.module}/bootstrap.sh"
}

data "aws_ami" "ubuntu_20_04" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "this" {
  key_name   = "${var.env_name}-k8s-minikube"
  public_key = tls_private_key.this.public_key_openssh
}

data "aws_availability_zones" "available" {
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 3.0"

  name        = "${var.env_name}-k8s-minikube"
  description = "K8s Kind Cluster"
  vpc_id      = var.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["ssh-tcp", "all-icmp", "all-tcp"]
  egress_rules        = ["all-all"]
}




resource "aws_iam_role" "node" {
  name = "${var.env_name}-k8s-minikube"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "node" {
  name        = "${var.env_name}-k8s-minikube"
  path        = "/"
  description = "Policy for role ${var.env_name}-k8s-minikube"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:*"
                ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "node" {
  name       = "${var.env_name}-k8s-minikube"
  roles      = [aws_iam_role.node.name]
  policy_arn = aws_iam_policy.node.arn
}

resource "aws_iam_instance_profile" "node" {
  name = "${var.env_name}-k8s-minikube"
  role = aws_iam_role.node.name
}

module "node" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 2.0"

  name             = "${var.env_name}-k8s-minikube"
  user_data_base64 = "${base64encode(file(local.bootstrap_file_name))}"
  ami              = data.aws_ami.ubuntu_20_04.id
  instance_type    = var.instance_type
  key_name         = aws_key_pair.this.key_name
  subnet_id        = var.subnet_id

  iam_instance_profile = aws_iam_instance_profile.node.name

  vpc_security_group_ids = [module.security_group.this_security_group_id]

  root_block_device = [{
    volume_size = var.instance_disk_size
    volume_type = "gp2"
  }]

  tags = {
    "kubernetes.io/cluster/${var.env_name}-k8s-minikube" = "shared"
    "KubernetesCluster"                                  = "${var.env_name}-k8s-minikube"
  }

}
