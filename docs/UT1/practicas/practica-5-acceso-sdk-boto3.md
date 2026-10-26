---
search:
  exclude: true
---

# Práctica 1.5: Acceso Programático a Amazon S3 con Python (Boto3)

- **Módulo:** Administración de Bases de Datos y Almacenamiento en la Nube (ABDAN)
- **Unidad de Trabajo:** UT1. Servicios de almacenamiento de objetos en la nube (Amazon S3)
- **Resultados de Aprendizaje asociados:**
    - **RA2.a:** Definición de nombres de buckets y recursos según limitaciones técnicas.
    - **RA2.b:** Definición de clases de almacenamiento y metadatos de objetos.
    - **RA2.e:** Configuración de parámetros de visibilidad, acceso y generación de credenciales temporales.
    - **RA5.a:** Automatización del flujo de datos y transferencia de información hacia y desde la nube.

---

## 1. Preparación del Entorno de Trabajo

Para trabajar de forma limpia y aislada sin modificar la instalación global de Python en tu equipo, utilizaremos un **entorno virtual (`venv`)**.

### Paso 1.1: Crear la carpeta de trabajo y el entorno virtual

Abre tu terminal local y ejecuta:

```bash
# 1. Crear carpeta de trabajo y acceder a ella
mkdir -p ~/practica-boto3
cd ~/practica-boto3

# 2. Crear el entorno virtual con Python 3
python3 -m venv venv

# 3. Activar el entorno virtual:
# En Linux / macOS / WSL:
source venv/bin/activate

# (En Windows PowerShell usa: .\venv\Scripts\Activate.ps1)
```

*(Comprueba que aparece el prefijo `(venv)` en el indicador de tu terminal).*

### Paso 1.2: Instalar la biblioteca Boto3

Con el entorno virtual activo, instala el SDK oficial de AWS:

```bash
pip install boto3
```

### Paso 1.3: Verificación de credenciales activas

Boto3 lee automáticamente las credenciales configuradas en tu entorno local (`~/.aws/credentials`). Comprueba que tu sesión del Learner Lab está activa ejecutando:

```bash
aws sts get-caller-identity
```

---

## 2. Ejercicios

En cada tarea crearás un script en Python a partir de una plantilla guiada. Sustituye las marcas `___` por la variable o parámetro adecuado.

---

### Tarea 1: Creación de Bucket considerando la Región (`01_crear_bucket.py`)

Tal como se explica en la teoría, en Amazon S3 la región `us-east-1` no admite `CreateBucketConfiguration`, mientras que en cualquier otra región (`us-west-2`, `eu-west-1`, etc.) es obligatorio especificarla.

1. Dentro de `~/practica-boto3`, crea el archivo `01_crear_bucket.py`.
2. Utiliza el código de ejemplo en el apartado de la teoría.
3. Ejecuta el script:

```bash
python 01_crear_bucket.py
```

4. Verifica con el AWS CLI que el bucket existe en tu cuenta:

```bash
aws s3 ls
```

---

### Tarea 2: Subida de Archivo con Clase de Almacenamiento y Metadatos (`02_subir_archivo.py`)

En administración de sistemas no solo subimos archivos; a menudo debemos asignar metadatos de auditoría o definir la clase de almacenamiento adecuada para optimizar costes.

1. Genera un archivo local de prueba:
2. Crea el archivo `02_subir_archivo.py`.
3. Utiliza el código de ejemplo en el apartado de la teoría. Crea una función para subir archivos, del mismo estilo que la de creación de buckets.
4. Ejecuta el script:
5. **Inspección de metadatos:** Comprueba desde la terminal con `aws s3api head-object` que la clase de almacenamiento y los metadatos personalizados se han registrado en S3:

```bash
aws s3api head-object \
    --bucket TU-NOMBRE-DE-BUCKET \
    --key documentos/auditoria.txt
```

---

### Tarea 3: Descarga del Objeto (`03_descargar_archivo.py`)

1. Crea el archivo `03_descargar_archivo.py`.
2. Utiliza el código de ejemplo en el apartado de la teoría. Crea una función para descargar archivos, del mismo estilo que la de creación de buckets.
3. Ejecuta el script:

```bash
python 03_descargar_archivo.py
```

---

### Tarea 4: Generación y Verificación de URL Prefirmada (`04_url_prefirmada.py`)

Una URL prefirmada (*Presigned URL*) permite conceder acceso temporal de descarga a un tercero **sin credenciales de AWS y sin hacer público el bucket**.

1. Crea el archivo `04_url_prefirmada.py`.
2. Utiliza el código de ejemplo en el apartado de la teoría. Crea una función para firmar URL, del mismo estilo que la de creación de buckets.
3. Ejecuta el script:
4. **Comprobación:**
   - Copia la URL devuelta en la terminal y ábrela en una **ventana de incógnito** de tu navegador (o mediante `curl -I "URL"`).
   - Comprueba que el archivo privado se visualiza y descarga inmediatamente sin solicitar contraseñas.


---

## 3. Limpieza de Recursos (Clean-up)

Para no consumir recursos en tu cuenta de AWS Academy:

1. Vacía y elimina el bucket de pruebas creado con el AWS CLI:

```bash
aws s3 rb s3://TU-NOMBRE-DE-BUCKET --force
```

2. Desactiva el entorno virtual de Python:

```bash
deactivate
```

---

## 4. Entregables

Presenta una memoria o documento breve con:

1. **Captura 1 (Tarea 1):** Salida en la terminal de `01_crear_bucket.py` y salida del comando `aws s3 ls` demostrando la existencia del bucket.
2. **Captura 2 (Tarea 2):** Salida en terminal del comando `aws s3api head-object` mostrando la clase de almacenamiento (`INTELLIGENT_TIERING`) y los metadatos aplicados al objeto.
3. **Captura 3 (Tarea 3):** Salida de `03_descargar_archivo.py` mostrando la descarga y la visualización del contenido.
4. **Captura 4 (Tarea 4):** Salida de `04_url_prefirmada.py` con la URL generada y captura del navegador mostrando el contenido del archivo abierto mediante dicha URL.
5. **Código completado:** Copia o adjunta los 4 archivos `.py` con los huecos debidamente rellenados.
