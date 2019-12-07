# MySQL

# Generate DB Password
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

# Security Group(default)
resource "aws_security_group" "db_sg" {
  tags = { "Name" = "${var.name}-db-sg" }
  name = "${var.name}-db-sg"
  # description = "Used in the terraform"
  vpc_id = aws_vpc.default.id
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name = "${var.name}-db-subnet-group"
  subnet_ids = [
    aws_subnet.subnet_2a.id,
    aws_subnet.subnet_2c.id,
  ]
  depends_on = [
    aws_subnet.subnet_2a,
    aws_subnet.subnet_2c
  ]
}

resource "aws_db_instance" "db" {
  allocated_storage      = 5
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  name                   = "mydb"
  username               = "myuser"
  password               = random_password.db_password.result
  parameter_group_name   = "default.mysql5.7"
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = true
  depends_on = [
    random_password.db_password,
    aws_db_subnet_group.db_subnet_group,
    aws_security_group.db_sg,
  ]
}
