# Práctica 1.2: Alojamiento de un Sitio Web Estático en Amazon S3

- **Módulo:** Administración de Bases de Datos y Almacenamiento en la Nube (ABDAN)
- **Unidad de Trabajo:** UT1. Servicios de almacenamiento de objetos en la nube (Amazon S3)
- **Resultados de Aprendizaje asociados:**
    - **RA2.e:** Configuración de parámetros de visibilidad, acceso y seguridad.
    - **RA2.f:** Configuración de parámetros de acceso público mediante HTTP/HTTPS.

---

## 1. Objetivos de la Práctica

1. Comprender la arquitectura y las limitaciones del alojamiento de sitios web estáticos sobre almacenamiento de objetos.
2. Desplegar un sitio web funcional (HTML5, CSS3 y JavaScript del lado del cliente) en **Amazon S3**.
3. Configurar de forma segura el bloqueo de acceso público y redactar una **política de bucket (Bucket Policy)** en JSON que conceda permisos de solo lectura al público anónimo.
4. Identificar, diagnosticar y corregir el error común **HTTP 403 Forbidden**.
5. Practicar el protocolo de limpieza y vaciado de recursos para no incurrir en gastos involuntarios en el Learner Lab.

---

## 2. Preparación de los Archivos del Sitio Web

En tu equipo local, crea una carpeta de trabajo denominada `mi-sitio-s3` con tres archivos:

### `index.html`
```html
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sitio Web en Amazon S3 - ABDAN</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="card">
        <h1>¡Despliegue Exitoso en Amazon S3!</h1>
        <p>Esta página web estática está servida directamente desde un bucket de almacenamiento de objetos de AWS, sin servidores Apache o Nginx.</p>
        <button id="btnClick">Haz clic aquí</button>
        <div id="resultado" class="mensaje"></div>
    </div>
    <script src="script.js"></script>
</body>
</html>
```

### `style.css`
```css
body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    background: linear-gradient(135deg, #1e293b, #0f172a);
    color: #f8fafc;
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 100vh;
    margin: 0;
}
.card {
    background-color: #334155;
    padding: 2.5rem;
    border-radius: 12px;
    box-shadow: 0 10px 25px rgba(0,0,0,0.4);
    max-width: 550px;
    text-align: center;
}
button {
    background-color: #ff9900;
    color: #111;
    border: none;
    padding: 0.8rem 1.6rem;
    font-size: 1rem;
    font-weight: bold;
    border-radius: 6px;
    cursor: pointer;
    transition: background 0.3s;
}
button:hover {
    background-color: #ffaa22;
}
.mensaje {
    margin-top: 1.5rem;
    font-size: 1.1rem;
    color: #38bdf8;
}
```

### `script.js`
```javascript
document.getElementById('btnClick').addEventListener('click', () => {
    const ahora = new Date().toLocaleTimeString('es-ES');
    document.getElementById('resultado').innerText = 
        `Petición cliente procesada con éxito a las ${ahora} mediante JavaScript en el navegador.`;
});
```

Crea también un archivo opcional `404.html`:
```html
<!DOCTYPE html>
<html lang="es">
<head><title>Página No Encontrada</title></head>
<body style="font-family:sans-serif; text-align:center; padding-top:100px;">
    <h1>Error 404 - Recurso No Encontrado</h1>
    <p>El archivo solicitado no existe en este bucket de S3.</p>
</body>
</html>
```

---

## 3. Instrucciones Paso a Paso

### Paso 1: Creación del bucket para el sitio web

1. En la consola de S3, pulsa **Crear bucket**.
2. **Nombre del bucket:** `website-NOMBRE-APELLIDO-abdan` (debe ser único en el mundo).
3. **Región:** `us-east-1` (o la región de tu Learner Lab).
4. **Bloqueo de acceso público:** **Desmarca** la casilla *Bloquear todo el acceso público* y marca la casilla de verificación confirmando que reconoces que el bucket puede volverse público.
5. Pulsa **Crear bucket**.

### Paso 2: Subida de los archivos web

1. Entra en el bucket y pulsa **Cargar (Upload)**.
2. Arrastra y sube los 4 archivos creados (`index.html`, `style.css`, `script.js` y `404.html`).

### Paso 3: Habilitar el alojamiento de sitios web estáticos

1. Ve a la pestaña **Propiedades (Properties)** del bucket y baja hasta **Alojamiento de sitios web estáticos (Static website hosting)**.
2. Pulsa **Editar** y selecciona:
    - **Alojamiento de sitios web estáticos:** Habilitar.
    - **Tipo de alojamiento:** Alojar un sitio web estático.
    - **Documento de índice:** `index.html`.
    - **Documento de error:** `404.html`.
3. Pulsa **Guardar cambios**.
4. Copia la URL del punto de enlace generado (`http://<tu-bucket>.s3-website-us-east-1.amazonaws.com`).

### Paso 4: Comprobar el error HTTP 403 Forbidden y aplicar la Política de Bucket

1. Abre una ventana de tu navegador en **modo incógnito** e introduce la URL copiada.
2. Observarás un error **403 Forbidden**: Aunque el bucket permite el acceso público, sus objetos individuales siguen siendo privados.
3. Vuelve a la consola de S3, accede a la pestaña **Permisos (Permissions)** del bucket y baja hasta **Política de bucket (Bucket policy)**. Pulsa **Editar**.
4. Pega la siguiente directiva en formato JSON, **reemplazando** `TU-BUCKET-AQUI` por el nombre exacto de tu bucket:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::TU-BUCKET-AQUI/*"
    }
  ]
}
```

5. Pulsa **Guardar cambios**.
6. Recarga la página en la ventana en modo incógnito. La web debe cargar perfectamente mostrando los estilos CSS y respondiendo al botón de JavaScript.

---

## 4. Limpieza de Recursos (Clean-up)

Para evitar el consumo indeseado de créditos de laboratorio en AWS Academy:

1. Accede a la lista de buckets de S3 y selecciona tu bucket web.
2. Pulsa el botón **Vaciar (Empty)** y confirma la acción escribiendo `vaciar permanentemente`.
3. Una vez vaciado, selecciona de nuevo el bucket y pulsa **Eliminar (Delete)**, confirmando con el nombre del bucket.

---

## 5. Entregables

Presenta un informe técnico con:

1. La **URL pública** que tuvo tu sitio web durante la práctica.
2. **Captura de pantalla** del sitio web cargando correctamente en el navegador en modo incógnito con la consola de depuración web (F12) visible demostrando que los archivos `style.css` y `script.js` devuelven código `200 OK`.
3. **Pregunta de análisis:** Si quisiéramos asociar un dominio corporativo (ej. `www.micentro.es`) con certificado SSL (HTTPS) a este sitio web estático, ¿qué dos servicios adicionales de AWS necesitaríamos interponer y por qué el endpoint nativo de S3 no es suficiente?
