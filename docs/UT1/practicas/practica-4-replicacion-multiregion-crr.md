# Práctica 1.4: Replicación Multirregión en Amazon S3 (Cross-Region Replication - CRR)

- **Módulo:** Administración de Bases de Datos y Almacenamiento en la Nube (ABDAN)
- **Unidad de Trabajo:** UT1. Servicios de almacenamiento de objetos en la nube (Amazon S3)
- **Resultados de Aprendizaje asociados:**
    - **RA1.a:** Comprobación de operaciones de almacenamiento de objetos frente a requisitos técnicos de durabilidad y resiliencia.
    - **RA2.c:** Selección de región geográfica por latencia, coste, soberanía y tolerancia a fallos.
    - **RA2.d:** Aplicación de mecanismos de seguridad y cifrado en almacenamiento de objetos.
    - **RA2.g:** Configuración de parámetros de versionado y reglas de replicación multirregión.

---

## 1. Laboratorio Oficial de AWS Skill Builder

Esta práctica se desarrollará de forma guiada en la plataforma **AWS Skill Builder**, accediendo al siguiente laboratorio práctico:

> 🔗 **Laboratorio en AWS Skill Builder:**  
> [**Implementing Multi-Region Backup with Amazon S3 Cross-Region Replication**](https://skillbuilder.aws/learn/NVQC5ZDTRE/implementing-multiregion-backup-with-amazon-s3-crossregion-replication/PAN1T8H3N7)



## Modificación requerida para la práctica:
Tarea 3. Además de seguir los pasos guiados del laboratorio para observar la limitación con KMS, **realizaremos una prueba complementaria con el cifrado propio del servicio S3 (SSE-S3)**:

1. Sube un archivo de prueba (puedes llamarlo `crr-s3-encrypted.txt` o usar cualquier archivo de prueba).
2. En las opciones de subida, despliega la sección **Propiedades** -> **Cifrado del lado del servidor**:
   - Selecciona **Cifrado del lado del servidor con claves administradas por Amazon S3 (SSE-S3)** (`AES256`).
3. Completa la subida hacia el bucket de origen.
4. Accede al bucket de destino en la región secundaria y refresca la lista:  
   *(Comprobarás que con **SSE-S3** la replicación se realiza con éxito y de manera inmediata, ya que Amazon S3 gestiona las claves de cifrado internamente en cada región de forma transparente sin requerir gestión externa de claves).*


---

## 2. Capturas


### Tarea 1

- **1a:** Configuración de versionado activo (*Bucket Versioning: Enabled*) tanto en el bucket de origen (`PrimaryRegion`) como en el bucket de destino (`SecondaryRegion`).
- **1b:** Pantalla de resumen de la regla de replicación creada en el bucket de origen, mostrando el nombre de la regla, el estado (*Enabled*), el bucket de destino y el rol IAM utilizado.

### Tarea 2

- **2a:** Vista del bucket de **origen** mostrando los dos archivos existentes: `pre-crr.txt` (subido antes de activar la replicación) y `crr-bucket.txt` (subido después).
- **2b:** Vista del bucket de **destino** mostrando únicamente `crr-bucket.txt`. La ausencia de `pre-crr.txt` evidencia que los objetos preexistentes antes de configurar la regla no se replican automáticamente.

### Tarea 3

- **3a:** Vista del bucket de **destino vacío** tras subir `crr-encrypted.txt` con cifrado **SSE-KMS** al origen. Este es el momento clave: la replicación **no se ha producido** porque las claves KMS son regionales y no se comparten entre regiones automáticamente.
- **3b:** Vista del bucket de **destino** tras volver a subir el mismo archivo esta vez con cifrado **SSE-S3** (claves administradas por Amazon S3). El archivo aparece replicado correctamente, demostrando que con SSE-S3 la replicación multirregión funciona de forma transparente.

### Tarea 4

- **4a:** Pantalla de configuración de la regla de replicación por prefijo, donde se aprecia el filtro establecido (`crr-test/`).
- **4b:** Vista del bucket de destino mostrando que la carpeta `crr-test/` contiene `crr-folder.txt`, mientras que en la raíz del bucket no existe `crr-folder-root.txt`.

### Tarea 5

- **5a:** Pantalla de configuración de la regla de replicación por etiquetas, donde se aprecia el filtro definido (`replicate: yes`).
- **5b:** Vista del bucket de destino demostrando que únicamente se ha replicado `crr-tag.txt` (etiqueta `replicate: yes`) y que `crr-no-tag.txt` (sin etiqueta) no aparece en el destino.

### Tarea 6

- **6a:** Vista del bucket de **origen** con la opción *Mostrar versiones (Show versions)* activa, donde se aprecia el **delete marker** colocado sobre `crr-tag.txt` como versión más reciente, sin que el objeto haya sido destruido físicamente.
- **6b:** Vista del bucket de **destino** confirmando que `crr-tag.txt` sigue íntegro y accesible, sin ningún marcador de eliminación replicado.

### Tarea 7

**Captura 7 (Knowledge Check superado):** Pantalla final del laboratorio en AWS Skill Builder mostrando el mensaje **`Passed`** en el *Knowledge Check*.
