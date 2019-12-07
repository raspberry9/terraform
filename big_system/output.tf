output "lb_address" {
  # value = aws_elb.web.dns_name
  value = aws_lb.nlb.dns_name
}

output "server_ssh" {
  value = {
    for ins in aws_instance.server :
    ins.id => "ssh -i ${var.private_key_path} ${var.ec2_user}@${ins.public_ip}"
  }
}

output "redis_public_ip" {
  value = aws_elasticache_cluster.admin_redis.cache_nodes.0.address
  # value = aws_elasticache_cluster.redis.cache_nodes
  # for node in aws_elasticache_cluster.redis.cache_nodes :
  #   node => "${node.id}: ${node.address}:${node.port}"
}

# Output
output "mydb_dsn" {
  value = "${aws_db_instance.db.engine}://${aws_db_instance.db.username}:${aws_db_instance.db.password}@${aws_db_instance.db.endpoint}/${aws_db_instance.db.name}"
}
