output "vpc_id" {
  description = "ID de la VPC creada"
  value       = aws_vpc.main.id
}

output "efs_id" {
  description = "ID del sistema de ficheros EFS"
  value       = aws_efs_file_system.efs.id
}

output "efs_dns_name" {
  description = "Nombre DNS del sistema de ficheros EFS"
  value       = aws_efs_file_system.efs.dns_name
}

output "efs_access_point_id" {
  description = "ID del punto de acceso para la Instancia2"
  value       = aws_efs_access_point.instancia2.id
}

output "instancia1_id" {
  description = "ID de la Instancia1 (us-east-1a)"
  value       = aws_instance.instancia1.id
}

output "instancia1_public_ip" {
  description = "IP pública de la Instancia1"
  value       = aws_instance.instancia1.public_ip
}

output "instancia2_id" {
  description = "ID de la Instancia2 (us-east-1b)"
  value       = aws_instance.instancia2.id
}

output "instancia2_public_ip" {
  description = "IP pública de la Instancia2"
  value       = aws_instance.instancia2.public_ip
}

output "ssm_connect_instancia1" {
  description = "Comando de AWS CLI para conectar a la Instancia1 vía SSM"
  value       = "aws ssm start-session --target ${aws_instance.instancia1.id} --region ${var.aws_region}"
}

output "ssm_connect_instancia2" {
  description = "Comando de AWS CLI para conectar a la Instancia2 vía SSM"
  value       = "aws ssm start-session --target ${aws_instance.instancia2.id} --region ${var.aws_region}"
}
