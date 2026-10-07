# Administración de Bases de Datos y Almacenamiento en la Nube (ABDAN)

Bienvenido a los apuntes y materiales didácticos del módulo **Administración de Bases de Datos y Almacenamiento en la Nube** (ABDAN), perteneciente al **Curso de Especialización en Recursos y Servicios en la Nube** impartido en el [IES Poeta Paco Mollá](https://iespacomolla.es/) de Petrer (Alicante).

**Profesor:** David Ortega Parrilla  
**Carga lectiva:** 5 horas semanales (150 horas lectivas en total)

---

## Presentación del Módulo

El propósito fundamental de este módulo formativo es capacitar al alumnado en la gestión, aprovisionamiento, seguridad, escalabilidad y optimización tanto de **sistemas de almacenamiento en la nube** (objetos, bloques y archivos en red) como de **sistemas gestores de bases de datos relacionales, clave-valor, documentales y memorias intermedias (caché)**, así como en los procesos de infraestructura híbrida, migración y procesamiento analítico de datos (OLAP).

La plataforma de nube pública de referencia a lo largo de todo el curso es **Amazon Web Services (AWS)**, a través de la plataforma educativa **AWS Academy (Learner Labs y Lab Projects)**, complementada puntualmente con otros servicios gestionados líderes en el sector (como MongoDB Atlas y Redis Cloud).

---


## Resultados de Aprendizaje (RA) y Criterios de Evaluación

El módulo evalúa 7 Resultados de Aprendizaje oficiales, con la siguiente ponderación porcentual en la calificación final:

| Resultado de Aprendizaje (RA) | Descripción | Ponderación |
| :--- | :--- | :---: |
| **RA1** | **Selecciona el tipo de almacenamiento** para los datos del sistema según requisitos funcionales y criterios de durabilidad, seguridad, fiabilidad, rendimiento y coste. | **5%** |
| **RA2** | **Administra sistemas de almacenamiento de objetos** en nube, configurando y monitorizando los mismos, para garantizar el almacenamiento, la seguridad digital, y los patrones de uso. | **10%** |
| **RA3** | **Administra sistemas de almacenamiento de ficheros** en nube, tanto en dispositivos de bloque como en sistemas de red (EBS, EFS, FSx), mediante consola, CLI, API e IaC. | **10%** |
| **RA4** | **Administra los sistemas de bases de datos** relacionales y NoSQL, garantizando el almacenamiento, la seguridad y el patrón de acceso más eficiente. | **45%** |
| **RA5** | **Gestiona los datos** desde el exterior y entre sistemas de almacenamiento y bases de datos, facilitando el flujo seguro y eficiente de información. | **10%** |
| **RA6** | **Administra la infraestructura de datos de nube híbrida** (Storage Gateway, VPN, enlaces dedicados) permitiendo la interoperabilidad y sincronización. | **10%** |
| **RA7** | **Administra sistemas de transformación y análisis de datos (OLAP)** (Redshift, Athena, Glue), garantizando retención, particionado y seguridad. | **10%**\* |

*\*Nota: El RA7 se encuentra vinculado curricularmente al periodo de formación en empresa.*

---

## Criterios de Calificación y Superación

### Instrumentos de evaluación

Cada Unidad de Trabajo integra dos instrumentos de evaluación principales:

- **Ejercicios y prácticas de laboratorio:** Realizados a lo largo de cada unidad y entregados mediante la plataforma oficial **Aules**.
- **Cuestionarios tipo test:** Pruebas teóricas y de resolución de supuestos al finalizar cada unidad formativa.

### Cálculo de la calificación por RA

Cada práctica y cuestionario está asociado de forma unívoca a uno o varios Criterios de Evaluación dentro de su respectivo RA:

> **Calificación por RA** = **85%** (Media de ejercicios prácticos) + **15%** (Media de cuestionarios test) 

!!! info "Requisitos de Superación del Módulo"

    1. Para superar el módulo es requisito indispensable obtener una calificación **igual o superior a 5,0 en todos y cada uno de los Resultados de Aprendizaje (RA1 a RA7)**.
    2. **Convocatoria ordinaria:** Se realizará una prueba específica de recuperación para aquellos RA que no hayan alcanzado la nota mínima. En esta convocatoria no se admitirán nuevas prácticas de los RA suspensos.
    3. **Convocatoria extraordinaria:** Los alumnos con RA pendientes realizarán un examen final de los RA no superados, manteniéndose las calificaciones de los RA ya aprobados en la convocatoria ordinaria.


---

## Estructura de Unidades de Trabajo (UT)

El temario del módulo está estructurado en 9 Unidades de Trabajo:

1. :material-cube-outline: **[UT1. Servicios de almacenamiento de objetos en la nube (Amazon S3)](UT1/01-introduccion.md)**
2. :material-harddisk: **UT2. Servicios de almacenamiento en bloque y sistemas de ficheros en red (Amazon EBS, EFS, FSx)**
3. :material-database: **UT3. Servicios administrados de bases de datos relacionales (Amazon RDS, Amazon Aurora)**
4. :material-key-variant: **UT4. Bases de datos clave-valor (Amazon DynamoDB)**
5. :material-file-document-outline: **UT5. Bases de datos basadas en documentos (Amazon DocumentDB / MongoDB Atlas)**
6. :material-memory: **UT6. Sistemas de memoria caché en bases de datos (Amazon ElastiCache / Redis)**
7. :material-lan-connect: **UT7. Infraestructura y administración de datos en nube híbrida (AWS Storage Gateway, VPN)**
8. :material-sync: **UT8. Transferencia, sincronización y migración de datos (AWS DMS, AWS DataSync)**
9. :material-chart-box-outline: **UT9. Sistemas de procesamiento analítico en línea - OLAP (Amazon Redshift, Athena, AWS Glue)**
