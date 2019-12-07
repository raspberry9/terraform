# Template: /etc/systemd/system/server.service
# data "template_file" "systemd_tpl" {
#   template = file("server.service.tpl")
#   vars = {
#     ADMIN_REDIS_URL = "redis://:@${aws_elasticache_cluster.admin_redis.cache_nodes.0.address}:${aws_elasticache_cluster.admin_redis.cache_nodes.0.port}/0"
#   }
# }

data "aws_subnet_ids" "all_subnets" {
  vpc_id = aws_vpc.default.id
}

# instance
resource "aws_instance" "server" {
  count                       = length(data.aws_subnet_ids.all_subnets[*])
  tags                        = { "Name" = "${var.name}-${count.index + 1}-server" }
  ami                         = data.aws_ami.ubuntu.id # data.aws_ami.centos.id
  instance_type               = "t2.nano"
  associate_public_ip_address = true
  key_name                    = aws_key_pair.key_pair.key_name
  vpc_security_group_ids      = [aws_security_group.server_sg.id, aws_security_group.lb_sg.id]
  subnet_id                   = element(data.aws_subnet_ids.all_subnets.ids[*], count.index)

  connection {
    type        = "ssh"
    user        = var.ec2_user
    host        = self.public_ip
    private_key = file(var.private_key_path)
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
    ]
  }

  # # build server binary
  # provisioner "local-exec" {
  #   command = "cd ../../../server/ && GOOS=linux GOARCH=amd64 go build ."
  # }

  # # add server binary
  # provisioner "file" {
  #   source      = "../server/server"
  #   destination = "/tmp/server"
  # }

  # install server binary & systemd
  provisioner "remote-exec" {
    inline = [
      # "sudo chmod +x /tmp/server",
      # "sudo mv /tmp/server /usr/local/bin/server",
      # "cat > /tmp/server.service <<EOL\n${data.template_file.systemd_tpl.rendered}\nEOL",
      # "sudo mv /tmp/server.service /etc/systemd/system/server.service",
      # "sudo systemctl daemon-reload",
    ]
  }

  # start server
  provisioner "remote-exec" {
    inline = [
      # "sudo systemctl start server",
    ]
  }
}
