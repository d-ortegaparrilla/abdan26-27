# Administración de Bases de Datos y Almacenamiento en la Nube (ABDAN) 2026-2027

Materiales y apuntes del módulo **Administración de Bases de Datos y Almacenamiento en la Nube** (ABDAN), perteneciente al **Curso de Especialización en Recursos y Servicios en la Nube** en el [IES Poeta Paco Mollá](https://iespacomolla.es/) de Petrer.

## Tecnologías utilizadas

- [MkDocs](https://www.mkdocs.org/)
- [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/)
- Amazon Web Services (AWS Academy / Learner Labs)

## Despliegue local

Para previsualizar los apuntes en un servidor local de desarrollo:

```bash
# Crear y activar entorno virtual (opcional)
python3 -m venv .venv
source .venv/bin/activate

# Instalar dependencias
pip install -r requirements.txt

# Iniciar servidor de desarrollo
mkdocs serve
```

La documentación estará disponible en `http://127.0.0.1:8000/`.

## Despliegue en GitHub Pages

El proyecto incluye un flujo de trabajo de GitHub Actions (`.github/workflows/deploy.yml`) que compila y publica automáticamente la web en GitHub Pages ante cualquier `push` a la rama `main`.
# abdan26-27
