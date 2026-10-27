# Práctica 1: Volúmenes EBS

- **Módulo:** Administración de Bases de Datos y Almacenamiento en la Nube (ABDAN)
- **Unidad de Trabajo:** UT2. Servicios de almacenamiento en bloque y sistemas de ficheros en red

---

## Fase 1: Despliegue inicial en la misma AZ (`us-east-1a`)

> [!WARNING]
> **Requisito crítico: La misma Zona de Disponibilidad**
> Un volumen EBS reside físicamente en una única Zona de Disponibilidad (AZ). Para estas primeras fases, ambas instancias EC2 y el volumen EBS deben crearse exactamente en la misma AZ (por ejemplo, `us-east-1a`).

1. Accede a la consola de EC2 y lanza dos instancias (**Amazon Linux 2023**, tipo `t3.micro`):

    - **Nombre Instancia 1:** `Nodo-Origen-A`
    - **Nombre Instancia 2:** `Nodo-Destino-A`
    - **Configuración de red (Network settings):** Haz clic en **Edit** y selecciona explícitamente la misma subred para ambas instancias (ej. la subred perteneciente a `us-east-1a`).
    - Asegúrate de permitir tráfico SSH en el **Grupo de Seguridad** y selecciona tu par de claves.

2. En el menú lateral izquierdo de EC2, ve a **Elastic Block Store > Volumes** y haz clic en **Create volume**:

    - **Volume type:** `gp3`
    - **Size:** `10 GiB`
    - **Availability Zone:** Selecciona exactamente la misma AZ donde lanzaste las instancias (`us-east-1a`).
    - Añade una etiqueta (Tag) con clave `Name` y valor `EBS-Datos-Compartidos`.

---

## Fase 2: Asociación, formateo y persistencia en `Nodo-Origen-A`

1. Conéctate por SSH a la instancia `Nodo-Origen-A` y lista los dispositivos de bloque actuales:

    ```bash
    lsblk
    ```

    Observa que solo aparece el disco raíz (`nvme0n1` con sus particiones).

2. Regresa a la consola web de AWS, entra en **Volumes**, selecciona `EBS-Datos-Compartidos` y ve a **Actions > Attach volume**:

    - **Instance:** Selecciona `Nodo-Origen-A`.
    - **Device name:** Elige `/dev/sdf` y pulsa **Attach volume**.

3. Sin necesidad de reiniciar la máquina, vuelve a tu terminal SSH de `Nodo-Origen-A` y ejecuta de nuevo:

    ```bash
    lsblk
    ```

    > [!NOTE]
    > **¿Por qué se llama `/dev/nvme1n1` y no `/dev/sdf`?**
    > Las instancias modernas de AWS utilizan el hipervisor **Nitro**, que expone los discos EBS a través de controladores NVMe de alto rendimiento. Aunque en la consola web asignes `/dev/sdf`, el kernel de Linux lo detectará como `/dev/nvme1n1` (creando internamente un enlace simbólico `/dev/sdf -> nvme1n1` mediante reglas `udev`).

4. Comprueba que el volumen es un disco virgen en crudo (sin sistema de archivos):

    ```bash
    sudo file -s /dev/nvme1n1
    ```

    Si la salida devuelve únicamente `/dev/nvme1n1: data`, el disco no tiene formato.

5. Formatea el volumen con el sistema de archivos `ext4`:

    ```bash
    sudo mkfs -t ext4 /dev/nvme1n1
    ```

6. Crea el punto de montaje y obtén el identificador único (UUID) del sistema de archivos recién creado:

    ```bash
    sudo mkdir -p /mnt/datos
    sudo blkid /dev/nvme1n1
    ```

    Copia el valor de `UUID="..."` (sin las comillas).

