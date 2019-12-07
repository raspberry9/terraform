# ~/.ssh/id_rsa, id_rsa.pub required, if not run this command "ssh-keygent"

# Provider
# https://www.terraform.io/docs/providers/index.html
provider "aws" {
  # 사용 가능한 Region: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.RegionsAndAvailabilityZones.html
  region                  = "ap-northeast-2"
  shared_credentials_file = ".aws/credentials"
  # Example ~/.aws/credentials
  # [${var.name}]
  # aws_access_key_id=BLABLA
  # aws_secret_access_key=bLabLabLabLa
  profile = var.name
}

# KeyPair
# https://www.terraform.io/docs/providers/aws/r/key_pair.html
resource "aws_key_pair" "key_pair" {
  key_name   = "${var.name}_key_pair"
  public_key = file(var.public_key_path)
}

# VPC
resource "aws_vpc" "default" {
  tags       = { "Name" = "${var.name}-vpc" }
  cidr_block = "10.0.0.0/16"
}

# Enable Internet
resource "aws_internet_gateway" "default" {
  tags   = { "Name" = "${var.name}-igw" }
  vpc_id = aws_vpc.default.id
}
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.default.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
}

# Subnet 2a
resource "aws_subnet" "subnet_2a" {
  tags                    = { "Name" = "${var.name}-2a-subnet" }
  vpc_id                  = aws_vpc.default.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true
}

# Subnet 2c
resource "aws_subnet" "subnet_2c" {
  tags                    = { "Name" = "${var.name}-2c-subnet" }
  vpc_id                  = aws_vpc.default.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = true
}

# WORLD / ADMIN -> NLB
resource "aws_security_group" "lb_sg" {
  tags        = { "Name" = "${var.name}-lb-sg" }
  name        = "${var.name}-lb-sg"
  description = "Used in the terraform"
  vpc_id      = aws_vpc.default.id

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = var.whitelist_cidr_blocks
  }

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = var.whitelist_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# server Security Group
resource "aws_security_group" "server_sg" {
  tags        = { "Name" = "${var.name}-server-sg" }
  name        = "${var.name}-server-sg"
  description = "Used in the terraform"
  vpc_id      = aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Network LoadBalancer
resource "aws_lb" "nlb" {
  tags               = { "Name" = "${var.name}-nlb" }
  name               = "${var.name}-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets = [
    aws_subnet.subnet_2a.id,
    aws_subnet.subnet_2c.id
  ]

  # true이면 AWS Console에서 속성에서 protection 뻰 후 수동으로 지워야 함
  enable_deletion_protection = false
}

resource "aws_lb_listener" "lbl" {
  load_balancer_arn = aws_lb.nlb.arn
  for_each          = var.forwarding_all
  port              = each.key
  protocol          = each.value
  default_action {
    target_group_arn = aws_lb_target_group.lb_tg[each.key].arn
    type             = "forward"
  }
}

resource "aws_lb_target_group" "lb_tg" {
  for_each             = var.forwarding_all
  name                 = "${var.name}-${each.key}-${each.value}"
  tags                 = { "Name" = "${var.name}-lb_tg" }
  port                 = each.key
  protocol             = each.value
  vpc_id               = aws_vpc.default.id
  target_type          = "instance"
  deregistration_delay = 90
  health_check {
    interval            = 10 # Must be one of the following values '[10, 30]
    port                = each.value != "TCP_UDP" ? each.key : var.tcp_udp_health_port
    protocol            = "TCP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

# WORLD -> NLB -> SERVER
# server가 여러개인 경우 target_id = aws_instance.server[N].id 으로 여러개 생성 필요
resource "aws_lb_target_group_attachment" "lb_server_tga_0" {
  for_each         = var.forwarding_server
  target_group_arn = aws_lb_target_group.lb_tg[each.key].arn
  port             = each.key
  target_id        = aws_instance.server[0].id
}

# Ubuntu 18.04 hvm ebs
# https://www.terraform.io/docs/providers/aws/d/ami.html
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}
