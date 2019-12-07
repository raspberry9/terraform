variable "name" { default = "test" }
variable "ec2_user" { default = "ubuntu" }
variable "public_key_path" { default = "~/.ssh/id_rsa.pub" }
variable "private_key_path" { default = "~/.ssh/id_rsa" }
variable "whitelist_cidr_blocks" { default = [
  # "123.456.789.000/32",
] }

variable "db_shard_count" { default = 2 }
variable "server_scale_out_count" { default = 1 }

variable "forwarding_all" {
  default = {
    22   = "TCP" # SSH for admin
    5000 = "TCP" # server
    6379 = "TCP" # redis
    3306 = "TCP" # MySQL
  }
}

variable "forwarding_server" {
  default = {
    22   = "TCP" # SSH for admin
    5000 = "TCP" # server
  }
}

variable "forwarding_db" {
  default = {
    3306 = "TCP" # MySQL
  }
}

variable "forwarding_redis" {
  default = {
    6379 = "TCP" # Redis
  }
}

variable "tcp_udp_health_port" { default = 5000 }
