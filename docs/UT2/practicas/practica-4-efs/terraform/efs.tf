# Sistema de ficheros Amazon EFS
resource "aws_efs_file_system" "efs" {
  creation_token   = "${var.project_name}-token"
  performance_mode = "generalPurpose"
  throughput_mode  = "elastic"
  encrypted        = true

  tags = {
    Name = "mi-efs"
  }
}

# Mount Target en Subred Privada 1 (us-east-1a)
resource "aws_efs_mount_target" "target_1" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = aws_subnet.private_1.id
  security_groups = [aws_security_group.efs.id]
}

# Mount Target en Subred Privada 2 (us-east-1b)
resource "aws_efs_mount_target" "target_2" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = aws_subnet.private_2.id
  security_groups = [aws_security_group.efs.id]
}

# Punto de acceso para la Instancia2 (restringido al directorio /instancia2)
resource "aws_efs_access_point" "instancia2" {
  file_system_id = aws_efs_file_system.efs.id

  root_directory {
    path = "/instancia2"
    creation_info {
      owner_gid   = 0
      owner_uid   = 0
      permissions = "0777"
    }
  }

  tags = {
    Name = "Punto de acceso para Instancia2"
  }
}
