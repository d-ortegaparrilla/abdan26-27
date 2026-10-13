# Práctica 1.1: Operaciones Básicas y Avanzadas con Amazon S3 (Consola Gráfica y AWS CLI)

- **Módulo:** Administración de Bases de Datos y Almacenamiento en la Nube (ABDAN)
- **Unidad de Trabajo:** UT1. Servicios de almacenamiento de objetos en la nube (Amazon S3)
- **Resultados de Aprendizaje asociados:**
    - **RA1.a:** Comprobación de operaciones de almacenamiento de objetos frente a requisitos técnicos.
    - **RA2.a:** Definición de nombres de buckets y etiquetas de metadatos según limitaciones técnicas.
    - **RA2.b:** Definición de clases de almacenamiento y objetos según requisitos de latencia y coste.
    - **RA2.c:** Selección de región geográfica por latencia, coste y residencia.
    - **RA2.e:** Configuración de parámetros de visibilidad, acceso y generación de credenciales temporales.


---

## 1. Operaciones desde la Consola Gráfica de AWS

### Tarea 1.1: Creación del bucket principal

1. Accede a la consola de **Amazon S3** en AWS Academy.
2. Pulsa en **Crear bucket (Create bucket)** y aplica los siguientes parámetros:
    - **Tipo de depósito:** *General Purpose Bucket* (Shared Global Namespace).
    - **Nombre del bucket:** Debe ser un identificador global único. Utiliza la nomenclatura:  
      `abdan-NOMBRE-APELLIDO-lab1` *(en minúsculas, números y guiones)*.
    - **Región de AWS:** `us-east-1` (Norte de Virginia) o `us-west-2` (Oregón) —las permitidas por Learner Lab—.
    - **Propiedad de objetos:** Mantener **ACL deshabilitadas (recomendado)**.
    - **Bloqueo de acceso público:** Dejar marcada la casilla **Bloquear todo el acceso público** (*Block all public access*).
    - **Cifrado predeterminado:** Cifrado del lado del servidor con claves administradas por S3 (**SSE-S3**).
3. Pulsa **Crear bucket** al final de la página.

### Tarea 1.2: Carga de archivos, carpetas y exploración de identificadores

1. Entra al bucket recién creado.
2. Sube tres archivos de prueba de distinta extensión (un documento de texto `.txt`, un PDF `.pdf` y una imagen `.png` o `.jpg`).
3. Pulsa en **Crear carpeta (Create folder)** y crea una subcarpeta lógica denominada `documentos/`.
4. Accede a la carpeta creada y sube un nuevo archivo en su interior.
5. Selecciona el archivo que has subido dentro de `documentos/` y observa la cabecera de detalles:
    - Localiza y copia en un bloc de notas sus tres direcciones: **S3 URI**, **Amazon Resource Name (ARN)** y **Object URL**.
    - Revisa la pestaña **Propiedades (Properties)** para verificar la clase de almacenamiento asignada (`Standard`) y el hash **ETag**.

---

## 2. Comandos de Alto Nivel vs. Bajo Nivel y Metadatos

Abre tu terminal local.

### Tarea 2.1: Verificación de identidad y credenciales

Asegúrate de que tus credenciales de AWS Academy están activas en `~/.aws/credentials`:

```bash
aws sts get-caller-identity
```

Verifica que el comando devuelve tu `UserId`, `Account` y el ARN de tu rol de laboratorio.

### Tarea 2.2: Creación de un segundo bucket por CLI

Crea un segundo bucket destinado a pruebas avanzadas desde la terminal:

```bash
# Define una variable con tu prefijo para no equivocarte
MI_BUCKET="abdan-$(whoami)-cli"

# Crear el bucket con el comando de alto nivel 'mb' (Make Bucket)
aws s3 mb s3://$MI_BUCKET --region us-east-1

# Comprobar que aparece en tu cuenta
aws s3 ls
```

### Tarea 2.3: Inyección de Metadatos de Usuario (`x-amz-meta-*`)

1. Crea un fichero de informe local:
   ```bash
   echo "Informe confidencial de auditoría de sistemas 2026" > informe_seguridad.txt
   ```

2. Sube el archivo inyectando **metadatos de usuario personalizados** mediante el parámetro `--metadata`:
   ```bash
   aws s3 cp informe_seguridad.txt s3://$MI_BUCKET/auditorias/informe_seguridad.txt \
       --metadata "autor=tu-nombre,departamento=ciberseguridad,clasificacion=confidencial"
   ```

