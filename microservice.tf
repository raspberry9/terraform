# 주의사항! WARNING! 반드시 읽으세요.

# 이 예제는 production에서 사용하기 부적합하며 반드시 성능, 보안 등을 검토 후 적절히 수정후에만 적용 가능 합니다.
# 이 예제는 애래의 참고자료들을 참고 하였으며, 이 예제를 참고하여 발생하는 법적, 도덕적 책임은 사용자 본인에게 있있음을
# 인정하는 경우에만 사용하십시오.
# 참고자료 1. AWS VPC, Subnet: https://www.44bits.io/ko/post/understanding_aws_vpc
# 참고자료 2. Terraform: https://www.44bits.io/ko/post/terraform_introduction_infrastrucute_as_code
#                      https://rampart81.github.io/post/vpc_confing_terraform/

# 1. https://console.aws.amazon.com/iam/home?#/users 에서 적절한 iam 계정을 생성

# 2. IAM 권한 부여 및 계정 생성 후 ~/.aws/credentials 파일에 새로운 프로필 추가
# vi ~/.aws/credentials
# ------------------------------------------------
# [terraform]
# aws_access_key_id = ...
# aws_secret_access_key = ...
# ------------------------------------------------

# Project Name
variable "name" { default = "hello"} # 각종 Tag Name에 prefix로 붙음(구분용)
variable "public_key_path" { default = "~/.ssh/id_rsa.pub" } # ssh로 생성된 서버에 접근시 필요한 public_key
variable "private_key_path" { default = "~/.ssh/id_rsa" }    # ssh로 생성된 서버에 접근시 필요한 private_key

# Configure the AWS Provider
# https://www.terraform.io/docs/providers/index.html
provider "aws" {
  # 사용 가능한 Region: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.RegionsAndAvailabilityZones.html
  region                  = "ap-northeast-2"
  shared_credentials_file = ".aws/credentials"
  profile                 = "terraform"
}

# https://www.terraform.io/docs/providers/aws/r/key_pair.html
resource "aws_key_pair" "key_pair" {
  key_name   = "${var.name}_key_pair"
  public_key = file(var.public_key_path)
}

# 위와 같이 사용하지 않고 아래와 같이 OS Environment에 access_key, secret_key를 넣고 사용 가능
# export AWS_ACCESS_KEY_ID="..."
# export AWS_SECRET_ACCESS_KEY="..."
# export AWS_DEFAULT_REGION="ap-northeast-2"
# provider "aws" {}

