# Práctica 1.3: Políticas de Acceso, Permisos IAM, Versionado y Ciclo de Vida en Amazon S3

- **Módulo:** Administración de Bases de Datos y Almacenamiento en la Nube (ABDAN)
- **Unidad de Trabajo:** UT1. Servicios de almacenamiento de objetos en la nube (Amazon S3)
- **Resultados de Aprendizaje asociados:**
    - **RA2.b:** Definición de clases de almacenamiento y transición según requisitos de latencia y coste.
    - **RA2.d:** Aplicación de mecanismos de seguridad y cifrado en almacenamiento de objetos.
    - **RA2.e:** Configuración de parámetros de visibilidad, acceso y políticas de seguridad (Bucket Policies e IAM).
    - **RA2.g:** Configuración del control de versiones, marcadores de eliminación y reglas de ciclo de vida.

---


## 1. Preparación de los Archivos de Prueba

Para realizar las pruebas de transferencia y versionado, utilizaremos dos archivos:

**Archivo de informe gráfico (`new-report.png`)**
Puedes utilizar cualquier captura o imagen de prueba local.

**Archivo de texto para versionado (`sample-file.txt`)**
Crea en tu equipo local un archivo de texto con el siguiente contenido inicial:

```text
This sample text file is used to illustrate the use of versioning in an Amazon S3 bucket.

Make it a great day!
```

---

## 2. Instrucciones


### Parte 1: Creación del Bucket y el Contraste: ACLs vs. Bucket Policies

#### Paso 1.1: Creación del bucket con ACLs habilitadas

1. Accede a la consola de **Amazon S3** en AWS Academy Learner Lab.
2. Pulsa en **Crear bucket (Create bucket)**:
    - **Tipo de depósito:** *General Purpose Bucket*.
    - **Nombre del bucket:** Debe ser un nombre globalmente único. Nómbralo:  
      `reportbucket-NOMBRE-APELLIDO` *(todo en minúsculas, números o guiones)*.
    - **Región de AWS:** Mantén la región de tu laboratorio (ej. `us-east-1` Norte de Virginia).
    - **Propiedad de objetos (Object Ownership):** Selecciona **ACL habilitadas (ACLs enabled)** y marca **Escritor de objetos (Object writer)**.
    - **Bloqueo de acceso público (Block Public Access):** Mantén activada la casilla **Bloquear todo el acceso público** (*Block all public access*).
    - **Cifrado predeterminado:** SSE-S3.
3. Haz clic en **Crear bucket**.

#### Paso 1.2: Carga del primer objeto y bloqueo de ACL por BPA

1. Entra al bucket recién creado y pulsa **Cargar (Upload)** -> **Agregar archivos (Add files)**.
2. Selecciona la imagen de prueba `new-report.png` y súbela.
3. Haz clic sobre el nombre del archivo `new-report.png` para abrir su panel de detalles.
4. Localiza el campo **URL de objeto (Object URL)** y ábrela en el navegador. Obtendrás el error esperado `AccessDenied` (privado por defecto).
5. Vuelve a la pestaña de `new-report.png` en la consola de AWS, despliega el menú **Acciones del objeto (Object actions)** y pulsa la última opción: **Hacer público mediante ACL (Make public using ACL)**.

!!! warning "Fallo en la asignación de ACL por Block Public Access"
    Observarás una advertencia informando de que el acceso público está bloqueado por la configuración de **Bloqueo de acceso público (BPA)** del bucket. Si pulsas en *Hacer público*, la consola devolverá un error:
    `Failed to edit public access`
    Esto demuestra que **Block Public Access actúa como un cortafuegos maestro** que ignora cualquier ACL permisiva.

#### Paso 1.3: Desactivar BPA y hacer público el objeto individual mediante ACL

1. Regresa a la página principal del bucket y haz clic en la pestaña **Permisos (Permissions)**.
2. En la sección **Bloqueo de acceso público (configuración del bucket)**, pulsa **Editar**.
3. **Desmarca** la casilla *Bloquear todo el acceso público*, pulsa **Guardar cambios** y confirma escribiendo `confirmar` (o `confirm`).
4. Vuelve a la pestaña **Objetos**, entra en `new-report.png` -> **Acciones del objeto** -> **Hacer público mediante ACL**.
5. Pulsa en **Hacer público**: ahora la operación se completará con éxito (*Successfully edited public access*).
6. Recarga la pestaña del navegador con la URL del objeto: la imagen `new-report.png` se mostrará públicamente.

