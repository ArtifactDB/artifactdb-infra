resource "local_sensitive_file" "bastion_private_key" {
  content         = var.private_key
  filename        = "${path.module}/bastion_key.pem"
  file_permission = "0600"
}

resource "aws_instance" "bastion" {
  ami           = data.aws_ami.latest_amazon_linux.id
  instance_type = "t2.small"

  key_name = var.ssh_key_name

  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  subnet_id              = var.bastion_subnet_id

  tags = {
    Name = "bastion-host-${var.cluster_name}"
  }
  lifecycle {ignore_changes = [tags]}
}

resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg-${var.cluster_name}"
  description = "Security group for the bastion host"
  vpc_id      = var.vpc_id
  lifecycle {ignore_changes = [tags]}

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    #cidr_blocks = ["77.253.45.156/32"]
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["717063266043"]

  filter {
    name   = "name"
    values = ["AMI-RCP-CENTRALIZED-PB-UBUNTU-20.04-*"]
  }
}