3. **Inspección con comando de bajo nivel (`aws s3api`):**  
   Utiliza `head-object` para obtener las cabeceras HTTP y los metadatos almacenados:
   ```bash
   aws s3api head-object \
       --bucket $MI_BUCKET \
       --key auditorias/informe_seguridad.txt
   ```

!!! question "Pregunta de reflexión 1"
    Examina el JSON devuelto por `head-object`. ¿Bajo qué clave aparecen los metadatos personalizados que has introducido? ¿Qué información técnica del archivo acompaña a la respuesta?

---

## 3. Consultas Avanzadas y Filtrado con JMESPath (`--query`)

En entornos de producción con miles de objetos, la administración requiere consultar atributos concretos sin saturar la salida.

### Tarea 3.1: Generación de archivos de muestra

Genera en local varios archivos con tamaños deliberadamente distintos:

```bash
mkdir muestras
echo "Texto breve" > muestras/pequeno.txt
head -c 2048 /dev/urandom > muestras/medio_2kb.dat
head -c 10240 /dev/urandom > muestras/grande_10kb.dat

# Subir los archivos a S3
aws s3 cp muestras/ s3://$MI_BUCKET/muestras/ --recursive
```

### Tarea 3.2: Consultas estructuradas

1. **Listar únicamente las claves (nombres) y el tamaño formateado en tabla:**
   ```bash
   aws s3api list-objects-v2 \
       --bucket $MI_BUCKET \
       --query "Contents[].[Key, Size, StorageClass]" \
       --output table
   ```

2. **Filtrar con condición JMESPath (solo objetos que pesen más de 1.000 bytes):**
   ```bash
   aws s3api list-objects-v2 \
       --bucket $MI_BUCKET \
       --query "Contents[?Size > \`1000\`].[Key, Size]" \
       --output table
   ```

---

## 4. Clases de Almacenamiento y el Experimento de Glacier

Vamos a comprobar en la práctica cómo responde S3 ante distintas clases de almacenamiento y qué ocurre al intentar leer datos en frío.

### Tarea 4.1: Asignación de clases en subida

Sube tres archivos asignándoles diferentes clases de almacenamiento:

```bash
# 1. Clase S3 Intelligent-Tiering
aws s3 cp ./muestras/pequeno.txt s3://$MI_BUCKET/clases/archivo_it.txt \
    --storage-class INTELLIGENT_TIERING

# 2. Clase S3 One Zone-IA (Acceso infrecuente en una sola AZ)
aws s3 cp ./muestras/pequeno.txt s3://$MI_BUCKET/clases/archivo_onezone.txt \
    --storage-class ONEZONE_IA

# 3. Clase S3 Glacier Flexible Retrieval (Archivado a largo plazo)
aws s3 cp ./muestras/pequeno.txt s3://$MI_BUCKET/clases/archivo_glacier.txt \
    --storage-class GLACIER
```

Comprueba las clases asignadas con una consulta estructurada:
```bash
aws s3api list-objects-v2 \
    --bucket $MI_BUCKET \
    --prefix clases/ \
    --query "Contents[].[Key, StorageClass]" \
    --output table
```

### Tarea 4.2: La trampa de Glacier (Error en caliente)

1. Intenta descargar en local el archivo almacenado en `ONEZONE_IA`:
   ```bash
   aws s3 cp s3://$MI_BUCKET/clases/archivo_onezone.txt ./descarga_onezone.txt
   ```
   *(La descarga se completa de forma instantánea en milisegundos).*

2. Ahora intenta descargar el archivo almacenado en **Glacier**:
   ```bash
   aws s3 cp s3://$MI_BUCKET/clases/archivo_glacier.txt ./descarga_glacier.txt
   ```

!!! failure "¡Error esperado en Glacier!"
    El comando fallará mostrando un error similar a:  
    `fatal error: An error occurred (InvalidObjectState) when calling the GetObject operation: The operation is not valid for the object's storage class`

!!! question "Pregunta de reflexión 2"
    - ¿Por qué el comando `aws s3 cp` falla con el error `InvalidObjectState` al intentar descargar el archivo de Glacier?
    - ¿Qué procedimiento y qué comando (`aws s3api restore-object`) habría que ejecutar antes de poder leer dicho archivo? ¿Cuánto tardaría en estar disponible en el nivel Estándar?

