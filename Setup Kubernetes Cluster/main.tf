provider "aws" {
  region = "*****"
}

data "aws_ami" "*****" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}


resource "aws_instance" "master" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "*****"
  key_name      = aws_key_pair.k8skey.key_name
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

  tags = {
    Name = "k8s-master"
  }
}

resource "aws_instance" "workers" {
  count         = 2
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.small"
  key_name      = aws_key_pair.k8skey.key_name
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  tags = {
    Name = "k8s-worker-${count.index}"
  }
}

# -------------------------
# Generate Private Key
# -------------------------

resource "tls_private_key" "k8s_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# -------------------------
# Create AWS Key Pair
# -------------------------

resource "aws_key_pair" "k8skey" {
  key_name   = "*****"
  public_key = tls_private_key.k8s_key.public_key_openssh
}

# -------------------------
# Save Private Key Locally
# -------------------------

resource "local_file" "private_key" {
  content  = tls_private_key.k8s_key.private_key_pem
  filename = "${path.module}/*****.pem"
}

# -------------------------
# Security Group
# -------------------------

resource "aws_security_group" "k8s_sg" {
  name        = "k8s-sg"
  description = "Allow SSH and Kubernetes"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
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

output "master_ip" {
  value = aws_instance.master.public_ip
}
output "worker_ips" {
  value = aws_instance.workers[*].public_ip
}