#### Paso 1.4: La limitación de las ACLs (El problema de la gestión objeto a objeto)

1. Vuelve a la consola de S3 y sube al bucket el segundo archivo de prueba: `sample-file.txt`.
2. Una vez subido, haz clic sobre `sample-file.txt`, copia su **URL de objeto** y ábrela en una nueva pestaña del navegador.

!!! failure "¡Error 403 Forbidden otra vez! ¿Por qué no es visible sample-file.txt?"
    Aunque el bucket ya no bloquea el acceso público y se encuentra en el mismo depósito que la imagen, **las ACLs operan de forma aislada a nivel de objeto individual**. 
    
    Cada vez que se sube un nuevo archivo, nace privado por defecto. Para hacerlo público mediante ACL tendrías que repetir manualmente el procedimiento archivo por archivo. En una organización con miles o millones de objetos, esto es ingobernable, imposible de auditar y una fuente crítica de errores de seguridad.

3. En las siguientes partes conectaremos un servidor EC2 y utilizaremos una **Política de Bucket (Bucket Policy)** centralizada en JSON. Veremos cómo gobernar el acceso público de lectura y cómo aplicar restricciones de seguridad granulares (como denegar la subida de objetos a la máquina virtual y forzar conexiones cifradas HTTPS) sin depender de ACLs individuales.

---

### Parte 2: Lanzamiento de Instancia EC2 y Conectividad con S3

En esta parte desplegaremos un servidor virtual Linux en la nube y verificaremos cómo interactúa con nuestro bucket a través del perfil de instancia y rol IAM asignado (`LabRole`), comprobando los permisos que tiene por defecto en el entorno del laboratorio.

#### Paso 2.1: Lanzar una instancia EC2 con el rol de laboratorio (`LabRole`)

1. Desde el menú superior de la consola de AWS, dirígete al servicio **EC2**.
2. En el panel izquierdo selecciona **Instancias** y pulsa en **Lanzar instancias (Launch instances)**.
3. Configura los parámetros básicos de la instancia:
    - **Nombre:** `Servidor-Reportes`.
    - **Imagen del sistema operativo (AMI):** *Amazon Linux 2023 AMI* (Apta para la capa gratuita).
    - **Tipo de instancia:** `t3.micro`.
    - **Par de claves (Key pair):** Crea un par de claves o utiliza uno que ya tengas creado (nos conectaremos directamente mediante ssh).
    - **Grupo de seguridad (security group):** Crea un grupo de seguridad llamado SSH que abra el puerto 22 a todas las IPs. Para ello deberás pulsar el botón Edit de la sección.
    - **Configuración de red:** Deja la VPC y subred por defecto.
4. Despliega la sección **Detalles avanzados (Advanced details)** al final de la página:
    - En el campo **Perfil de instancia de IAM (IAM instance profile)**, selecciona **`LabInstance`**.

!!! important "Asignación obligatoria de `LabInstance`"
    Asignar el perfil de instancia `LabInstance` proporciona a la máquina virtual el rol `LabRole` el cual provee de credenciales temporales dentro del Learner Lab con acceso a los recursos creados por el propio usuario.

5. Pulsa **Lanzar instancia** y espera a que su estado pase a `En ejecución` (*Running*).

#### Paso 2.2: Conexión mediante SSH

1. Apunta la IP pública de la instancia EC2 creada.
2. Sitúate con el terminal en la misma carpeta donde tengas el archivo `.pem` descargado cuando creamos el key pair. Reduce los permisos del archivo con:
   ```bash
   chmod 400 archivo.pem
   ```
3. Ejecuta la conexión SSH hacia la instancia:
   ```bash
   ssh -i archivo.pem ec2-user@IPPúblicaInstanciaEC2
   ```
4. Se abrirá la sesión de terminal interactiva en tu máquina EC2.

#### Paso 2.3: Generación de datos de prueba en la máquina

En la consola de la máquina EC2, ejecuta los siguientes comandos para crear una carpeta de trabajo con un informe de prueba:

```bash
mkdir -p ~/reports
cd ~/reports
echo "Informe generado por el sistema el $(date)" > report-test1.txt
ls -la
```

#### Paso 2.4: Comprobación de conectividad y permisos predeterminados (`LabRole`)

1. Comprueba si la máquina puede listar los objetos de tu bucket ejecutando:

```bash
aws s3 ls s3://reportbucket-NOMBRE-APELLIDO/
```

