variable "aws_region" {
  description = "Región de AWS para desplegar los recursos"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefijo para los nombres de los recursos"
  type        = string
  default     = "Practica-EFS"
}

variable "vpc_cidr" {
  description = "Bloque CIDR de la VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "public_subnets" {
  description = "Configuración de las subredes públicas"
  type = map(object({
    cidr = string
    az   = string
  }))
  default = {
    publica1 = {
      cidr = "10.1.0.0/24"
      az   = "us-east-1a"
    }
    publica2 = {
      cidr = "10.1.2.0/24"
      az   = "us-east-1b"
    }
  }
}

variable "private_subnets" {
  description = "Configuración de las subredes privadas para los puntos de montaje EFS"
  type = map(object({
    cidr = string
    az   = string
  }))
  default = {
    privada1 = {
      cidr = "10.1.1.0/24"
      az   = "us-east-1a"
    }
    privada2 = {
      cidr = "10.1.3.0/24"
      az   = "us-east-1b"
    }
  }
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t4g.micro"
}

variable "ami_ssm_parameter" {
  description = "Parámetro SSM para resolver la AMI de Amazon Linux 2 (ARM64)"
  type        = string
  default     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-arm64-gp2"
}

variable "iam_instance_profile" {
  description = "Perfil de instancia IAM asignado a las instancias EC2 (LabInstanceProfile en AWS Academy)"
  type        = string
  default     = "LabInstanceProfile"
}
