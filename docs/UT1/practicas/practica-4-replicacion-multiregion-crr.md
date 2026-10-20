# Práctica 1.4: Replicación Multirregión en Amazon S3 (Cross-Region Replication - CRR)

- **Módulo:** Administración de Bases de Datos y Almacenamiento en la Nube (ABDAN)
- **Unidad de Trabajo:** UT1. Servicios de almacenamiento de objetos en la nube (Amazon S3)
- **Resultados de Aprendizaje asociados:**
    - **RA1.a:** Comprobación de operaciones de almacenamiento de objetos frente a requisitos técnicos de durabilidad y resiliencia.
    - **RA2.c:** Selección de región geográfica por latencia, coste, soberanía y tolerancia a fallos.
    - **RA2.d:** Aplicación de mecanismos de seguridad y cifrado en almacenamiento de objetos.
    - **RA2.g:** Configuración de parámetros de versionado y reglas de replicación multirregión.

---

## 1. Enlace al Laboratorio Oficial de AWS Skill Builder

Esta práctica se desarrollará de forma guiada en la plataforma **AWS Skill Builder**, accediendo al siguiente laboratorio práctico:

> 🔗 **Laboratorio en AWS Skill Builder:**  
> [**Implementing Multi-Region Backup with Amazon S3 Cross-Region Replication**](https://skillbuilder.aws/learn/NVQC5ZDTRE/implementing-multiregion-backup-with-amazon-s3-crossregion-replication/PAN1T8H3N7)

El laboratorio proporciona una cuenta de AWS efímera e interactiva donde dispondrás de los nombres preasignados para `SourceBucket`, `DestinationBucket`, `PrimaryRegion`, `SecondaryRegion` y el rol IAM `S3-CRR-Role`.

---

## 2. Resumen de Tareas y Flujo de Trabajo

El objetivo del laboratorio es implementar una arquitectura de respaldo multirregión basada en **Replicación entre Regiones (Cross-Region Replication - CRR)**, explorando sus diferentes niveles de alcance, filtros y comportamiento ante eliminaciones.

### Tarea 1: Creación y configuración de los depósitos de origen y destino
1. Crear el bucket de origen (`SourceBucket`) en la región principal (`PrimaryRegion`) y habilitar el **Control de versiones (Versioning)** en sus propiedades.
2. Cambiar en la consola a la región secundaria (`SecondaryRegion`) y crear el bucket de destino (`DestinationBucket`), asegurándote de habilitar también el **Control de versiones**.
3. Regresar el selector de consola a la región principal.

### Tarea 2: Habilitación de replicación CRR para todo el bucket
1. Subir el archivo `pre-crr.txt` al bucket origen antes de definir la regla de replicación.  
   *(Comprobarás que los objetos preexistentes **no** se replican automáticamente a menos que se use S3 Batch Replication)*.
2. En el bucket origen, pestaña **Administración**, crear la regla de replicación `crr-full-bucket`:
   - **Ámbito:** Aplicar a todos los objetos del bucket.
   - **Destino:** Especificar el bucket `DestinationBucket`.
   - **Rol IAM:** Seleccionar el rol existente `S3-CRR-Role`.
3. Subir el archivo `crr-bucket.txt` y verificar que este nuevo objeto sí se replica automáticamente en el bucket de destino.

---

### Tarea 3: Replicación de archivos cifrados (Modificación: KMS vs. SSE-S3)

En el paso 3 del laboratorio guiado se propone subir un archivo (`crr-encrypted.txt`) cifrado con una clave de **AWS KMS (SSE-KMS)** y observar que la replicación no ocurre por defecto.

!!! warning "El reto técnico de las claves AWS KMS entre regiones distintas"
    Las claves maestras de KMS (KMS keys) son **recursos estrictamente regionales**. Una clave creada en `us-east-1` no existe ni se puede utilizar directamente en `us-west-2` a menos que sea una clave multirregión y se configure un mapeo explícito de claves en la regla de replicación. Por este motivo, al replicar objetos cifrados con KMS entre regiones, si no se dispone de una clave KMS de destino adecuada y permisos de recifrado, la replicación falla o no se ejecuta.

#### Modificación requerida para la práctica:
Además de seguir los pasos guiados del laboratorio para observar la limitación con KMS, **realizaremos una prueba complementaria con el cifrado propio del servicio S3 (SSE-S3)**:

1. Sube un archivo de prueba (puedes llamarlo `crr-s3-encrypted.txt` o usar cualquier archivo de prueba).
2. En las opciones de subida, despliega la sección **Propiedades** -> **Cifrado del lado del servidor**:
   - Selecciona **Cifrado del lado del servidor con claves administradas por Amazon S3 (SSE-S3)** (`AES256`).
3. Completa la subida hacia el bucket de origen.
4. Accede al bucket de destino en la región secundaria y refresca la lista:  
   *(Comprobarás que con **SSE-S3** la replicación se realiza con éxito y de manera inmediata, ya que Amazon S3 gestiona las claves de cifrado internamente en cada región de forma transparente sin requerir gestión externa de claves).*

---

### Tarea 4: Configuración de replicación selectiva por carpeta (prefijo)
1. Crear una carpeta llamada `crr-test/` en el bucket de origen.
2. Eliminar la regla de replicación previa (`crr-full-bucket`).
3. Crear una nueva regla de replicación denominada `crr-folder-only`:
   - **Ámbito:** Limitar el alcance mediante prefijo.
   - **Prefijo:** `crr-test/`.
4. Probar la regla subiendo dos archivos:
   - `crr-folder-root.txt` en la raíz del bucket origen $\rightarrow$ **No se replica**.
   - `crr-folder.txt` dentro de la subcarpeta `crr-test/` $\rightarrow$ **Sí se replica** hacia el bucket destino respetando la estructura de carpetas.

---

### Tarea 5: Configuración de replicación selectiva por etiquetas (Tags)
1. Eliminar la regla de carpetas (`crr-folder-only`).
2. Crear una nueva regla de replicación denominada `crr-tag-only`:
   - **Ámbito:** Limitar el alcance por etiquetas.
   - **Etiqueta:** Clave `replicate`, Valor `yes`.
3. Probar la regla subiendo dos archivos:
   - `crr-no-tag.txt` (sin etiquetas) $\rightarrow$ **No se replica**.
   - `crr-tag.txt` añadiendo en la subida la etiqueta `replicate=yes` $\rightarrow$ **Sí se replica** al bucket destino.

---

### Tarea 6: Comportamiento ante la eliminación de objetos replicados
1. En el bucket de origen, eliminar el archivo replicado `crr-tag.txt`.
2. Acceder al bucket de destino en la región secundaria:  
   *(Observarás que `crr-tag.txt` **sigue existiendo intacto** en el bucket de destino. Por diseño de seguridad, S3 CRR no replica por defecto las solicitudes de eliminación ni los marcadores de borrado para evitar pérdidas accidentales o ataques en cascada).*

---

### Cuestionario final de evaluación (Knowledge Check)
Al terminar la práctica en la plataforma, completa el cuestionario interactivo de comprobación de conocimientos que aparece al final del laboratorio de AWS Skill Builder.

---

## 3. Entregables (Capturas Obligatorias)

Deberás presentar una memoria o documento de prácticas en PDF con las siguientes **9 evidencias numeradas**:

1. **Captura 1 (Tarea 1):** Configuración de versionado activo (*Bucket Versioning: Enabled*) tanto en el bucket de origen (`PrimaryRegion`) como en el bucket de destino (`SecondaryRegion`).

2. **Capturas 2a y 2b (Tarea 2):**
   - **2a:** Vista del bucket de **origen** mostrando los dos archivos existentes: `pre-crr.txt` (subido antes de activar la replicación) y `crr-bucket.txt` (subido después).
   - **2b:** Vista del bucket de **destino** mostrando únicamente `crr-bucket.txt`. La ausencia de `pre-crr.txt` evidencia que los objetos preexistentes antes de configurar la regla no se replican automáticamente.

3. **Capturas 3a y 3b (Tarea 3 — KMS y modificación SSE-S3):**
   - **3a:** Vista del bucket de **destino vacío** tras subir `crr-encrypted.txt` con cifrado **SSE-KMS** al origen. Este es el momento clave: la replicación **no se ha producido** porque las claves KMS son regionales y no se comparten entre regiones automáticamente.
   - **3b:** Vista del bucket de **destino** tras volver a subir el mismo archivo esta vez con cifrado **SSE-S3** (claves administradas por Amazon S3). El archivo aparece replicado correctamente, demostrando que con SSE-S3 la replicación multirregión funciona de forma transparente.

4. **Captura 4 (Tarea 4):** Vista del bucket de destino tras la prueba por prefijo, mostrando que la carpeta `crr-test/` contiene `crr-folder.txt`, mientras que en la raíz del bucket no existe `crr-folder-root.txt`.

5. **Captura 5 (Tarea 5):** Vista del bucket de destino tras la prueba por etiquetas, demostrando que únicamente se ha replicado `crr-tag.txt` (etiqueta `replicate: yes`) y que `crr-no-tag.txt` (sin etiqueta) no aparece en el destino.

6. **Capturas 6a y 6b (Tarea 6):**
   - **6a:** Vista del bucket de **origen** con la opción *Mostrar versiones (Show versions)* activa, donde se aprecia el **delete marker** colocado sobre `crr-tag.txt` como versión más reciente, sin que el objeto haya sido destruido físicamente.
   - **6b:** Vista del bucket de **destino** confirmando que `crr-tag.txt` sigue íntegro y accesible, sin ningún marcador de eliminación replicado.

7. **Captura 7 (Knowledge Check superado):** Pantalla final del laboratorio en AWS Skill Builder mostrando el mensaje **`Passed`** en el *Knowledge Check*.