7. Abre el archivo `/etc/fstab` con permisos de superusuario (`sudo nano /etc/fstab`) y añade al final la siguiente línea sustituyendo tu UUID:

    ```
    UUID=TU-UUID-AQUI  /mnt/datos  ext4  defaults,nofail  0  2
    ```

    > [!TIP]
    > **Por qué nunca debes usar `/dev/nvme1n1` en el fstab**
    > En instancias Nitro con varios discos, el orden en que el kernel numera los dispositivos `nvmeXn1` puede cambiar entre reinicios. Usar el UUID garantiza que siempre se monte el disco correcto. Además, la opción `nofail` permite que el servidor arranque con normalidad aunque el disco no esté presente, evitando perder el acceso por SSH.

8. Monta todos los sistemas de archivos declarados en `/etc/fstab` y verifica el montaje:

    ```bash
    sudo mount -a
    df -h /mnt/datos
    ```

9. **Asignación de propietario sobre el volumen montado:** Por defecto, al formatear con `mkfs.ext4`, el directorio raíz del nuevo sistema de archivos pertenece a `root:root`. Con el volumen ya montado, asigna la propiedad al usuario `ec2-user` para poder trabajar sin `sudo`:

    ```bash
    ls -ld /mnt/datos
    sudo chown -R ec2-user:ec2-user /mnt/datos
    ls -ld /mnt/datos
    ```

    > [!WARNING]
    > **¡Cambia el propietario siempre DESPUÉS de montar!**
    > Si ejecutas `chown` sobre `/mnt/datos` antes de hacer el `mount`, solo estarás cambiando los permisos de la carpeta vacía en el disco principal. Al hacerlo con el volumen ya montado, el cambio de propietario (UID 1000) se graba directamente en el inodo raíz del volumen EBS y viajará con él a cualquier otra máquina.

10. Crea un archivo de prueba directamente con tu usuario sin privilegios (`ec2-user`):

    ```bash
    echo "Línea 1: Escrita por ec2-user en Nodo-Origen-A" > /mnt/datos/testigo.txt
    cat /mnt/datos/testigo.txt
    ```

11. **Prueba de fuego de persistencia:** Reinicia la máquina (`sudo reboot`), vuelve a entrar por SSH tras un minuto y ejecuta `df -h` para comprobar que `/mnt/datos` se ha montado automáticamente en el arranque.

---

## Fase 3: Desmontaje seguro y extracción (Detach)

Para retirar un volumen EBS de una instancia en caliente sin corromper el sistema de archivos `ext4`, siempre se debe liberar primero desde el sistema operativo antes de desconectarlo en la consola de AWS.

1. En la terminal SSH de `Nodo-Origen-A`, asegúrate de no encontrarte dentro del directorio `/mnt/datos` y desmonta la unidad:

    ```bash
    cd ~
    sudo umount /mnt/datos
    ```

2. Edita el archivo `/etc/fstab` de `Nodo-Origen-A` (`sudo nano /etc/fstab`) y borra o comenta con `#` la línea del volumen EBS. De este modo dejamos el sistema operativo limpio porque el disco ya no va a pertenecer a esta máquina.

3. Ve a la consola de AWS (**EC2 > Volumes**), selecciona `EBS-Datos-Compartidos` y haz clic en **Actions > Detach volume**. Espera unos segundos hasta que el estado del volumen pase de `In-use` a `Available`.

---

## Fase 4: Trasplante en la misma AZ (`Nodo-Destino-A`)

1. En la consola de AWS (**EC2 > Volumes**), selecciona `EBS-Datos-Compartidos` (ahora en estado `Available`) y pulsa **Actions > Attach volume**:

    - **Instance:** Selecciona `Nodo-Destino-A`.
    - **Device name:** `/dev/sdf`.

2. Conéctate por SSH a `Nodo-Destino-A` y verifica que el kernel ha detectado el disco:

    ```bash
    lsblk -f
    ```

    Observa cómo en la columna `FSTYPE` ya aparece `ext4` y conserva exactamente el mismo UUID que tenía en la primera máquina.

    > [!CAUTION]
    > **¡No ejecutes `mkfs` en `Nodo-Destino-A`!**
    > El disco ya contiene una tabla de inodos, un sistema de archivos `ext4` y tus datos. Si vuelves a ejecutar `mkfs -t ext4`, formatearás el volumen de nuevo y destruirás toda la información creada en `Nodo-Origen-A`.

