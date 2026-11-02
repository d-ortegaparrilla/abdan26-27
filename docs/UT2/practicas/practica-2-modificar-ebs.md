# Práctica 2: Modificación de un Volumen EBS

- **Módulo:** Administración de Bases de Datos y Almacenamiento en la Nube (ABDAN)
- **Unidad de Trabajo:** UT2. Servicios de almacenamiento en bloque y sistemas de ficheros en red

---

## Fase 1: Creación de la instancia EC2

1. Accede a la consola de EC2 y lanza una nueva instancia con la siguiente configuración:

    | Parámetro | Valor |
    | :--- | :--- |
    | **AMI** | Amazon Linux (última versión disponible) |
    | **Tipo de instancia** | `t2.micro` |
    | **Par de claves** | `tu_clave` |
    | **Almacenamiento (volumen raíz)** | `8 GB` |
    | **Opciones avanzadas > Perfil de instancia IAM** | `LabInstanceProfile` |

    Deja el resto de las opciones con sus valores por defecto.

---

## Fase 2: Identificación del volumen raíz y la zona de disponibilidad

1. Utiliza el comando `describe-instances` para obtener la información de la instancia recién creada. En concreto, necesitas localizar dos datos clave: el **ID del volumen raíz** y la **Zona de Disponibilidad** donde se lanzó la instancia:

    Anota el `VolumeId` (por ejemplo, `vol-0abc1234567890def`) y la `AvailabilityZone` (por ejemplo, `us-east-1a`).

2.  Obtén información sobre el volumen asociado a la instancia con el comando `aws ec2 describe-volumes`. También, conéctate a la instancia (desde tu máquina por ssh), y utiliza los comandos sudo `lsblk` y `df -hT` para comprobar las particiones del volumen, nombre de estas y espacio total, ocupado y libre.

3. Conéctate a la instancia por SSH (desde CloudShell o desde tu máquina local) y comprueba las particiones del volumen, sus nombres y el espacio disponible.

---

## Fase 3: Copia de seguridad previa (Snapshot)
Antes de proceder a la modificación del volumen, es conveniente realizar una copia de seguridad por si se produjera cualquiera error
en el proceso

- a. Crea un snapshot del volumen de la instancia con el comando `aws ec2 create-snapshot`
- b. Espera hasta que el estado de la copia esté completo. Puedes monitorizar el estado del snapshot con el comando `aws ec2 describe-snapshots`


> [!WARNING]
> **No modifiques el volumen hasta que el snapshot esté completo**
> Si la modificación del volumen fallara y no dispusieras de una copia de seguridad completada, podrías perder el acceso al sistema operativo de la instancia. La instantánea es tu red de seguridad.

---

## Fase 4: Modificación del tamaño del volumen

Modifica el volumen para aumentar su tamaño de 8 GB a **10 GB**:

- a. Utiliza para ello el comando aws ec2 modify-volume 
- b. Una vez lanzado, monitoriza el estado de la modificación mediante  el comando `aws ec2 describe-volumes-modifications`. Inicialmente el estado será *modifying*. Continúa monitorizando hasta que el estado sea *completed*.


---

## Fase 5: Ampliación del sistema de archivos

Aunque el volumen EBS ya tiene 10 GB a nivel de infraestructura de AWS, el sistema operativo aún no es consciente del cambio. Es necesario ampliar primero la **partición** y después el **sistema de archivos**.

- a. Desde la instancia, ejecuta el comando df -hT. Podrás comprobar que el sistema de ficheros raíz montado en ‘/’ sigue teniendo 8 GB. Es necesario realizar modificaciones en la partición y en el sistema de ficheros.
- b. Averigua si el tipo de instancia está basada en Xen o en Nitro. En función de eso, cambian los nombres de los dispositivos y particiones. Utiliza el comando siguiente para averiguarlo:
`aws ec2 describe-instance-types --instance-type t2.micro --query "InstanceTypes[].Hypervisor"`
- c. Desde la instancia, amplía la partición utilizando el comando `sudo growpart /dev/xvda 1` (tipo de instancia Xen) o `sudo growpart /dev/nvme0n1 1` (tipo de instancia Nitro).
- d. Comprueba que la partición se ha ampliado a 10 GB con el comando `sudo lsblk`
- e. Amplía el sistema de archivos con el comando `sudo xfs_growfs -d` / (si es de tipo XFS) o el comando `sudo resize2fs /dev/xvda1` (si es de tipo Ext4)
- f. Comprueba con el comando `dh -hT` que el sistema de archivos tiene 10 GB.


---

## Fase 6: Limpieza

Si todo ha ido bien, ya puedes eliminar la copia de seguridad del volumen realizada anteriormente con el comando `aws ec2 delete snapshot`

---

## Entregables

1. **Captura 1 — Estado inicial del volumen:** Salida del terminal con los comandos `sudo lsblk` y `df -hT` ejecutados en la instancia, donde se aprecie que el volumen raíz tiene un tamaño de **8 GB**.

2. **Captura 2 — Snapshot completado:** Salida del comando `aws ec2 describe-snapshots` mostrando el estado `completed` y el progreso al `100%`.

3. **Captura 3 — Modificación del volumen:** Salida del comando `aws ec2 describe-volumes-modifications` mostrando que el estado es `completed` (o `optimizing`) y el tamaño objetivo es `10`.

4. **Captura 4 — Partición ampliada:** Salida del comando `sudo lsblk` tras ejecutar `growpart`, donde se aprecie que la partición ha crecido a **10 GB**.

5. **Captura 5 — Sistema de archivos ampliado:** Salida del comando `df -hT` final, donde el sistema de archivos montado en `/` muestre un tamaño total de aproximadamente **10 GB**.
