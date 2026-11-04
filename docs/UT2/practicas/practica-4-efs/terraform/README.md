# Despliegue con Terraform — Práctica 2.4: Amazon EFS

Este proyecto de **Terraform** automatiza de extremo a extremo toda la infraestructura requerida para la **Práctica 2.4 (Amazon EFS: Creación de un Sistema de Ficheros NFS)**, incluyendo la configuración automática de los montajes y persistencia en ambas instancias EC2.

---

## Recursos desplegados

1. **Red (VPC y Subredes):**
   - VPC `vpc-Practica-EFS` (`10.1.0.0/16`) con soporte DNS habilitado.
   - 2 Subredes públicas:
     - `Practica-EFS-publica-1` (`10.1.0.0/24`, `us-east-1a`)
     - `Practica-EFS-publica-2` (`10.1.2.0/24`, `us-east-1b`)
   - 2 Subredes privadas (para los destinos de montaje EFS):
     - `Practica-EFS-privada-1` (`10.1.1.0/24`, `us-east-1a`)
     - `Practica-EFS-privada-2` (`10.1.3.0/24`, `us-east-1b`)
   - Internet Gateway y tabla de rutas asociada a las subredes públicas.

2. **Seguridad (Security Groups):**
   - `sg-ec2`: Asignado a las dos instancias EC2 (sin reglas de entrada, gestionadas vía AWS SSM).
   - `sg-efs`: Asignado a los puntos de montaje EFS, permitiendo tráfico entrante por el **puerto 2049 (NFS)** únicamente desde `sg-ec2`.

3. **Amazon EFS:**
   - Sistema de ficheros elástico y cifrado `mi-efs`.
   - 2 Destinos de montaje (*Mount Targets*) en las subredes privadas.
   - 1 Punto de acceso (*Access Point*) restringido al directorio `/instancia2`.

4. **Instancias EC2 y Montaje Automático:**
   - **Instancia1** (`t4g.micro` en `us-east-1a`):
     - Instala `amazon-efs-utils` y `tree`.
     - Monta la raíz del EFS en `/mnt/efs`.
     - Registra la entrada persistente en `/etc/fstab`.
     - Crea la estructura de carpetas (`/mnt/efs/instancia2`) y los ficheros de prueba (`fichero1.txt`, `fichero2.txt`).
   - **Instancia2** (`t4g.micro` en `us-east-1b`):
     - Instala `amazon-efs-utils` y `tree`.
     - Monta el EFS mediante el **Punto de Acceso** (`fsap-...`), restringiendo la vista a `/instancia2`.
     - Registra la entrada persistente correspondiente en `/etc/fstab`.

---

## Requisitos previos

1. Tener instalado [Terraform](https://developer.hashicorp.com/terraform/downloads) (>= 1.5).
2. Tener configurada la **AWS CLI** con las credenciales de tu sandbox de **AWS Academy Learner Lab**:
   ```bash
   aws sts get-caller-identity
   ```

---

## Instrucciones de uso

### 1. Inicializar el proyecto
```bash
terraform init
```

### 2. Revisar el plan de ejecución
```bash
terraform plan
```

### 3. Aplicar y desplegar la infraestructura
```bash
terraform apply -auto-approve
```

> **Nota:** El despliegue tarda aproximadamente entre 2 y 3 minutos debido a la provisión de los puntos de montaje EFS.

### 4. Conectar a las instancias para verificar

Los comandos exactos para conectar por **AWS SSM** se mostrarán en la salida (`outputs`) de Terraform:

```bash
# Conectar a Instancia1
aws ssm start-session --target <instancia1_id> --region us-east-1

# Dentro de Instancia1, verificar la estructura completa:
sudo tree /mnt/efs
cat /etc/fstab
```

```bash
# Conectar a Instancia2
aws ssm start-session --target <instancia2_id> --region us-east-1

# Dentro de Instancia2, verificar que solo ve el subdirectorio instancia2:
sudo tree /mnt/efs
cat /etc/fstab
```

---

## Limpieza / Destrucción

Cuando termines el laboratorio, destruye todos los recursos para no consumir créditos de AWS Academy:

```bash
terraform destroy -auto-approve
```