---

## 5. Seguridad Práctica: Object URL vs. URL Prefirmada (*Presigned URL*)

### Tarea 5.1: Probar el acceso público bloqueado (Object URL)

1. Genera un fichero de datos sensibles:
   ```bash
   echo "CLAVE_SECRETA_API=123456789_XYZ" > secreto.env
   aws s3 cp secreto.env s3://$MI_BUCKET/privado/secreto.env
   ```

2. Construye la **Object URL** de ese archivo según el formato estándar:  
   `https://NOMBRE_DE_TU_BUCKET.s3.us-east-1.amazonaws.com/privado/secreto.env`

3. Abre una ventana de **incógnito** en tu navegador web y pega esa dirección URL.

!!! warning "Resultado esperado"
    El navegador debe responder con un error XML **`403 Forbidden` (`AccessDenied`)**, demostrando que el *Block Public Access* y las listas de control de acceso privadas están protegiendo el bucket.

### Tarea 5.2: Compartición segura y temporal con una Presigned URL

Imagina que debes entregar ese archivo a un cliente o compañero de equipo que **no tiene cuenta ni credenciales de AWS**, durante solo 5 minutos:

1. Genera una **URL prefirmada válida durante 300 segundos (5 minutos)** desde tu terminal:
   ```bash
   aws s3 presign s3://$MI_BUCKET/privado/secreto.env --expires-in 300
   ```

2. Copia la URL larguísima que aparece en la terminal (observa que incluye en los parámetros `X-Amz-Signature`, `X-Amz-Credential` y `X-Amz-Expires`).
3. Abre de nuevo tu navegador web en **modo incógnito** y pega la URL prefirmada.
4. **Verificación:** El archivo se descargará o abrirá inmediatamente en pantalla con código HTTP `200 OK`.
5. Si esperas más de 5 minutos e intentas recargar la página, ¿qué ocurre? Comprueba cómo el enlace expira automáticamente (`Request has expired`).

---

## 6. Sincronización Avanzada con Filtros y Flag Destructivo (`--delete`)

### Tarea 6.1: Sincronización selectiva con `--exclude` e `--include`

1. Crea un directorio local con varios ficheros:
   ```bash
   mkdir proyecto_local
   touch proyecto_local/app.py
   touch proyecto_local/config.json
   touch proyecto_local/temp_cache.tmp
   touch proyecto_local/error.log
   ```

2. Sincroniza hacia S3 **excluyendo todos los ficheros temporales (`*.tmp`)**:
   ```bash
   aws s3 sync ./proyecto_local/ s3://$MI_BUCKET/proyecto/ \
       --exclude "*.tmp"
   ```

3. Comprueba los archivos que han subido a S3:
   ```bash
   aws s3 ls s3://$MI_BUCKET/proyecto/
   ```
   *(Verifica que `temp_cache.tmp` no se ha subido).*

### Tarea 6.2: El peligro del flag `--delete` (Espejo estricto)

Por defecto, `aws s3 sync` nunca borra archivos en el destino si se eliminan en el origen. Para forzar un reflejo idéntico se utiliza `--delete`:

1. Elimina un archivo localmente:
   ```bash
   rm ./proyecto_local/error.log
   ```

2. Ejecuta una sincronización normal sin `--delete`:
   ```bash
   aws s3 sync ./proyecto_local/ s3://$MI_BUCKET/proyecto/ --exclude "*.tmp"
   aws s3 ls s3://$MI_BUCKET/proyecto/
   ```
   *(Observa que `error.log` sigue existiendo en el bucket).*

3. Ahora ejecuta la sincronización con `--delete`:
   ```bash
   aws s3 sync ./proyecto_local/ s3://$MI_BUCKET/proyecto/ \
       --exclude "*.tmp" \
       --delete
   aws s3 ls s3://$MI_BUCKET/proyecto/
   ```
   *(Comprueba que ahora `error.log` ha sido eliminado automáticamente del bucket).*

!!! warning "Peligro en producción"
    El flag `--delete` debe utilizarse con extrema precaución. Si un script local borra accidentalmente el directorio de origen y lanza un sync con `--delete`, borrará automáticamente todas las copias remotas de S3.