# VPC 생성
# https://www.terraform.io/docs/providers/aws/r/vpc.html
resource "aws_vpc" "dmz" {
  tags = { "Name" = "${var.name}-dmz" }
  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true # VPC 내부에서 생성되는 인스턴스에 퍼블릭 DNS 호스트네임을 할당해주는 기능
  instance_tenancy     = "default"  # dedicated로 입력하면 전용 EC2를 사용
}
resource "aws_vpc" "app" {
  tags = { "Name" = "${var.name}-app" }
  cidr_block           = "10.2.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# VPC에 Subnet 생성
resource "aws_subnet" "dmz_public_a" {
  tags = { "Name" = "${var.name}-dmz_public_a" }
	vpc_id            = aws_vpc.dmz.id
	cidr_block        = "10.1.1.0/24"
	availability_zone = "ap-northeast-2a"
}
resource "aws_subnet" "dmz_public_c" {
  tags = { "Name" = "${var.name}-dmz_public_c" }
	vpc_id            = aws_vpc.dmz.id
	cidr_block        = "10.1.2.0/24"
	availability_zone = "ap-northeast-2c"
}
resource "aws_subnet" "app_public_a" {
  tags = { "Name" = "${var.name}-app_public_a" }
	vpc_id            = aws_vpc.app.id
	cidr_block        = "10.2.1.0/24"
	availability_zone = "ap-northeast-2a"
}
resource "aws_subnet" "app_public_c" {
  tags = { "Name" = "${var.name}-app_public_c" }
	vpc_id            = aws_vpc.app.id
	cidr_block        = "10.2.2.0/24"
	availability_zone = "ap-northeast-2c"
}
resource "aws_subnet" "app_private_a" {
  tags = { "Name" = "${var.name}-app_private_a" }
	vpc_id            = aws_vpc.app.id
	cidr_block        = "10.2.3.0/24"
	availability_zone = "ap-northeast-2a"
}
resource "aws_subnet" "app_private_c" {
  tags = { "Name" = "${var.name}-app_private_c" }
	vpc_id            = aws_vpc.app.id
	cidr_block        = "10.2.4.0/24"
	availability_zone = "ap-northeast-2c"
}

# Route tables 생성
resource "aws_default_route_table" "dmz_default" {
  tags = { "Name" = "${var.name}-dmz_default" }
  default_route_table_id = aws_vpc.dmz.default_route_table_id
}
resource "aws_default_route_table" "app_default" {
  tags = { "Name" = "${var.name}-app_default" }
  default_route_table_id = aws_vpc.app.default_route_table_id
}
resource "aws_route_table" "app_private" {
  tags = { "Name" = "${var.name}-app_private" }
  vpc_id = aws_vpc.app.id
}
# ㄲoute table 연결
resource "aws_route_table_association" "dmz_public_a" {
	subnet_id      = aws_subnet.dmz_public_a.id
	route_table_id = aws_vpc.dmz.default_route_table_id
}
resource "aws_route_table_association" "dmz_public_c" {
	subnet_id      = aws_subnet.dmz_public_c.id
	route_table_id = aws_vpc.dmz.default_route_table_id
}
resource "aws_route_table_association" "app_public_a" {
	subnet_id      = aws_subnet.app_public_a.id
	route_table_id = aws_vpc.app.default_route_table_id
}
resource "aws_route_table_association" "app_public_c" {
	subnet_id      = aws_subnet.app_public_c.id
	route_table_id = aws_vpc.app.default_route_table_id
}
resource "aws_route_table_association" "app_private_a" {
	subnet_id      = aws_subnet.app_private_a.id
	route_table_id = aws_route_table.app_private.id
}
resource "aws_route_table_association" "appl_private_c" {
	subnet_id      = aws_subnet.app_private_c.id
	route_table_id = aws_route_table.app_private.id
}

# 내부 인스턴스가 인터넷을 이용하기 위하여 Internet Gateway를 생성
resource "aws_internet_gateway" "dmz" {
  tags = { "Name" = "${var.name}-dmz" }
  vpc_id = aws_vpc.dmz.id
}
resource "aws_internet_gateway" "app" {
  tags = { "Name" = "${var.name}-app" }
  vpc_id = aws_vpc.app.id
}
# Internet Gateway와 route table 연결
resource "aws_route" "dmz_public" {
	route_table_id         = aws_vpc.dmz.default_route_table_id
	destination_cidr_block = "0.0.0.0/0"
	gateway_id             = aws_internet_gateway.dmz.id
}
resource "aws_route" "app_public" {
	route_table_id         = aws_vpc.app.default_route_table_id
	destination_cidr_block = "0.0.0.0/0"
	gateway_id             = aws_internet_gateway.app.id
}

# NAT(Elastic IP Address)
resource "aws_eip" "app_nat" { vpc = true }
resource "aws_nat_gateway" "app" {
  allocation_id = aws_eip.app_nat.id
  subnet_id     = aws_subnet.app_public_a.id
}
# private 서브넷이 NAT을 통해 우회적으로 인터넷 접속이 가능하게 한다.
resource "aws_route" "app_private" {
	route_table_id         = aws_route_table.app_private.id
	destination_cidr_block = "0.0.0.0/0"
	nat_gateway_id         = aws_nat_gateway.app.id
}

# dmz와 app간 VPC Peering Connection 생성
data "aws_caller_identity" "current" { }
resource "aws_vpc_peering_connection" "dmz_to_app" {
  vpc_id = aws_vpc.app.id
  peer_owner_id = data.aws_caller_identity.current.account_id
  peer_vpc_id = aws_vpc.dmz.id
  # auto_accept는 true로 설정해서 vpc peering connection을 자동으로 accept하도록 한다
  # vpc들이 같은 AWS 계정에 속해있을때만 가능
  auto_accept = true
}
# VPC Peering Connection을 각 VPC의 route table들에 지정
resource "aws_route" "peering_to_app" {
  route_table_id = aws_vpc.dmz.default_route_table_id
  destination_cidr_block = aws_vpc.app.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.dmz_to_app.id
}
resource "aws_route" "peering_from_dmz" {
  route_table_id = aws_route_table.app_private.id
  destination_cidr_block = aws_vpc.dmz.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.dmz_to_app.id
}

# 이하는 web 서버 EC2 생성

# Ubuntu 18.04 hvm ebs
# https://www.terraform.io/docs/providers/aws/d/ami.html
data "aws_ami" "ubuntu" {
  most_recent = true
  owners = ["099720109477"] # Canonical
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

# CentOS 7 hvm ebs
# https://www.terraform.io/docs/providers/aws/d/ami.html
data "aws_ami" "centos" {
  most_recent = true
  owners      = ["679593333241"] # Centos.org
  filter {
    name   = "name"
    values = ["CentOS Linux 7 x86_64 HVM EBS *"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# 보안 그룹 생성
resource "aws_security_group" "app_sg" {
  name = "${var.name}-app_sg"
  vpc_id      = aws_vpc.app.id
  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]  # 위험하므로 관리자의 IP로 제한해야 함
  }

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 아래는 가용영역 a로만 인스턴스를 생성했으나, 실제로는 a, c 둘 다 만들고 로드밸런서를 앞에 두면 가용성이 높아짐
# https://www.terraform.io/docs/providers/aws/r/instance.html
resource "aws_instance" "web_a" {
  tags = { "Name" = "${var.name}-web_a" }
  ami           = data.aws_ami.ubuntu.id # data.aws_ami.centos.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.app_public_a.id # aws_subnet.app_public_c.id
  security_groups = [aws_security_group.app_sg.id]
  associate_public_ip_address = true
  key_name      = aws_key_pair.key_pair.key_name

  connection {
    user         = "ubuntu"
    host         = self.public_ip
    private_key  = file(var.private_key_path)
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install apache2 -y",
      "sudo systemctl enable apache2",
      "sudo systemctl start apache2",
      "sudo chmod 777 /var/www/html/index.html"
    ]
  }

  # 로켈(admin 사용자)의 index.html 파일을 서버에 올려서 테스트로 사용함
  provisioner "file" {
    source = "index.html"
    destination = "/var/www/html/index.html"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod 644 /var/www/html/index.html"
    ]
  }

  # 아래와 같이 내부에서 특정 명령을 실행하여 admin 로컬에 파일로 출력할 수 있음
  # provisioner "local-exec" {
  #   command = "echo ${aws_instance.web_a.public_ip} > public-ip.txt"
  # }

  depends_on    = [
    aws_security_group.sg
  ]
}

# apply가 끝나고 ssh를 접속할 수있도록 output으로 알려줌
output "ssh_connection" {
  description = "show ssh connecting command"
  value       = "Try run this command,\n\tssh -i ${var.private_key_path} ubuntu@${aws_instance.web_a.public_dns}"
}

# apply가 끝나고 http를 접속할 수있도록 output으로 알려줌
output "http_test" {
  description = "show http test url"
  value       = "http://${aws_instance.web_a.public_dns}"
}

# 아래는 MySQL, Redis를 사용할 부분이며 현재 작성중

# # ElasticCache Subnet Group
# resource "aws_elasticache_subnet_group" "subnet_group" {
#   name       = "${var.name}-ec-subnet-group"
#   subnet_ids = [
#     aws_subnet.private_a.id,
#     # aws_subnet.private_c.id
#   ]
# }

# # Create a ElasticCache(Redis) cluster
# resource "aws_elasticache_cluster" "redis" {
#   cluster_id           = "${var.name}-redis-cluster"
#   engine               = "redis"
#   # node_type            = "cache.m4.large" # production
#   node_type            = "cache.t2.micro" # development
#   num_cache_nodes      = 1
#   parameter_group_name = "default.redis5.0"
#   engine_version       = "5.0.5"
#   port                 = 6379
#   subnet_group_name = aws_elasticache_subnet_group.subnet_group.name
# }

# resource "random_password" "db_password" {
#   length = 16
#   special = true
#   override_special = "_%@"
# }

# # Create a RDS(MySQL) instance
# resource "aws_db_instance" "db" {
#   allocated_storage    = 5
#   storage_type         = "gp2"
#   engine               = "mysql"
#   engine_version       = "5.7"
#   instance_class       = "db.t2.micro"
#   name                 = "webdb"
#   username             = "${var.name}user"
#   password             = random_password.db_password.result
#   parameter_group_name = "default.mysql5.7"

#   # if false and run terraform destroy you can see this,
#   # Error: DB Instance FinalSnapshotIdentifier is required when a final snapshot is required
#   skip_final_snapshot = true
# }

# # Configure the MySQL provider based on the outcome of
# # creating the aws_db_instance.
# provider "mysql" {
#   endpoint = "${aws_db_instance.db.endpoint}"
#   username = "${aws_db_instance.db.username}"
#   password = "${aws_db_instance.db.password}"
# }

# # Create a second database, in addition to the "initial_db" created
# # by the aws_db_instance resource above.
# resource "mysql_database" "app" {
#   name = "another_db"
# }

# # Output
# output "rds_dsn" {
#   value = "${aws_db_instance.db.engine}://${aws_db_instance.db.username}:${aws_db_instance.db.password}@${aws_db_instance.db.endpoint}/${aws_db_instance.db.name}"
# }
