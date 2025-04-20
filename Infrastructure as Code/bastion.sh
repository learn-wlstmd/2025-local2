#!/bin/bash
yum install -y yum-utils
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
yum install -y terraform

mkdir -p /home/ec2-user/korea

cat << EOF > /home/ec2-user/korea/provider.tf
provider "aws" {
  profile = "default"
  region  = "ap-northeast-2"
}
EOF

cat << EOF > /home/ec2-user/korea/main.tf
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "korea-vpc"
    Project = "KoreaSkills"
  }
}

# Public

## Internet Gateway
resource"aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "korea-igw"
    Project = "KoreaSkills"
  }
}

## Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "korea-public-rt"
    Project = "KoreaSkills"
  }
}
 
resource "aws_route" "public" {
  route_table_id = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.main.id
}

## Public Subnet
resource "aws_subnet" "public_a" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "korea-public-subnet-a"
    Project = "KoreaSkills"
  }
}

## Attach Public Subnet in Route Table
resource "aws_route_table_association" "public_a" {
  subnet_id = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}


# EC2

# EBS Encryption
resource "aws_ebs_encryption_by_default" "ebs" {
  enabled = true
}

## Keypair
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "aws_key_pair" "keypair" {
  key_name = "korea"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "local_file" "keypair" {
  content = tls_private_key.rsa.private_key_pem
  filename = "./korea.pem"
}

## Public EC2
resource "aws_instance" "korea_instance" {
  ami = "ami-0eb302fcc77c2f8bd"
  subnet_id = aws_subnet.public_a.id
  instance_type = "t3.micro"
  key_name = aws_key_pair.keypair.key_name
  vpc_security_group_ids = [aws_security_group.korea_instance.id]
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.korea_instance.name
  user_data = <<-EOF
  #!/bin/bash
  yum update -y
  sudo dnf install -y https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm
  EOF
  tags = {
    Name = "korea-instance"
    Project = "KoreaSkills"
  }
}

## Public Security Group
resource "aws_security_group" "korea_instance" {
  name = "korea-instance-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "22"
    to_port = "22"
  }

  egress {
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "0"
    to_port = "0"
  }
 
  tags = {
    Name = "korea-instance-sg"
    Project = "KoreaSkills"
  }
}

## IAM
resource "aws_iam_role" "korea_instance" {
  name = "korea-instance-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
}

resource "aws_iam_instance_profile" "korea_instance" {
  name = "korea-instance-profile"
  role = aws_iam_role.korea_instance.name
}

# OutPut

## VPC
output "aws_vpc" {
  value = aws_vpc.main.id
}

## Public Subnet
output "public_a" {
  value = aws_subnet.public_a.id
}

output "korea_instance" {
  value = aws_instance.korea_instance.id
}

output "korea_instance-sg" {
  value = aws_security_group.korea_instance.id
}
EOF

sudo chown -R ec2-user:ec2-user /home/ec2-user/korea
cd /home/ec2-user/korea
terraform init