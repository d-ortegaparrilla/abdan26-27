# Práctica 6: Copias de seguridad centralizadas con AWS Backup

- **Módulo:** Administración de Bases de Datos y Almacenamiento en la Nube (ABDAN)
- **Unidad de Trabajo:** UT2. Servicios de almacenamiento en bloque y sistemas de ficheros en red

---

## Objetivo

Configurar una estrategia centralizada de copias de seguridad con AWS Backup y aplicarla a los recursos de almacenamiento creados en la práctica anterior.

Al finalizar la práctica deberás haber protegido un volumen EBS y un sistema de ficheros EFS, comprobado los puntos de recuperación y restaurado el contenido de EFS.

## Recursos utilizados

- Una instancia EC2 Amazon Linux creada mediante Terraform.
- Un volumen EBS adicional de 8 GiB.
- Un sistema de ficheros EFS montado en la instancia.
- AWS Backup.
- El rol IAM `LabRole`.

No es necesario crear una nueva plantilla Terraform: reutilizarás y adaptarás el proyecto de la [Práctica 2.5](practica-5-terraform-ebs-efs.md).

---

## Documentación

Consulta la documentación oficial cuando necesites comprobar el funcionamiento o los parámetros de una opción:

- [AWS Backup](https://docs.aws.amazon.com/aws-backup/latest/devguide/whatisbackup.html)
- [Copias de seguridad de Amazon EBS con AWS Backup](https://docs.aws.amazon.com/aws-backup/latest/devguide/ebs-backups.html)
- [Copias de seguridad de Amazon EFS con AWS Backup](https://docs.aws.amazon.com/aws-backup/latest/devguide/efs-backups.html)

---

## Fase 1: Preparación de la infraestructura

1. Copia el proyecto de Terraform de la Práctica 2.5 a una nueva carpeta:

    ```bash
    cp -r terraform-ebs-efs terraform-backup
    cd terraform-backup
    ```

2. En esta práctica solamente necesitas:
   - La instancia `Ordenador1`.
   - El volumen EBS adicional de 8 GiB.
   - El sistema de ficheros EFS `EFS_Terraform`.

3. Elimina o comenta la configuración y los outputs correspondientes a `Ordenador2`. No elimines el volumen EBS, el EFS ni el grupo de seguridad necesario para NFS.

4. Comprueba que dispones de la clave privada usada en la práctica anterior. Desplegarás el entorno con:

    ```bash
    terraform init
    terraform apply -auto-approve
    ```

5. Anota los siguientes identificadores:
   - Dirección IP pública de `Ordenador1`.
   - ID del volumen EBS `VolumenEBSTerraform`.
   - ID del sistema de ficheros `EFS_Terraform`.

### Datos de prueba

Conéctate a `Ordenador1` por SSH y crea un archivo de prueba en EBS y otro en EFS:

```bash
ssh -i clave ec2-user@<IP_PUBLICA>

sudo bash -c "echo 'Backup Test EBS - $(date)' > /mnt/ebs/test_ebs.txt"
sudo bash -c "echo 'Backup Test EFS - $(date)' > /mnt/efs/test_efs.txt"

cat /mnt/ebs/test_ebs.txt
cat /mnt/efs/test_efs.txt
```

Comprueba con `df -hT /mnt/ebs /mnt/efs` que ambos sistemas están montados.

---

## Fase 2: Creación del Backup Vault

En AWS Backup crea un Backup Vault con estos datos:

| Campo | Valor |
| :--- | :--- |
| Nombre | `vault-abdan` |
| Clave de cifrado | Predeterminada de AWS Backup: `aws/backup` |

Anota el nombre del vault para utilizarlo en las fases siguientes.

---

## Fase 3: Creación del plan de backup

1. Crea un nuevo Backup Plan con el nombre `plan-backup-ebs-efs`.
2. Selecciona **Build a new plan** y crea una regla con el nombre `regla-diaria-recursos`.
3. Configura la regla:

| Campo | Valor |
| :--- | :--- |
| Backup vault | `vault-abdan` |
| Frecuencia | Diaria |
| Hora de comienzo | Próxima a la hora actual |
| Inicio de la ejecución | Dentro de 1 hora |
| Finalización | Dentro de 4 horas |
| Retención | 7 días |

Deja el resto de opciones con sus valores predeterminados y crea el plan.

---

## Fase 4: Asignación de recursos

Desde el plan recién creado, asigna los recursos protegidos:

1. Crea una asignación llamada `asignacion-ebs-efs`.
2. Selecciona el rol existente `LabRole`.
3. Incluye los recursos específicos:
   - EBS: volumen `VolumenEBSTerraform`.
   - EFS: sistema de ficheros `EFS_Terraform`.
4. Guarda la asignación.

En AWS Academy no selecciones la opción que crea automáticamente un nuevo rol IAM.

---

## Fase 5: Ejecución y monitorización

1. Accede a **Jobs > Backup jobs**.
2. Espera a que comiencen los dos trabajos o, si es necesario para completar la práctica dentro de la sesión, ejecuta una copia bajo demanda en **Protected resources**.
3. Monitoriza los trabajos hasta que ambos estén en estado **Completed**.
4. Abre `vault-abdan` y comprueba que contiene dos puntos de recuperación:
   - Uno para el volumen EBS.
   - Uno para el sistema EFS.

!!! tip "Ejecución bajo demanda"
    Si la ventana diaria no comienza dentro del tiempo disponible, puedes lanzar una copia bajo demanda para EBS y otra para EFS, utilizando el mismo vault `vault-abdan`, una retención de 7 días y el rol `LabRole`.

---

## Fase 6: Restauración del sistema EFS

1. En `vault-abdan`, selecciona el punto de recuperación de EFS.
2. Pulsa **Restore**.
3. Configura las opciones de restauración:
   - Restaurar a un nuevo sistema de ficheros.
   - Cifrado: clave predeterminada `aws/elasticfilesystem`.
   - Rol IAM: `LabRole`.
4. Inicia la restauración.
5. En **Jobs > Restore jobs**, espera hasta que el trabajo esté en estado **Completed**.
6. Comprueba en el servicio Amazon EFS que se ha creado un segundo sistema de ficheros.

AWS Backup crea el EFS restaurado, pero no crea automáticamente todos sus destinos de montaje.

---

## Fase 7: Montaje y verificación de los datos

1. En la consola de Amazon EFS, abre el sistema restaurado.
2. En la pestaña **Network**, crea o administra sus destinos de montaje.
3. Utiliza la VPC `TerraformVPC` y las subredes en las que tenga acceso `Ordenador1`.
4. Asigna a los destinos el grupo de seguridad `EFS_SG`.
5. Espera a que los destinos estén en estado **Available**.
6. Anota el ID o el nombre DNS del nuevo EFS.

Desde la terminal de `Ordenador1`, monta el sistema restaurado:

```bash
sudo mkdir -p /mnt/efs-restaurado
sudo mount -t efs -o tls <ID_NUEVO_EFS>:/ /mnt/efs-restaurado
df -hT /mnt/efs /mnt/efs-restaurado
```

Localiza el archivo restaurado y comprueba que coincide con el archivo original:

```bash
sudo find /mnt/efs-restaurado -name test_efs.txt
cat /mnt/efs-restaurado/aws-backup-restore_*/test_efs.txt
```

El archivo puede aparecer dentro de una carpeta creada por AWS Backup. Si el comando con el carácter comodín no encuentra el archivo, utiliza el resultado de `find` para obtener su ruta exacta.

---

## Fase 8: Limpieza

Elimina todos los recursos creados para no consumir créditos:

1. Desmonta el EFS restaurado y crea una copia de seguridad de cualquier dato no entregable si fuera necesario:

    ```bash
    sudo umount /mnt/efs-restaurado
    exit
    ```

2. Elimina el EFS restaurado desde Amazon EFS.
3. En AWS Backup, elimina todos los recovery points del vault `vault-abdan`.
4. Elimina primero las asignaciones de recursos del plan y después el plan `plan-backup-ebs-efs`.
5. Elimina el vault `vault-abdan`.
6. Desde la carpeta `terraform-backup`, destruye la infraestructura:

    ```bash
    terraform destroy -auto-approve
    ```

---

## Entregables

Entrega un documento o PDF con las siguientes capturas:

1. Plan `plan-backup-ebs-efs` y su regla diaria.
2. Asignación de recursos con el volumen EBS y el sistema EFS bajo el rol `LabRole`.
3. Pestaña **Backup jobs** con los trabajos EBS y EFS en estado **Completed**.
4. Vault `vault-abdan` con los puntos de recuperación EBS y EFS en estado **Completed**.
5. Pestaña **Restore jobs** con el trabajo de restauración de EFS en estado **Completed**.
6. Terminal de `Ordenador1` mostrando:
   - `/mnt/efs` y `/mnt/efs-restaurado` montados.
   - El contenido restaurado de `test_efs.txt`.
7. Terminal local mostrando que `terraform destroy` ha finalizado correctamente.
