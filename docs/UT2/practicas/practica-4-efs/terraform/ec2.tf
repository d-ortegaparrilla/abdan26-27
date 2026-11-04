# Obtención de la AMI de Amazon Linux 2 (ARM64) desde AWS SSM
data "aws_ssm_parameter" "ami" {
  name = var.ami_ssm_parameter
}

# ==========================================
# Instancia 1 (Montaje raíz completo del EFS)
# ==========================================
resource "aws_instance" "instancia1" {
  ami                    = data.aws_ssm_parameter.ami.value
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = var.iam_instance_profile

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y amazon-efs-utils tree

              # Crear punto de montaje
              mkdir -p /mnt/efs

              # Esperar a que el destino de montaje responda por red/DNS
              fs_dns="${aws_efs_file_system.efs.dns_name}"
              fs_id="${aws_efs_file_system.efs.id}"

              # Montar el sistema de ficheros EFS en la raíz
              mount -t efs -o tls $fs_id:/ /mnt/efs

              # Configuración persistente en /etc/fstab
              echo "$fs_dns:/ /mnt/efs nfs4 nfsvers=4.1,rsize=1048576,hard,timeo=600,retrans=2,noresvport,_netdev 0 0" >> /etc/fstab

              # Crear estructura de carpetas y ficheros según el enunciado de la práctica
              mkdir -p /mnt/efs/instancia2
              echo "Fichero 1. Sólo accesible por la instancia1" > /mnt/efs/fichero1.txt
              echo "Fichero 2. Accesible por ambas instancias" > /mnt/efs/instancia2/fichero2.txt
              chmod -R 777 /mnt/efs/instancia2
              EOF

  tags = {
    Name = "Instancia1"
  }

  # Asegurar que los Mount Targets de EFS estén listos antes de levantar la máquina
  depends_on = [
    aws_efs_mount_target.target_1,
    aws_efs_mount_target.target_2
  ]
}

# =========================================================
# Instancia 2 (Montaje restringido mediante Access Point)
# =========================================================
resource "aws_instance" "instancia2" {
  ami                    = data.aws_ssm_parameter.ami.value
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_2.id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = var.iam_instance_profile

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y amazon-efs-utils tree

              # Crear punto de montaje
              mkdir -p /mnt/efs

              fs_dns="${aws_efs_file_system.efs.dns_name}"
              fs_id="${aws_efs_file_system.efs.id}"
              fsap_id="${aws_efs_access_point.instancia2.id}"

              # Montar utilizando el punto de acceso (restringido a /instancia2)
              mount -t efs -o tls,accesspoint=$fsap_id $fs_id:/ /mnt/efs

              # Configuración persistente en /etc/fstab
              echo "$fs_dns /mnt/efs efs _netdev,tls,accesspoint=$fsap_id 0 0" >> /etc/fstab
              EOF

  tags = {
    Name = "Instancia2"
  }

  # Asegurar que los Mount Targets y el Access Point de EFS estén creados antes
  depends_on = [
    aws_efs_mount_target.target_1,
    aws_efs_mount_target.target_2,
    aws_efs_access_point.instancia2
  ]
}
