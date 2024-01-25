terraform {
    #Necesario para el terraform
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.7.0"
}

# Configura el proveedor AWS utilizando el perfil configurado en la AWS CLI
provider "aws" {
  region = "eu-south-2"
}

# Crea una VPC para alojar tus recursos
resource "aws_vpc" "mean_vpc" {
  cidr_block = "10.0.0.0/16" # Este es el rango de direcciones IP para tu VPC.

  tags = {
    Name = "mean_vpc"
  }
}

# Define las subredes dentro de la VPC
resource "aws_subnet" "mean_subnet" {
  vpc_id     = aws_vpc.mean_vpc.id # Asocia esta subred con la VPC que acabas de definir.
  cidr_block = "10.0.1.0/24" # Subconjunto del bloque CIDR de la VPC para esta subred.

  tags = {
    Name = "mean_subnet"
  }
}

# Crea un grupo de seguridad para tus instancias EC2
resource "aws_security_group" "mean_sg" {
  name        = "mean_security_group"
  description = "Security group for MEAN stack"
  vpc_id      = aws_vpc.mean_vpc.id

  # Regla de ingreso: permite el tráfico entrante HTTP y SSH
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["212.183.248.241/32"] # Lo reemplazo con mi IP pública para acceso SSH.
  }

  # Regla de egreso: permite todo el tráfico saliente
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Permite todas
  }

  tags = {
    Name = "mean_sg"
  }
}

# Instancia EC2 para Node.js
resource "aws_instance" "node_instance" {
  ami           = "ami-0a9e7160cebfd8c12" 
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.mean_subnet.id
  security_groups = [aws_security_group.mean_sg.name]

  tags = {
    Name = "NodeInstance"
  }
}

# Instancia EC2 para MongoDB
resource "aws_instance" "mongo_instance" {
  ami           = "ami-04724c78a5bbb23bb" 
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.mean_subnet.id
  security_groups = [aws_security_group.mean_sg.name]

  tags = {
    Name = "MongoInstance"
  }
}

# Salida: IPs públicas de las instancias
output "node_instance_ip" {
  value = aws_instance.node_instance.public_ip
  description = "IP pública de la instancia Node.js"
}

output "mongo_instance_ip" {
  value = aws_instance.mongo_instance.public_ip
  description = "IP pública de la instancia MongoDB"
}

output "mongodb_ip" {
  value = aws_instance.mongodb.public_ip
}