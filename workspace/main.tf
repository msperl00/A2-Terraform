terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.5.0"
}

# Configura el proveedor AWS utilizando el perfil configurado en la AWS CLI
provider "aws" {
  region = "us-east-1"
}

# Crear VPC
resource "aws_vpc" "mean_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "mean_vpc"
  }
}

# Crear Subred
resource "aws_subnet" "mean_subnet" {
  vpc_id     = aws_vpc.mean_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "mean_subnet"
  }
}

# Crear Internet Gateway
resource "aws_internet_gateway" "mean_gateway" {
  vpc_id = aws_vpc.mean_vpc.id

  tags = {
    Name = "mean_gateway"
  }
}

# Crear Tabla de Ruteo
resource "aws_route_table" "mean_route_table" {
  vpc_id = aws_vpc.mean_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mean_gateway.id
  }

  tags = {
    Name = "mean_route_table"
  }
}


# Asociar la Tabla de Ruteo con la Subred
resource "aws_route_table_association" "mean_route_table_assoc" {
  subnet_id      = aws_subnet.mean_subnet.id
  route_table_id = aws_route_table.mean_route_table.id
}
resource "aws_security_group" "mean_sg" {
  name        = "mean_security_group"
  description = "Security group for MEAN stack"
  vpc_id      = aws_vpc.mean_vpc.id  
  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    #cidr_blocks = ["212.183.248.241/32"] # Mi conexión
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["212.183.248.241/32"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # Regla para MongoDB
  ingress {
    description      = "MongoDB"
    from_port        = 27017
    to_port          = 27017
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  # Reglas de salida para permitir todas las conexiones salientes
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mean_sg"
  }
}

# Cargar la clave pública SSH en AWS
resource "aws_key_pair" "keypair" {
  key_name   = "mi_clave_ssh"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "mi_clave_ssh" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "clave_new"
}

# Instancia EC2 para Node.js
# Asegúrate de actualizar las instancias EC2 para usar la subred y el grupo de seguridad VPC
resource "aws_instance" "node_instance" {
  ami                    = "ami-0c7217cdde317cfec"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.mean_subnet.id
  vpc_security_group_ids = [aws_security_group.mean_sg.id]
  private_ip             = "10.0.1.11"
  key_name               = "mi_clave_ssh"
  associate_public_ip_address = true

  tags = {
    Name = "NodeInstance"
  }
}
# Instancia EC2 para MongoDB
resource "aws_instance" "mongo_instance" {
  ami                    = "ami-0c7217cdde317cfec"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.mean_subnet.id
  vpc_security_group_ids = [aws_security_group.mean_sg.id]
  private_ip             = "10.0.1.10"
  key_name               = "mi_clave_ssh"
  associate_public_ip_address = true
  user_data = file("${path.module}/installmongodb.sh")

  tags = {
    Name = "MongoInstance"
  }
}

output "node_instance_ip" {
  value = aws_instance.node_instance.public_ip
}

output "mongo_instance_ip" {
  value = aws_instance.mongo_instance.public_ip
}
