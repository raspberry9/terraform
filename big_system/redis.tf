# Redis
# Security Group(default)
resource "aws_security_group" "redis_sg" {
  tags = { "Name" = "${var.name}-redis-sg" }
  name = "${var.name}-redis-sg"
  # description = "Used in the terraform"
  vpc_id = aws_vpc.default.id
  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name = "${var.name}-ec-subnet-group"
  subnet_ids = [
    aws_subnet.subnet_2a.id,
    aws_subnet.subnet_2c.id,
  ]
}
resource "aws_elasticache_cluster" "admin_redis" {
  cluster_id = "${var.name}-admin-redis-cluster"
  engine     = "redis"
  # node_type            = "cache.m4.large" # production
  node_type            = "cache.t2.micro" # development
  num_cache_nodes      = 1
  parameter_group_name = "default.redis5.0"
  engine_version       = "5.0.5"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnet_group.name
  security_group_ids   = [aws_security_group.redis_sg.id]
}