3. Crea el directorio de montaje en `Nodo-Destino-A`:

    ```bash
    sudo mkdir -p /mnt/datos_recuperados
    ```

4. Añade la línea correspondiente al final de `/etc/fstab` en `Nodo-Destino-A` (usando el mismo UUID que puedes consultar con `sudo blkid /dev/nvme1n1`):

    ```
    UUID=TU-UUID-AQUI  /mnt/datos_recuperados  ext4  defaults,nofail  0  2
    ```

5. Ejecuta el montaje a través del fstab, comprueba que el propietario (`ec2-user`) y el archivo se han conservado, y añade una segunda línea al archivo:

    ```bash
    sudo mount -a
    ls -ld /mnt/datos_recuperados
    echo "Línea 2: Añadida desde Nodo-Destino-A" >> /mnt/datos_recuperados/testigo.txt
    cat /mnt/datos_recuperados/testigo.txt
    ```

---

## Fase 5: Migración a otra Zona de Disponibilidad mediante Snapshot (`Nodo-Remoto-B`)

¿Qué ocurre si necesitamos llevarnos estos datos a un servidor que está en otra Zona de Disponibilidad (otro centro de datos físico)? Como un volumen EBS **no puede cruzar de una AZ a otra directamente**, utilizaremos un **Snapshot (instantánea)** como puente.

1. Lanza una tercera instancia EC2 (**Amazon Linux 2023**, `t3.micro`):

    - **Nombre Instancia 3:** `Nodo-Remoto-B`
    - **Configuración de red (Network settings):** Haz clic en **Edit** y selecciona explícitamente una subred en una Zona de Disponibilidad **DISTINTA** a las anteriores (por ejemplo, `us-east-1b`).

2. **Comprobación de la limitación física:**

    Si intentas asociar el volumen original `EBS-Datos-Compartidos` (ubicado en `us-east-1a`) a `Nodo-Remoto-B` (ubicado en `us-east-1b`), verás que `Nodo-Remoto-B` **ni siquiera aparece** en el desplegable de instancias disponibles.

3. **Creación del Snapshot (Instantánea):**

    - Para garantizar que todos los datos en memoria se han volcado a disco antes de la foto, ve a la terminal SSH de `Nodo-Destino-A` y ejecuta `sync` (o desmonta temporalmente el volumen con `sudo umount /mnt/datos_recuperados`).
    - En la consola de AWS, ve a **Elastic Block Store > Volumes**, selecciona `EBS-Datos-Compartidos` y haz clic en **Actions > Create snapshot**.
    - **Description:** `Snapshot-Migracion-AZ` y pulsa **Create snapshot**.

    > [!NOTE]
    > **Por qué el Snapshot sí puede cambiar de AZ**
    > Cuando creas un Snapshot de EBS, AWS guarda una copia de los bloques internamente en **Amazon S3**, que es un almacenamiento regional replicado en múltiples zonas. Desde ese Snapshot en S3 puedes engendrar nuevos volúmenes EBS en **cualquier Zona de Disponibilidad de la región**.

4. **Creación del nuevo volumen en la segunda AZ (`us-east-1b`):**

    - En el menú izquierdo, entra en **Elastic Block Store > Snapshots** y espera un par de minutos hasta que `Snapshot-Migracion-AZ` pase de `Pending` a `Completed`.
    - Selecciónalo y haz clic en **Actions > Create volume from snapshot**.
    - **Availability Zone:** ¡Paso clave! Despliega la lista y selecciona `us-east-1b` (la misma zona donde vive `Nodo-Remoto-B`).
    - Añade una etiqueta (Tag) con clave `Name` y valor `EBS-Clon-ZonaB`, y pulsa **Create volume**.