*(Debe mostrarse el archivo `new-report.png` y `sample-file.txt` que subiste en la Parte 1).*

2. Sube el archivo de informe generado en el paso anterior hacia el bucket:

```bash
aws s3 cp report-test1.txt s3://reportbucket-NOMBRE-APELLIDO/
```

!!! success "Subida exitosa por permisos IAM del rol"
    La salida confirmará la subida correctamente:
    ```text
    upload: ./report-test1.txt to s3://reportbucket-NOMBRE-APELLIDO/report-test1.txt
    ```

3. Comprueba también que la máquina puede descargar objetos desde el bucket:

```bash
aws s3 cp s3://reportbucket-NOMBRE-APELLIDO/new-report.png copia-report.png
ls -lh copia-report.png
```

!!! info "Permisos predeterminados de `LabRole` en AWS Academy Learner Lab"
    Observa que el servidor EC2 puede listar el bucket, subir archivos y descargarlos **sin haber configurado credenciales ni claves locales** en `~/.aws/credentials`.
    
    Esto ocurre porque el perfil de instancia `LabInstance` asocia a la máquina virtual el rol IAM `LabRole`, el cual dispone por defecto de una política de identidad con permisos amplios para operar sobre todos los buckets de S3 de la cuenta del laboratorio.
    
    Sin embargo, bajo el principio de **Mínimo Privilegio**, en muchos escenarios necesitamos que un servidor solo actúe como lector o deseamos proteger un bucket contra modificaciones directas. En la Parte 3 comprobaremos cómo una **Política de Bucket (Bucket Policy)** con una directiva de denegación explícita (`Deny`) prevalece sobre los permisos del rol, permitiendo que la máquina pueda hacer todo en el bucket **excepto subir archivos**.

---

### Parte 3: Configuración de Políticas de Bucket (Bucket Policies) y Precedencia de Evaluación IAM

En esta parte utilizaremos directivas JSON aplicadas en el propio bucket (**Bucket Policies**) para gobernar el acceso. Primero aplicaremos una política con efecto **`Deny`** para la acción `PutObject` dirigida al rol `LabRole`, demostrando cómo una directiva de denegación en una política de recurso invalida los permisos de la identidad. Posteriormente, configuraremos lectura pública anónima y exigiremos conexiones cifradas por HTTPS (TLS).

#### Paso 3.1: Obtención del ARN del rol `LabRole`

1. En una nueva pestaña de la consola de AWS, ve al servicio **IAM** -> **Roles**.
2. En el cuadro de búsqueda escribe `LabRole` y haz clic sobre él.
3. Copia el **ARN del rol**, que tendrá un formato similar a:
   `arn:aws:iam::123456789012:role/LabRole`

#### Paso 3.2: Aplicar la política de bucket con `Deny` para la acción `PutObject` de `LabRole`

