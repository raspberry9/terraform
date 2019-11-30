# Configure the AWS Provider

# 1. https://console.aws.amazon.com/iam/home?#/users 에서 적절한 iam 계정을 생성

# 2. IAM 권한 부여 및 계정 생성 후 ~/.aws/credentials 파일에 새로운 프로필 추가
# vi ~/.aws/credentials
# ------------------------------------------------
# [terraform]
# aws_access_key_id = ...
# aws_secret_access_key = ...
# ------------------------------------------------

provider "aws" {
  # 사용 가능한 Region: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.RegionsAndAvailabilityZones.html
  region                  = "ap-northeast-2"
  shared_credentials_file = ".aws/credentials"
  profile                 = "terraform"
}

resource "aws_key_pair" "hello_key_pair" {
  key_name   = "hello_key_pair"
  public_key = file("~/.ssh/id_rsa.pub")
}

# 혹은 아래와 같이 OS Environment에 access_key, secret_key를 넣고 사용
# export AWS_ACCESS_KEY_ID="..."
# export AWS_SECRET_ACCESS_KEY="..."
# export AWS_DEFAULT_REGION="ap-northeast-2"
# provider "aws" {}

# Create a VPC
# https://www.terraform.io/docs/providers/aws/r/vpc.html
resource "aws_vpc" "hello_vpc" {
  cidr_block           = "172.16.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"  # dedicated로 입력하면 전용 EC2를 사용
}

# 만약 Subnet을 아래와 같이 구성한다면
# 1. ap-northeast-2a
#   public: 172.16.1.0/24
#   private: 172.16.101.0/24
# 2. ap-northeast-2c
#   public: 172.16.2.0/24
#   private: 172.16.102.0/24

# Create a ap-northeast-2a public subnet
resource "aws_subnet" "hello_public_a" {
  vpc_id            = aws_vpc.hello_vpc.id
  availability_zone = "ap-northeast-2a"
  cidr_block        = "172.16.1.0/24"
  map_public_ip_on_launch = true
}
# Create a ap-northeast-2a private subnet
resource "aws_subnet" "hello_private_a" {
  vpc_id            = aws_vpc.hello_vpc.id
  availability_zone = "ap-northeast-2a"
  cidr_block        = "172.16.101.0/24"
}
# Create a ap-northeast-2c public subnet
resource "aws_subnet" "hello_public_c" {
  vpc_id            = aws_vpc.hello_vpc.id
  availability_zone = "ap-northeast-2c"
  cidr_block        = "172.16.2.0/24"
  map_public_ip_on_launch = true
}
# Create a ap-northeast-2c private subnet
resource "aws_subnet" "hello_private_c" {
  vpc_id            = aws_vpc.hello_vpc.id
  availability_zone = "ap-northeast-2c"
  cidr_block        = "172.16.102.0/24"
}

# Gateway
resource "aws_internet_gateway" "hello_gw" {
  vpc_id = aws_vpc.hello_vpc.id
}

# Ubuntu 18.04 LTS ami
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "hello_instance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.hello_private_a.id
  key_name      = aws_key_pair.hello_key_pair.key_name
  depends_on    = [aws_internet_gateway.hello_gw]
}

# $ terraform init
# $ terraform validate
# $ terraform plan
# $ terraform apply