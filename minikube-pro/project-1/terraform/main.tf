module "network" {
  source = "./modules/network"

  vpc_name = "xbrain-vpc"

  vpc_cidr = "10.0.0.0/16"

  public_subnet_1_cidr = "10.0.1.0/24"
  public_subnet_2_cidr = "10.0.2.0/24"

  az_1 = "ap-southeast-1a"
  az_2 = "ap-southeast-1b"
}

module "security_group" {
  source = "./modules/security_group"

  vpc_id = module.network.vpc_id

  my_ip = "${var.my_ip}/32"
}


module "ec2" {
  source = "./modules/ec2"

  instance_name = "xbrain-minikube"

  ami_id        = data.aws_ami.amazon_linux.id
  instance_type = "t3.medium"

  subnet_id = module.network.public_subnet_ids[0]

  security_group_id = module.security_group.ec2_sg_id

  key_name = aws_key_pair.ec2_key.key_name
}

data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

module "alb" {
  source = "./modules/alb"

  vpc_id = module.network.vpc_id

  subnet_ids = module.network.public_subnet_ids

  alb_sg_id = module.security_group.alb_sg_id

  instance_id = module.ec2.instance_id
}
