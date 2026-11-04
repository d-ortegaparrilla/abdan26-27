# Grupo de seguridad para las instancias EC2 (clientes NFS)
resource "aws_security_group" "ec2" {
  name        = "ec2-sg"
  description = "Grupo de seguridad para los clientes NFS. Se administran mediante AWS SSM por lo que no necesitan reglas de entrada"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "Permitir todo el trafico saliente"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-ec2"
  }
}

# Grupo de seguridad para el sistema de ficheros EFS
resource "aws_security_group" "efs" {
  name        = "efs-sg"
  description = "Grupo de seguridad para el sistema de ficheros EFS"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Permitir trafico NFS (puerto 2049) exclusivamente desde las instancias EC2"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  egress {
    description = "Permitir todo el trafico saliente"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-efs"
  }
}