5. **Asociación y montaje en `Nodo-Remoto-B`:**

    - Ve a **Volumes**, selecciona el nuevo volumen `EBS-Clon-ZonaB` y haz clic en **Actions > Attach volume**.
    - Selecciona `Nodo-Remoto-B` y el dispositivo `/dev/sdf`.
    - Entra por SSH a `Nodo-Remoto-B` y ejecuta:

        ```bash
        lsblk -f
        ```

    Observa que el nuevo volumen creado desde el Snapshot es un **clon exacto a nivel de bloques**: ya viene formateado en `ext4` y tiene exactamente el mismo UUID que el disco original.

6. Crea el punto de montaje en `Nodo-Remoto-B`, regístralo en `/etc/fstab` con `nofail`, móntalo y comprueba que están las dos líneas de texto escritas por las máquinas de la otra Zona de Disponibilidad:

    ```bash
    sudo mkdir -p /mnt/datos_clonados
    # Añade la línea en /etc/fstab con sudo nano /etc/fstab:
    # UUID=TU-UUID-AQUI  /mnt/datos_clonados  ext4  defaults,nofail  0  2
    sudo mount -a
    cat /mnt/datos_clonados/testigo.txt
    ```

---

## Fase 6: Limpieza del laboratorio (Control de costes)

En esta práctica hemos generado recursos en tres apartados distintos que generan coste si se dejan olvidados:

1. **Instancias:** Ve a **Instances**, selecciona las 3 máquinas (`Nodo-Origen-A`, `Nodo-Destino-A` y `Nodo-Remoto-B`) y cámbialas a **Terminate** (Delete).

2. **Volúmenes EBS:** Cuando las instancias hayan terminado, ve a **Volumes**. Verás que los 3 discos de arranque han desaparecido solos, pero tus dos volúmenes de datos (`EBS-Datos-Compartidos` en la zona A y `EBS-Clon-ZonaB` en la zona B) siguen en estado `Available`. Selecciónalos y pulsa **Actions > Delete volume**.

3. **Snapshots:** Ve a **Snapshots**, selecciona `Snapshot-Migracion-AZ` y elimínalo (**Actions > Delete snapshot**), ya que las instantáneas almacenadas en S3 también se facturan por cada GB ocupado al mes.

---

## Entregables


1. **Captura 1 — Formateo y UUID en `Nodo-Origen-A`:** Salida del terminal tras ejecutar `sudo mkfs -t ext4 /dev/nvme1n1` seguido de `sudo blkid /dev/nvme1n1`. Debe verse el sistema de archivos creado y el UUID asignado.

2. **Captura 2 — Persistencia tras reboot en `Nodo-Origen-A`:** Salida de `df -h /mnt/datos` y `cat /mnt/datos/testigo.txt` después de haber reiniciado la máquina con `sudo reboot`. Demuestra que el montaje vía `/etc/fstab` funciona y que los datos sobreviven al reinicio.

3. **Captura 3 — Trasplante intra-AZ en `Nodo-Destino-A`:** Salida de `lsblk -f` (mostrando que el volumen llega con `ext4` y el mismo UUID) y de `cat /mnt/datos_recuperados/testigo.txt` tras añadir la segunda línea. Deben verse las **dos líneas** del archivo `testigo.txt`.

4. **Captura 4 — Limitación física entre AZs:** Captura de la consola web de AWS en la pantalla de **Attach volume** de `EBS-Datos-Compartidos` donde se evidencie que `Nodo-Remoto-B` **no aparece** en el desplegable de instancias (por estar en una AZ distinta).

5. **Captura 5 — Verificación final en `Nodo-Remoto-B`:** Salida de `lsblk -f` y `cat /mnt/datos_clonados/testigo.txt` en `Nodo-Remoto-B`. Debe confirmarse que el volumen clonado desde el Snapshot conserva el formato `ext4`, el mismo UUID, y las dos líneas de texto escritas desde las máquinas de la otra AZ.