1. Vuelve a la consola de **Amazon S3**, entra en tu bucket `reportbucket-NOMBRE-APELLIDO` y selecciona la pestaña **Permisos (Permissions)**.
2. Desplázate hasta la sección **Política de bucket (Bucket policy)** y haz clic en **Editar**.
3. Pega la siguiente directiva JSON, sustituyendo `123456789012` por tu ID de cuenta y `reportbucket-NOMBRE-APELLIDO` por el nombre real de tu bucket:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenegarSubidaEC2LabRole",
      "Effect": "Deny",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:role/LabRole"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::reportbucket-NOMBRE-APELLIDO/*"
    }
  ]
}
```

!!! note "Lógica de evaluación IAM: Precedencia absoluta del `Deny` explícito"
    - **`Effect: Deny`**: En la lógica de evaluación de AWS IAM, **un `Deny` explícito siempre prevalece sobre cualquier `Allow`**. Aunque la política de identidad del rol `LabRole` autorice la escritura en el bucket, el `Deny` de la Bucket Policy la invalida de inmediato.
    - **`Action: s3:PutObject`**: Únicamente se restringe la acción de subir o sobrescribir objetos. Las acciones de lectura y listado no se ven afectadas por esta regla.
    - **`Resource: .../*`**: Aplica sobre cualquier objeto contenido dentro del depósito.

4. Haz clic en **Guardar cambios**.

#### Paso 3.3: Comprobar la restricción en EC2: Denegación de subida y persistencia de lectura

Regresa a la terminal interactiva de la máquina EC2 y realiza las siguientes comprobaciones:

1. Crea un segundo archivo de informe e intenta subirlo al bucket:

```bash
echo "Informe 2 generado el $(date)" > report-test2.txt
aws s3 cp report-test2.txt s3://reportbucket-NOMBRE-APELLIDO/
```

!!! failure "Fallo de autorización por Deny explícito en la Bucket Policy"
    El comando devolverá inmediatamente un error:
    ```text
    upload failed: ./report-test2.txt to s3://reportbucket-NOMBRE-APELLIDO/report-test2.txt
    An error occurred (AccessDenied) when calling the PutObject operation: Access Denied
    ```
    **Diagnóstico:** Aunque la máquina dispone del rol `LabRole`, la política de bucket ha denegado explícitamente `s3:PutObject`. La subida queda completamente vetada.

2. Comprueba ahora si la máquina virtual sigue pudiendo listar el contenido del bucket:

```bash
aws s3 ls s3://reportbucket-NOMBRE-APELLIDO/
```

*(El listado se mostrará sin errores, evidenciando que `s3:ListBucket` sigue permitido por el rol).*

3. Comprueba que la máquina también puede seguir descargando objetos del bucket:

```bash
aws s3 cp s3://reportbucket-NOMBRE-APELLIDO/report-test1.txt copia-descargada.txt
cat copia-descargada.txt
```

!!! success "Comportamiento selectivo comprobado: todo permitido salvo subir archivos"
    Hemos verificado cómo la instancia EC2 puede realizar todas las tareas de consulta y lectura gracias a los permisos de `LabRole`, pero **no puede subir cosas al bucket**, exactamente lo establecido por nuestra política de denegación selectiva.

#### Paso 3.4: Verificación de acceso externo desde el equipo local con `--no-sign-request`

Ahora que hemos comprobado cómo responde la máquina EC2 ante la política, abre una **segunda terminal en tu propio ordenador local** para comprobar cómo responde el bucket ante peticiones externas sin credenciales.

!!! info "¿Por qué utilizaremos el parámetro `--no-sign-request`?"
    En tu ordenador local tienes configuradas en `~/.aws/credentials` las credenciales de estudiante de AWS Academy Learner Lab. En AWS, dentro de la misma cuenta, **si una política de identidad (IAM) otorga un permiso, este se concede a menos que haya un `Deny` explícito**. Por tanto, tus credenciales locales de alumno ya disponen de permisos para operar sobre tus buckets.
    
    Para simular con exactitud cómo responderá S3 ante un **cliente externo, un usuario anónimo o una aplicación de internet sin credenciales**, utilizaremos la bandera `--no-sign-request`, que obliga al AWS CLI a enviar peticiones sin firmar.

1. Intenta subir un archivo desde tu terminal local de forma anónima:

```bash
echo "Prueba desde mi terminal local" > reporte-local.txt
aws s3 cp reporte-local.txt s3://reportbucket-NOMBRE-APELLIDO/ --no-sign-request
```

!!! failure "Fallo de autorización en el CLI local: AccessDenied"
    La terminal local devolverá el error:
    ```text
    upload failed: ./reporte-local.txt to s3://reportbucket-NOMBRE-APELLIDO/reporte-local.txt
    An error occurred (AccessDenied) when calling the PutObject operation: Access Denied
    ```

2. Intenta igualmente descargar un archivo sin credenciales:

```bash
aws s3 cp s3://reportbucket-NOMBRE-APELLIDO/new-report.png copia.png --no-sign-request
```

*(El comando también fallará con `AccessDenied`)*.

**Conclusión didáctica:** Hasta ahora, el bucket solo permite lectura y listado a identidades autenticadas de la cuenta (como la máquina EC2 mediante `LabRole`), denegando la escritura a `LabRole` por la Bucket Policy. Cualquier cliente externo sin autenticar queda bloqueado por denegación implícita predeterminada de S3.

---

#### Paso 3.5: Aplicar la 2ª directiva (Lectura pública) y verificar en Navegador y CLI local

En el **Paso 1.4** comprobamos que `sample-file.txt` devolvía `AccessDenied` al abrirlo en el navegador porque no habíamos configurado su ACL individual. 

En lugar de repetir el engorroso proceso de editar la ACL archivo por archivo, utilizaremos la potencia de la **Bucket Policy** para autorizar la lectura a cualquier cliente de internet (navegadores web y peticiones anónimas de terminal), manteniendo intacta la prohibición de subida para la instancia EC2:

1. En la pestaña **Permisos (Permissions)** de tu bucket, desplázate hasta **Política de bucket (Bucket policy)** y haz clic en **Editar**.
2. Añade una segunda declaración (`Statement`) a la directiva existente que conceda `s3:GetObject` a cualquier identidad o público anónimo (`Principal: "*"`):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenegarSubidaEC2LabRole",
      "Effect": "Deny",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:role/LabRole"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::reportbucket-NOMBRE-APELLIDO/*"
    },
    {
      "Sid": "PermitirLecturaPublicaAnonima",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::reportbucket-NOMBRE-APELLIDO/*"
    }
  ]
}
```

3. Pulsa **Guardar cambios**.

4. **Comprobación 1 (Navegador):**  
   Recarga la URL de objeto de `sample-file.txt` en una ventana de incógnito del navegador: el archivo de texto ahora se visualiza al instante sin autenticación.

5. **Comprobación 2 (CLI local - Descarga pública permitida sin credenciales):**  
   Vuelve a la terminal de tu equipo local y descarga el archivo usando el CLI de AWS con `--no-sign-request`:
   ```bash
   aws s3 cp s3://reportbucket-NOMBRE-APELLIDO/sample-file.txt ./descarga-local.txt --no-sign-request
   cat descarga-local.txt
   ```
   *(La descarga se completa con éxito sin necesidad de credenciales gracias a la directiva pública `s3:GetObject`)*.

6. **Comprobación 3 (CLI local - Escritura protegida):**  
   Intenta de nuevo subir un archivo de forma anónima desde tu terminal local:
   ```bash
   aws s3 cp reporte-local.txt s3://reportbucket-NOMBRE-APELLIDO/ --no-sign-request
   ```
   **¡Vuelve a fallar con `AccessDenied`!**  
   Aunque el bucket permite que cualquier persona del mundo lea los objetos, **la escritura sigue protegida**. Ningún usuario anónimo puede subir objetos, y nuestra instancia EC2 (`LabRole`) sigue teniendo denegado el `PutObject` por la primera regla.

!!! success "El poder de la Bucket Policy frente a las ACLs"
    Con tan solo añadir esas directivas en JSON y apuntar al comodín `reportbucket-NOMBRE-APELLIDO/*`, **todos los objetos actuales y cualquier archivo que se suba en el futuro quedan gobernados automáticamente**, aplicando políticas granulares (lectura pública para todos, pero subida bloqueada para la máquina EC2 y clientes anónimos). 
    
    No ha hecho falta tocar la ACL individual de ningún archivo. Por este motivo, la arquitectura moderna de AWS promueve **deshabilitar completamente las ACLs (*Bucket owner enforced*)** y delegar todo el control de acceso en las Políticas de Bucket y las Políticas IAM.

---

#### Paso 3.6: Seguridad Corporativa Avanzada: Forzar Cifrado en Tránsito (HTTPS obligatorio con `Condition`)

En el Paso 3.5 autorizamos la lectura pública (`Principal: "*"`). Sin embargo, un estándar de seguridad corporativo estricto (como las directrices del *CIS AWS Foundations Benchmark* o el Esquema Nacional de Seguridad) exige que toda transferencia de datos en la nube viaje cifrada mediante TLS/HTTPS, prohibiendo terminantemente el protocolo HTTP en texto plano.

Para aplicar esta restricción sin revocar el acceso legítimo, utilizaremos el elemento más potente de las directivas IAM: el bloque **`Condition`**.

1. En la consola de S3, accede a tu bucket -> pestaña **Permisos** -> **Política de bucket** -> **Editar**.
2. Incorpora una tercera declaración (`Statement`) con un efecto `Deny` cuando la condición `aws:SecureTransport` sea falsa:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenegarSubidaEC2LabRole",
      "Effect": "Deny",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:role/LabRole"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::reportbucket-NOMBRE-APELLIDO/*"
    },
    {
      "Sid": "PermitirLecturaPublicaAnonima",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::reportbucket-NOMBRE-APELLIDO/*"
    },
    {
      "Sid": "ForzarCifradoEnTransitoTLS",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::reportbucket-NOMBRE-APELLIDO",
        "arn:aws:s3:::reportbucket-NOMBRE-APELLIDO/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
```

3. Haz clic en **Guardar cambios**.

4. **Comprobación en la terminal local con `curl`:**  
   Verifica el cumplimiento de la condición ejecutando una petición HTTP insegura frente a una petición HTTPS cifrada sobre el archivo público `sample-file.txt`:

```bash
# 1. Petición insegura en texto plano por HTTP ordinario:
curl -I http://reportbucket-NOMBRE-APELLIDO.s3.amazonaws.com/sample-file.txt
```

!!! failure "Bloqueo por directiva de denegación explícita (HTTP 403 Forbidden)"
    La respuesta del servidor será:
    ```http
    HTTP/1.1 403 Forbidden
    x-amz-error-code: AccessDenied
    ```
    **Principio de evaluación de IAM:** Aunque la directiva previa `PermitirLecturaPublicaAnonima` concede lectura pública (`Allow`), **un `Deny` explícito tiene precedencia absoluta e invalida cualquier `Allow`**.

5. Ejecuta ahora la petición segura a través de HTTPS:

```bash
# 2. Petición cifrada y segura por HTTPS (TLS):
curl -I https://reportbucket-NOMBRE-APELLIDO.s3.amazonaws.com/sample-file.txt
```

!!! success "Acceso concedido mediante canal cifrado (HTTP 200 OK)"
    La respuesta devolverá:
    ```http
    HTTP/1.1 200 OK
    Content-Type: text/plain
    ```
    Como la conexión viaja cifrada por TLS (`aws:SecureTransport: "true"`), la condición del `Deny` no se cumple y se aplica el `Allow` público normalmente.

---

### Parte 4: Exploración del Control de Versiones (S3 Versioning)

El versionado protege los datos contra sobrescrituras accidentales o borrados no intencionados, almacenando un histórico completo de cada cambio.

#### Paso 4.1: Habilitar el control de versiones

1. En la consola de S3, accede a tu bucket `reportbucket-NOMBRE-APELLIDO` y haz clic en la pestaña **Propiedades (Properties)**.
2. En la sección **Control de versiones de buckets (Bucket Versioning)**, pulsa **Editar**.
3. Selecciona **Habilitar (Enable)** y pulsa **Guardar cambios**.

#### Paso 4.2: Sobreescritura y recuperación de versiones anteriores

1. En tu equipo local, edita el archivo `sample-file.txt` agregando una nueva línea al final:

```text
This sample text file is used to illustrate the use of versioning in an Amazon S3 bucket.

Make it a great day!
Nueva versión actualizada para el laboratorio de ABDAN.
```

2. En la consola de S3, sube el archivo modificado `sample-file.txt` con el **mismo nombre exacto**.
3. Ve a la pestaña del navegador donde tenías abierta la URL del objeto y pulsa recargar (F5):
    - Se mostrará la nueva versión con el texto añadido. Amazon S3 siempre sirve por defecto la versión más reciente (*latest version*).
4. Vuelve a la pestaña **Objetos** de tu bucket en la consola de AWS.
5. Activa el interruptor **Mostrar versiones (Show versions)** situado en la parte superior derecha de la tabla de objetos.

!!! tip "Inspección de versiones en la consola"
    Observarás que debajo de `sample-file.txt` aparecen ahora **dos entradas**:
    - La superior corresponde a la versión actual, identificada con un hash único en la columna **ID de versión**.
    - La inferior corresponde a la versión original previa. Si haces clic sobre ella, podrás descargarla o consultar sus metadatos históricos intactos.

#### Paso 4.3: Borrado Lógico con Marcador de Eliminación (Soft Delete)

¿Qué ocurre si un usuario o proceso elimina un archivo en un bucket versionado?

1. Desactiva el interruptor **Mostrar versiones** (para operar en la vista habitual de S3).
2. Marca la casilla de selección de `sample-file.txt` y haz clic en **Eliminar (Delete)**.
3. Confirma escribiendo `eliminar` y pulsa **Eliminar objetos**.
4. Cierra la ventana y observa la lista de objetos: el archivo `sample-file.txt` **ha desaparecido** de la vista.
5. Intenta recargar la URL del objeto en el navegador: obtendrás un error `404 Not Found`.
6. Ahora, vuelve a activar el interruptor **Mostrar versiones**:


Observa que S3 **no ha borrado ningún dato**. En su lugar, ha insertado un objeto especial llamado **Marcador de eliminación (Delete marker)** en la cima de la pila de versiones.

---

#### Paso 4.4: Auditoría y Recuperación ante Desastres por CLI (`aws s3api`)

En el paso anterior comprobamos cómo la consola gráfica oculta el objeto colocando un marcador en la cabecera. Sin embargo, en entornos corporativos o ante incidentes de borrado accidental masivo, los ingenieros cloud no restauran archivos mediante clics manuales en la web, sino mediante scripts y la API de bajo nivel de AWS (**`aws s3api`**).

1. Abre tu terminal local y consulta la pila de versiones de `sample-file.txt` en formato estructurado JSON:

```bash
aws s3api list-object-versions \
    --bucket reportbucket-NOMBRE-APELLIDO \
    --prefix sample-file.txt
```

!!! tip "Análisis del JSON de versiones"
    Observarás dos arrays principales en la respuesta:
    - `"DeleteMarkers"`: Contiene el marcador activo actual con su `VersionId` y `"IsLatest": true`.
    - `"Versions"`: Contiene las versiones reales históricas con `"IsLatest": false`, preservadas íntegramente en los discos de S3.

2. **Extracción automatizada del identificador con filtro JMESPath (`--query`):**  
   Filtra y almacena el `VersionId` del marcador de eliminación en una variable de entorno:

```bash
MARKER_ID=$(aws s3api list-object-versions \
    --bucket reportbucket-NOMBRE-APELLIDO \
    --prefix sample-file.txt \
    --query 'DeleteMarkers[0].VersionId' \
    --output text)

echo "El VersionId del Delete Marker es: $MARKER_ID"
```

3. **Restauración del archivo por línea de comandos:**  
   Elimina físicamente el marcador de borrado utilizando su identificador:

```bash
aws s3api delete-object \
    --bucket reportbucket-NOMBRE-APELLIDO \
    --key sample-file.txt \
    --version-id "$MARKER_ID"
```

4. Comprueba con el comando ordinario de S3 que el archivo ha "resucitado" y vuelve a estar accesible:

```bash
aws s3 ls s3://reportbucket-NOMBRE-APELLIDO/
```

*(El archivo `sample-file.txt` reaparece en el listado y vuelve a responder con código 200 en el navegador)*.

---

#### Paso 4.5: Borrado Físico Definitivo (Hard Delete)

1. En la consola de AWS, vuelve a la pestaña de objetos y activa el interruptor **Mostrar versiones**.
2. Selecciona únicamente la **versión más reciente** de `sample-file.txt` (la que tiene el texto añadido) y haz clic en **Eliminar**.
3. En el cuadro de diálogo se te advertirá: *¿Desea eliminar permanentemente los objetos?*. Escribe `eliminar permanentemente` y confirma.
4. Cierra la ventana, desactiva *Mostrar versiones* y recarga la URL del objeto en tu navegador.
5. Comprobarás que la versión actual es ahora la versión original del archivo, ya que la versión posterior ha sido destruida de forma irreversible.

---

### Parte 5: Automatización de Costes con Reglas de Ciclo de Vida (S3 Lifecycle)

Como has comprobado en la Parte 4, el versionado preserva todos los cambios históricos. Sin embargo, en un entorno de producción con miles de actualizaciones diarias, **las versiones no actuales (*noncurrent versions*) y los marcadores de eliminación se acumulan indefinidamente**, incrementando la factura mensual de almacenamiento sin aportar valor operativo.

Para resolver este desafío sin intervención manual, implementaremos una **Regla de Ciclo de Vida (Lifecycle Rule)** que gestione el ciclo vital de las versiones obsoletas.

#### Paso 5.1: Configuración de la regla de ciclo de vida

1. En la consola de S3, accede a tu bucket `reportbucket-NOMBRE-APELLIDO`.
2. Haz clic en la pestaña **Administración (Management)**.
3. En la sección **Reglas de ciclo de vida (Lifecycle rules)**, pulsa en **Crear regla de ciclo de vida (Create lifecycle rule)**.
4. Configura los parámetros iniciales de la regla:
    - **Nombre de la regla:** `GestionarVersionesAntiguas`.
    - **Ámbito de la regla (Rule scope):** Selecciona **Aplicar a todos los objetos del bucket (Apply to all objects in the bucket)**.
    - Marca la casilla de verificación: *Reozco que esta regla se aplicará a todos los objetos del bucket*.

#### Paso 5.2: Definición de las acciones de transición y purga

En la sección **Acciones de la regla de ciclo de vida (Lifecycle rule actions)**, marca las siguientes tres casillas:

1. **Mover versiones no actuales de objetos entre clases de almacenamiento (Move noncurrent versions of objects between storage classes)**:
    - En *Transiciones de versiones no actuales*:
        - **Clase de almacenamiento:** Selecciona **Glacier Flexible Retrieval** (antes *Amazon Glacier*).
        - **Días después de que los objetos se conviertan en versiones no actuales:** Introduce `90` días.
        - **Número de versiones más recientes que se conservarán (opcional):** Introduce `2` (para asegurar que siempre se retengan al menos las 2 versiones inmediatamente anteriores).

2. **Eliminar permanentemente las versiones no actuales de los objetos (Permanently delete noncurrent versions of objects)**:
    - **Días después de que los objetos se conviertan en versiones no actuales:** Introduce `365` días (al transcurrir 1 año, las versiones archivadas se eliminarán físicamente).

3. **Eliminar marcadores de eliminación de objetos caducados o cargas分partes incompletas (Delete expired object delete markers or incomplete multipart uploads)**:
    - Marca **Eliminar marcadores de eliminación de objetos caducados (Delete expired object delete markers)**.

!!! tip "¿Qué es un marcador de eliminación caducado (*Expired delete marker*)?"
    Cuando todas las versiones históricas de un objeto han sido finalmente eliminadas por una regla de expiración, el *Delete Marker* se queda solo en el bucket ("huérfano"). Activar esta opción indica a S3 que elimine automáticamente dicho marcador, liberando el bucket de residuos lógicos sin coste.

#### Paso 5.3: Revisión de la línea temporal y guardado

1. Desplázate al final de la página y examina la tabla de resumen **Acciones de ciclo de vida para las versiones no actuales**.
2. Observa la progresión temporal:
    - **Día 0:** El objeto se convierte en versión no actual.
    - **Día 90:** Se transiciona automáticamente a *S3 Glacier Flexible Retrieval*.
    - **Día 365:** Se destruye permanentemente.
3. Haz clic en **Crear regla (Create rule)**.

---

## 3. Limpieza de Recursos (Clean-up)

Para evitar consumos de cómputo innecesarios en tu cuenta de AWS Academy:

### 1. Terminar la instancia EC2
1. Dirígete a la consola de **EC2** -> **Instancias**.
2. Selecciona la instancia `Servidor-Reportes`.
3. Haz clic en **Estado de la instancia** -> **Terminar instancia (Terminate instance)** y confirma.

### 2. Vaciar y eliminar el bucket S3
1. Dirígete a **S3** -> selecciona tu bucket `reportbucket-NOMBRE-APELLIDO`.
2. Pulsa en **Vaciar (Empty)**.
   *(Al estar el versionado activo, el proceso de vaciado eliminará de forma secuencial todas las versiones históricas y marcadores de eliminación)*. Confirma escribiendo `vaciar permanentemente`.
3. Una vez vacío, pulsa en **Eliminar (Delete)** y confirma escribiendo el nombre del bucket.

---

## 4. Entregables

Presenta un documento o memoria de prácticas que contenga:

1. **Captura de terminal en EC2:** Salida del comando `aws s3 cp` demostrando la subida inicial exitosa gracias a los permisos predeterminados de `LabRole` (Paso 2.4), y captura posterior demostrando el error `AccessDenied` al intentar subir un archivo tras aplicar la directiva `Deny` en la política de bucket, contrastado con la capacidad de seguir listando y descargando objetos (Paso 3.3).
2. **Captura de terminal local (AWS CLI con `--no-sign-request`):** Salida que demuestre el error `AccessDenied` al intentar subir archivos tras la 1ª política, y la posterior descarga satisfactoria de `sample-file.txt` tras añadir la 2ª política pública.
3. **Captura de forzado de cifrado TLS (curl):** Salida en la terminal local ejecutando `curl -I http://...` (bloqueado con `403 Forbidden`) frente a `curl -I https://...` (autorizado con `200 OK`).
4. **Documento de la Política de Bucket:** El JSON final configurado en el bucket con las tres declaraciones (`Deny` a `PutObject` para `LabRole`, lectura pública anónima y denegación de tráfico no TLS), justificando brevemente la función de cada bloque.
5. **Captura de recuperación ante desastres por CLI (`aws s3api`):** Salida de la terminal local ejecutando `aws s3api list-object-versions` y la eliminación del *Delete Marker* con `aws s3api delete-object` restaurando el archivo.
6. **Captura de la Regla de Ciclo de Vida:** Captura del resumen de la regla creada en la pestaña *Administración* mostrando las transiciones a Glacier y la eliminación programada.

