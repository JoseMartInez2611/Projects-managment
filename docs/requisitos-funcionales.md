# Requerimientos funcionales: seguimiento de proyectos de investigación multi-entregable (MVP)

| | |
| --- | --- |
| Versión | 0.3. Cambios sobre 0.2: código de registro por rol (D8), RF-AUT-07 a 10, RN-18 a 20, S1 reemplazada |
| Fecha | 2026-10-24 |
| Fuente | Historia de usuario "Gestión Integral y Seguimiento de Proyectos de Investigación Multi-Entregable (Roles: Estudiante, Docente, Tutor)" |
| Ejemplos | `Cronograma_brownie_objetivos_1_y_2.xlsx` y `TABLAS DE RESULTADOS OBTENIDOS EN PRUEBAS FISICOQU.docx` (hallazgos en la sección 14) |
| Uso | Insumo para: 1) modelo de datos, 2) definición de la API, 3) estructura modular |

## 1. Alcance

Plataforma web donde estudiantes registran y hacen seguimiento de un proyecto de investigación dividido en **5 entregables independientes**. El tutor consulta el avance en solo lectura. El docente retroalimenta y califica cada entregable.

El MVP cubre:

1. Autenticación y roles (Estudiante, Docente, Tutor).
2. Proyectos con información general única y participantes.
3. Cinco entregables por proyecto, cada uno con documento, cronograma importado con barra de progreso, resultados con gráficos interactivos y evaluación.

La HU se declara a sí misma como épica. La sección 11 propone cómo partirla.

## 2. Decisiones y supuestos

### 2.1 Decisiones confirmadas con el solicitante (2026-10-24)

| Id | Decisión |
| --- | --- |
| D1 | **Estructura:** 1 proyecto con información general única (título, encargados, línea de investigación, resumen, objetivos) más **5 entregables fijos**. Cada entregable tiene su propio documento, cronograma, avance, resultados/gráficos y calificación. |
| D2 | **Asignación:** el Estudiante crea el proyecto y elige tutor y docente entre los usuarios registrados. Puede agregar otros estudiantes. No hay rol Administrador en el MVP. |
| D3 | **Calificación:** escala 0.0 a 5.0 con un decimal. |
| D4 | **Cronograma (revisada tras ver los ejemplos):** el estudiante sube un **XLSX con la plantilla estándar** y el sistema **importa las actividades** (objetivo, actividad, semana de inicio y fin, observaciones, avance, estado). La fecha de inicio del cronograma se registra en la aplicación. La barra compara el avance real contra el esperado según las semanas. Reemplaza la versión inicial (archivo sin interpretar y un solo % manual). |
| D5 | **Cronograma por entregable.** Un entregable puede cubrir varios objetivos específicos: el archivo de ejemplo, con los objetivos 1 y 2, sería un solo entregable. |
| D6 | **Plantilla de resultados:** una sola plantilla en formato largo con columna opcional de réplica. Con réplicas el sistema calcula media ± desviación estándar y dibuja barras de error. |
| D7 | **Solo Excel y CSV para resultados.** No se extraen tablas de documentos Word. El estudiante copia sus tablas a la plantilla. |
| D8 | **Registro con código por rol.** Para crear una cuenta de cualquier rol (Estudiante, Tutor o Docente) hay que ingresar el código de registro de ese rol, que se pide en un modal al enviar el formulario. Hay **un código compartido por rol**, guardado en la configuración del servidor y no en la base de datos. Reemplaza el registro libre de rol. |

### 2.2 Supuestos del redactor (corregir los que no apliquen)

| Id | Supuesto |
| --- | --- |
| S1 | Los códigos de registro son alfanuméricos y no distinguen mayúsculas. Se rotan a mano: se cambia la configuración y se reinicia el servicio. **Riesgo aceptado en el MVP:** si un código se filtra, cualquiera puede registrarse en ese rol hasta que se rote, y no se sabe quién lo usó. Los usuarios ya creados conservan su cuenta. |
| S2 | Un proyecto tiene 1 o más estudiantes, exactamente 1 tutor y exactamente 1 docente. Un estudiante puede estar en varios proyectos. Un usuario tiene un solo rol. |
| S3 | Tutor y docente solo ven los proyectos donde están asignados. Quien no participa en un proyecto recibe 404, para no revelar que existe. Las acciones prohibidas a un participante devuelven 403. |
| S4 | Estudiantes y tutor ven los comentarios y la calificación del docente en solo lectura. Sin eso la retroalimentación no sirve. |
| S5 | Para reconciliar el Escenario 1 con D1: la información general se muestra y edita desde el **encabezado del proyecto**, visible en las 5 sub-pestañas. Editarla no modifica ningún entregable. |
| S6 | La HU usa "documento base" (Escenario 1) y "documento final" (descripción). Se modela como **un documento por entregable**. |
| S7 | Un documento y un cronograma vigentes por entregable. Reemplazar borra el anterior, sin versionado. Los archivos de resultados son varios por entregable. |
| S8 | El bloqueo optimista protege también el cronograma de cada entregable. Cualquier cambio (fecha de inicio, actividades, avance, estado) incrementa la versión del entregable. |
| S9 | Estado "Atrasado" si el avance real está más de 10 puntos porcentuales por debajo del esperado. |
| S10 | Formatos y límites de peso de la sección RF-ARC, y longitudes máximas de campos de texto. Todos configurables. |
| S11 | Sin recuperación de contraseña en el MVP. |
| S12 | El avance y el estado de cada actividad se editan **dentro de la aplicación**. Los valores iniciales salen de las columnas "Avance %" y "Estado" del archivo. Volver a importar el archivo los sobrescribe, con aviso previo. |
| S13 | Avance real y esperado se ponderan por la duración de cada actividad en semanas. "Hoy" se calcula en la zona horaria `America/Bogota`. |

## 3. Roles y permisos

Participante = usuario asignado al proyecto (estudiante miembro, tutor o docente del proyecto).

| Acción | Estudiante | Tutor | Docente |
| --- | :---: | :---: | :---: |
| Crear proyecto | ✔ | ✖ | ✖ |
| Ver proyecto, entregables, cronogramas, barras y gráficos | ✔ | ✔ | ✔ |
| Ver comentarios y calificación | ✔ | ✔ | ✔ |
| Editar información general y participantes | ✔ | ✖ | ✖ |
| Subir o reemplazar documento y cronograma | ✔ | ✖ | ✖ |
| Editar fecha de inicio del cronograma, avance y estado de actividades | ✔ | ✖ | ✖ |
| Subir o eliminar resultados | ✔ | ✖ | ✖ |
| Descargar archivos | ✔ | ✔ | ✔ |
| Registrar comentarios y calificación | ✖ | ✖ | ✔ |

Todo lo no listado como ✔ debe ser rechazado por el backend, no solo ocultado en la interfaz.

## 4. Requerimientos funcionales

Prioridad: **M** = Must (MVP), **S** = Should, **C** = Could. Origen: Esc. = escenario de la HU, Flujo = caso alternativo, Dep. = nota de dependencias, Ejemplo = documentos de ejemplo.

### 4.1 Autenticación y roles (RF-AUT)

| Id | Requerimiento | Prio | Origen |
| --- | --- | :---: | --- |
| RF-AUT-01 | El sistema permite registrarse con nombre completo, correo (único sin distinguir mayúsculas), contraseña de al menos 8 caracteres, rol (Estudiante, Docente o Tutor) y el código de registro de ese rol (RF-AUT-07 a 10). | M | Dep., D8 |
| RF-AUT-02 | El sistema permite iniciar sesión con correo y contraseña y devuelve un token de acceso que incluye el **rol de forma explícita**. | M | Dep. |
| RF-AUT-03 | El token tiene expiración. Si es inválido o venció, el backend responde 401 y el frontend redirige al login. | M | Dep. |
| RF-AUT-04 | El backend autoriza cada petición por rol **y** por pertenencia al proyecto. No depende de que el frontend oculte controles. | M | Esc. 4, 5, Flujo 4 |
| RF-AUT-05 | El frontend muestra u oculta formularios de edición, botones de carga y la sección de calificación según el rol del token. | M | Dep. |
| RF-AUT-06 | El sistema expone los datos del usuario autenticado (nombre, correo, rol) y permite cerrar sesión. | M | Dep. |
| RF-AUT-07 | Al enviar el formulario de registro, el sistema abre un modal que pide el **código de registro** del rol elegido. El título nombra el rol (ej. "Código de acceso para Estudiantes"). | M | D8 |
| RF-AUT-08 | El backend compara el código con el configurado para ese rol, sin distinguir mayúsculas ni espacios en los extremos y en tiempo constante. La cuenta se crea solo si coincide. Si no, el modal muestra "Código incorrecto" sin revelar cuál es el correcto. | M | D8 |
| RF-AUT-09 | No se aceptan más de 5 intentos fallidos en cualquier ventana de 15 minutos por correo o por IP. Superado el límite, el sistema rechaza los nuevos intentos e indica cuánto falta para reintentar. | M | D8 |
| RF-AUT-10 | Hay un código por rol, leído de la configuración del servidor. Un rol sin código configurado no admite registros. | M | D8 |


### 4.2 Proyectos y participantes (RF-PRY)

| Id | Requerimiento | Prio | Origen |
| --- | --- | :---: | --- |
| RF-PRY-01 | Un Estudiante crea un proyecto indicando título, tutor y docente. Queda como estudiante participante. Al crearlo se generan automáticamente los 5 entregables vacíos. | M | D1, D2 |
| RF-PRY-02 | El sistema lista usuarios filtrando por rol (Tutor, Docente, Estudiante) para asignarlos. Solo expone nombre y correo. | M | D2 |
| RF-PRY-03 | Un estudiante participante puede agregar o quitar estudiantes del proyecto. Debe quedar siempre al menos uno. | M | D2, Esc. 1 |
| RF-PRY-04 | Un estudiante participante puede reasignar el tutor y el docente. | M | Esc. 1 |
| RF-PRY-05 | "Mis proyectos" lista los proyectos donde el usuario participa (como estudiante, tutor o docente), con título, encargados y avance global. | M | Esc. 4, 5 |
| RF-PRY-06 | El detalle del proyecto muestra la información general y un resumen de los 5 entregables (avance y calificación). | M | Esc. 1 |
| RF-PRY-07 | El avance global es el promedio simple del avance de los 5 entregables, calculado por el sistema. Un entregable sin cronograma cuenta como 0. | S | Esc. 2 |

### 4.3 Información general del proyecto (RF-INF)

| Id | Requerimiento | Prio | Origen |
| --- | --- | :---: | --- |
| RF-INF-01 | Los estudiantes pueden ingresar y editar título, línea de investigación, resumen y objetivo general. Solo título es obligatorio. | M | Esc. 1 |
| RF-INF-02 | Los objetivos específicos son una lista ordenada: agregar, editar, eliminar y reordenar. | M | Esc. 1 |
| RF-INF-03 | Los encargados (estudiantes, tutor, docente) se muestran en el encabezado del proyecto. | M | Esc. 1 |
| RF-INF-04 | La información general se muestra en el encabezado de las 5 sub-pestañas. Editarla no modifica datos de los entregables. | M | S5 |
| RF-INF-05 | **Bloqueo optimista:** cada guardado envía la versión que el usuario vio. Si ya cambió, el sistema **no sobrescribe**, conserva los cambios del primero y responde 409 con el estado actual. La interfaz avisa quién actualizó y cuándo, y deja al segundo reaplicar sus cambios. | M | Flujo 3 |
| RF-INF-06 | Título, línea, resumen, objetivos y encargados se versionan como una sola unidad para el bloqueo. | M | Flujo 3 |

### 4.4 Entregables y documento (RF-ENT)

| Id | Requerimiento | Prio | Origen |
| --- | --- | :---: | --- |
| RF-ENT-01 | Cada proyecto tiene exactamente 5 entregables numerados 1 a 5. No se agregan ni se eliminan. | M | D1 |
| RF-ENT-02 | Cada entregable tiene nombre opcional editable. Por defecto "Entregable n". | S | D1 |
| RF-ENT-03 | El estudiante sube un documento por entregable. Reemplazar sustituye el anterior. Se muestra nombre, tamaño, fecha y autor. | M | Esc. 1 |
| RF-ENT-04 | **Independencia:** operar sobre un entregable no lee ni modifica datos de otro. | M | Esc. 1 |
| RF-ENT-05 | El bloqueo optimista de RF-INF-05 aplica también al cronograma del entregable (S8). | S | S8 |

### 4.5 Cronograma y barra de progreso (RF-CRO)

| Id | Requerimiento | Prio | Origen |
| --- | --- | :---: | --- |
| RF-CRO-01 | El estudiante sube un cronograma en XLSX con la plantilla estándar (sección 6.1). El sistema importa las actividades. | M | D4 |
| RF-CRO-02 | El estudiante registra la **fecha de inicio del cronograma**. El sistema deriva las fechas de cada actividad a partir de ella y de las semanas. **No lee fechas del archivo.** | M | D4, Ejemplo |
| RF-CRO-03 | Al importar, el sistema valida la estructura. Si falla, no importa nada (todo o nada) y muestra errores con fila y columna y un enlace a la plantilla. | M | Flujo 1 |
| RF-CRO-04 | El sistema muestra las actividades agrupadas por objetivo: actividad, semanas, fechas derivadas, avance y estado. | M | Esc. 2 |
| RF-CRO-05 | El estudiante edita el avance (0 a 100) y el estado de cada actividad dentro de la aplicación. Los valores iniciales salen del archivo. | M | Esc. 2, S12 |
| RF-CRO-06 | **Barra de progreso del entregable:** el relleno es el avance real y un marcador indica el avance esperado hoy. Fórmulas en la sección 6.1. | M | Esc. 2, D4 |
| RF-CRO-07 | La barra muestra un estado: **Completado** (real = 100), **En tiempo** (real ≥ esperado − 10 pts), **Atrasado** (real < esperado − 10 pts), **Sin cronograma** (no hay actividades) o **Sin fecha de inicio** (no se puede calcular lo esperado, se muestra solo el avance real). | M | S9 |
| RF-CRO-08 | Volver a subir un cronograma reemplaza todas las actividades. Antes de confirmar, el sistema advierte que el avance y el estado editados en la aplicación se sustituyen por los del archivo. | M | S12 |
| RF-CRO-09 | El sistema ofrece la plantilla de cronograma descargable (XLSX, con ejemplo). | M | Dep. |
| RF-CRO-10 | Al guardar cualquier cambio, la barra y la tabla se actualizan sin recargar la página. | M | Esc. 2 |
| RF-CRO-11 | Vista tipo Gantt semanal de solo lectura: cuadrícula de semanas con las actividades marcadas. | S | Ejemplo |
| RF-CRO-12 | Barra de progreso por objetivo, además de la del entregable. | C | Ejemplo |
| RF-CRO-13 | Historial de cambios de avance (fecha, valor, usuario, actividad). | C | Esc. 2 |

### 4.6 Resultados y gráficos interactivos (RF-RES)

| Id | Requerimiento | Prio | Origen |
| --- | --- | :---: | --- |
| RF-RES-01 | El estudiante carga uno o varios archivos de resultados (CSV o XLSX) por entregable. | M | Esc. 3, D7 |
| RF-RES-02 | El sistema ofrece la **plantilla estándar** descargable (CSV y XLSX) con instrucciones y ejemplos. Estructura en la sección 6.2. | M | Esc. 3, Dep. |
| RF-RES-03 | Al cargar, el sistema valida formato, encabezados, tipos de dato, unicidad de (serie, x, réplica), una sola unidad por serie y límites de filas. Rechaza unidades escritas dentro de la celda de `y` (ej. `2,70 %`). El archivo se guarda **solo si pasa toda la validación** (todo o nada). | M | Flujo 1, Ejemplo |
| RF-RES-04 | Si la validación falla, el sistema muestra un mensaje claro con el formato requerido, la estructura esperada, un enlace a la plantilla y hasta 10 errores concretos con fila y columna. | M | Flujo 1 |
| RF-RES-05 | Por cada archivo válido se genera automáticamente un gráfico interactivo en la sub-pestaña del entregable. Mínimo: tooltip al pasar el cursor, mostrar u ocultar series desde la leyenda y barras de error cuando hay réplicas. | M | Esc. 3 |
| RF-RES-06 | El usuario puede cambiar el tipo de gráfico (línea, barras o dispersión). Por defecto: `x` fecha o numérica → línea, `x` texto → barras agrupadas. | S | Esc. 3 |
| RF-RES-07 | Los datos validados persisten: al reabrir la pestaña el gráfico se dibuja sin volver a subir el archivo. | M | Esc. 3 |
| RF-RES-08 | El estudiante puede eliminar o reemplazar un archivo de resultados. El gráfico asociado desaparece o se regenera. | M | Esc. 3 |
| RF-RES-09 | Cada conjunto de resultados tiene un título, por defecto el nombre del archivo, editable. | S | Esc. 3 |
| RF-RES-10 | Tabla resumen junto al gráfico: por serie y valor de `x`, la media, la desviación estándar y el número de réplicas (n). | S | Ejemplo |
| RF-RES-11 | Los números se aceptan con coma o punto decimal (`3,06` y `3.06`). | M | Ejemplo |
| RF-RES-12 | Una celda vacía en `y`, o con `NA` o `No válido`, es un dato faltante. Se excluye de los cálculos y el sistema muestra cuántos valores se excluyeron. | M | Ejemplo |
| RF-RES-13 | Si el archivo trae réplicas, el sistema calcula media y **desviación estándar muestral (n − 1)** por (serie, x), dibuja barras de error y muestra n. Con n = 1 no se dibuja barra de error. | M | D6, Ejemplo |

### 4.7 Evaluación del docente (RF-EVA) y vista Tutor (RF-TUT)

| Id | Requerimiento | Prio | Origen |
| --- | --- | :---: | --- |
| RF-EVA-01 | Cada entregable tiene una sección "Evaluación". Todos los participantes la ven. Solo el docente asignado ve los controles para escribir. | M | Esc. 5 |
| RF-EVA-02 | El docente registra comentarios de retroalimentación: texto de hasta 2000 caracteres, varios por entregable, en orden cronológico con autor y fecha. En el MVP no se editan ni se borran. | M | Esc. 5 |
| RF-EVA-03 | El docente asigna o actualiza la calificación del entregable, de 0.0 a 5.0 con un decimal. Hay una calificación vigente por entregable. Actualizar la sobrescribe y registra la fecha. | M | Esc. 5, D3 |
| RF-EVA-04 | Un entregable sin calificación muestra "Sin calificar". | M | Esc. 5 |
| RF-EVA-05 | Si un estudiante intenta entrar por URL a la sección de calificación del docente, el sistema responde **403** y lo redirige a su vista del entregable con un mensaje. | M | Flujo 4 |
| RF-EVA-06 | El docente ve todo el resto del proyecto en solo lectura. No puede editar contenido, subir archivos ni cambiar participantes. | M | Esc. 5 |
| RF-TUT-01 | El tutor ve información, cronogramas, barras y gráficos de las 5 sub-pestañas de sus proyectos asignados. El backend rechaza con 403 cualquier edición, carga o calificación. | M | Esc. 4 |

### 4.8 Archivos (RF-ARC)

| Id | Requerimiento | Prio | Origen |
| --- | --- | :---: | --- |
| RF-ARC-01 | Tipos permitidos: documento PDF o DOCX; cronograma XLSX; resultados CSV o XLSX. Un DOCX no se acepta como resultados (D7). Se valida por extensión **y** por contenido real. | M | S10, D7 |
| RF-ARC-02 | Límites de peso (configurables): documento 25 MB, cronograma 10 MB, resultados 10 MB. Si se excede, la carga se aborta sin guardar nada y el mensaje indica el límite máximo permitido. | M | Flujo 2 |
| RF-ARC-03 | El cliente valida tipo y peso antes de enviar. El servidor valida siempre, sin confiar en el cliente. | M | Flujo 2 |
| RF-ARC-04 | La descarga de archivos requiere ser participante del proyecto. | M | Esc. 4 |
| RF-ARC-05 | Reemplazar un archivo elimina el anterior. Una carga fallida no deja archivos huérfanos ni estados a medias. | M | S7 |

### 4.9 Interfaz y navegación (RF-UI)

| Id | Requerimiento | Prio | Origen |
| --- | --- | :---: | --- |
| RF-UI-01 | La vista del proyecto tiene 5 sub-pestañas (Tab navigation). Cambiar de pestaña no recarga la página completa. | M | Notas UI |
| RF-UI-02 | Cada pestaña carga sus datos y guarda por separado, sin afectar a las demás. | M | Esc. 1 |
| RF-UI-03 | La URL refleja el proyecto y la pestaña activa, para poder enlazar directamente. | S | Notas UI |
| RF-UI-04 | Advertencia al cambiar de pestaña o salir con cambios sin guardar. | S | Esc. 1 |
| RF-UI-05 | Mensajes de éxito y error claros, en español. | M | Flujos 1–4 |
| RF-UI-06 | Indicador de estado por pestaña (avance, calificada o sin calificar). | C | Esc. 2, 5 |

## 5. Reglas de negocio

| Id | Regla |
| --- | --- |
| RN-01 | Un proyecto tiene 1 o más estudiantes, exactamente 1 tutor y exactamente 1 docente. |
| RN-02 | El tutor y el docente asignados deben tener ese rol. Un usuario tiene un único rol. |
| RN-03 | Un proyecto tiene siempre 5 entregables, numerados 1 a 5. |
| RN-04 | La calificación va de 0.0 a 5.0 con un decimal. Solo la asigna el docente asignado al proyecto. |
| RN-05 | El avance de una actividad es un número de 0 a 100. El avance del entregable se calcula, no se escribe. |
| RN-06 | Cada actividad cumple `Sem. inicio ≥ 1` y `Sem. fin ≥ Sem. inicio`. |
| RN-07 | El estudiante no comenta ni califica. El tutor nunca escribe. El docente nunca edita contenido del proyecto. |
| RN-08 | Un usuario solo accede a proyectos donde participa. |
| RN-09 | Cada guardado exitoso de un recurso con bloqueo optimista incrementa su versión. |
| RN-10 | Cambiar el docente no borra comentarios ni calificaciones anteriores, que conservan su autor. |
| RN-11 | Un archivo de resultados o un cronograma se persiste solo si pasa toda la validación. |
| RN-12 | No se calcula nota definitiva del proyecto en el MVP. |
| RN-13 | Estado de actividad ∈ {Pendiente, En proceso, Finalizada, Reprogramada}. Una actividad `Finalizada` tiene avance 100, y avance 100 implica `Finalizada`. |
| RN-14 | La fecha de una actividad se deriva, no se guarda: inicio = fecha de inicio del cronograma + 7 × (Sem. inicio − 1), fin = fecha de inicio + 7 × Sem. fin − 1. |
| RN-15 | En resultados, la combinación (serie, x, réplica) es única dentro de un archivo. Sin columna de réplica, (serie, x) es único. |
| RN-16 | Cada serie tiene una sola unidad. Mediciones con unidades distintas van en archivos separados. |
| RN-17 | El sistema valida la **estructura** de los datos, no su plausibilidad científica. |
| RN-18 | El rol se fija al registrarse, con el código de ese rol, y no se puede cambiar después. |
| RN-19 | Hay un código de registro por rol, guardado en la configuración del servidor y no en la base de datos. Un rol sin código configurado no admite registros. |
| RN-20 | Máximo 5 intentos fallidos de código en una ventana de 15 minutos, por correo o por IP. |

## 6. Plantillas estándar

### 6.1 Cronograma (XLSX)

El sistema lee la **primera hoja**. Busca la fila de encabezados entre las primeras 20 filas: la que contiene "Actividad", "Sem. inicio" y "Sem. fin". Los encabezados no distinguen mayúsculas ni acentos.

| Columna | Obligatoria | Tipo | Descripción |
| --- | :---: | --- | --- |
| `Objetivo` | No | Texto, máx. 100 | Agrupa actividades (ej. "Objetivo específico 1"). Vacío = "Sin objetivo". |
| `Actividad` | Sí | Texto, máx. 300 | Nombre de la actividad. |
| `Sem. inicio` | Sí | Entero ≥ 1 | Semana de inicio, relativa al inicio del cronograma. |
| `Sem. fin` | Sí | Entero ≥ `Sem. inicio` | Semana de fin. |
| `Observaciones` | No | Texto, máx. 500 | |
| `Avance %` | No | Número 0 a 100 | Vacío = 0. |
| `Estado` | No | Pendiente, En proceso, Finalizada o Reprogramada | Vacío = Pendiente. |

**Reglas de lectura**

- Las demás columnas se ignoran: fechas de inicio y fin, cuadrícula semanal, fórmulas de presentación.
- Las filas sin `Actividad` se ignoran (notas, separadores).
- Hasta 200 actividades y 104 semanas.
- Las celdas de las columnas leídas deben tener valor, no una fórmula sin resultado guardado.
- La fecha de inicio **no se lee del archivo**: se registra en la aplicación (RF-CRO-02).

**Cálculo de la barra** (S13), para cada actividad `i` con `dur_i = Sem. fin − Sem. inicio + 1`:

```
esperado_i = clamp((hoy − fecha_inicio_i + 1) / (7 × dur_i), 0, 1) × 100
avance_real     = Σ(dur_i × avance_i)   / Σ dur_i
avance_esperado = Σ(dur_i × esperado_i) / Σ dur_i
```

El archivo de ejemplo `Cronograma_brownie_objetivos_1_y_2.xlsx` se importaría sin cambios: 17 actividades, 2 objetivos, semanas 1 a 16, encabezados en la fila 6. Sus fechas absolutas y la celda B3 se ignoran.

### 6.2 Resultados (CSV o XLSX)

Formato **largo**: una fila por medición. CSV en UTF-8 con separador coma, o XLSX (se lee la primera hoja). Los encabezados no distinguen mayúsculas.

| Columna | Obligatoria | Tipo | Descripción |
| --- | :---: | --- | --- |
| `serie` | Sí | Texto, máx. 100 | Muestra o variable (ej. "Harina de lenteja"). Cada valor distinto es una serie. |
| `x` | Sí | Número, fecha ISO `AAAA-MM-DD` o texto | Eje X: tiempo, parámetro, tratamiento. Mismo tipo en todo el archivo. |
| `y` | Sí | Número, coma o punto decimal | Valor medido, **sin unidad dentro de la celda**. Vacío, `NA` o `No válido` = dato faltante. |
| `replica` | No | Texto o entero, máx. 20 | Identificador de la réplica. Si hay réplicas, se agregan por (serie, x). |
| `unidad` | No | Texto, máx. 20 | Unidad de `y` para la serie. |

**Límites:** hasta 10 000 filas y 20 series por archivo.

**Con réplicas** el sistema calcula media y desviación estándar muestral (n − 1) por (serie, x). Esto reproduce lo que el estudiante hoy calcula a mano: para L* de la harina de arroz, las réplicas 51,51 / 39,68 / 44,13 dan 45,11 ± 5,98, igual que la tabla de colorimetría del ejemplo.

Ejemplo sin réplicas (curva de humedad):

```csv
serie,x,y,replica,unidad
Harina de lenteja,1,"3,06",,%
Harina de lenteja,2,"4,54",,%
Harina de arroz,1,"3,40",,%
Harina de arroz,2,"5,00",,%
```

Ejemplo con réplicas (colorimetría):

```csv
serie,x,y,replica,unidad
Arroz,L*,51.51,1,
Arroz,L*,39.68,2,
Arroz,L*,44.13,3,
Arroz,a*,0.10,1,
Arroz,a*,0.03,2,
Arroz,a*,-0.12,3,
```

**Gráfico por defecto:** `x` fecha o numérica → línea. `x` texto → barras agrupadas. Con réplicas, las barras o puntos llevan barras de error ±DE. Dispersión disponible cuando `x` es numérica.

## 7. Flujos alternativos y errores

Los códigos HTTP son orientativos. Se fijan al definir la API.

| Caso | Comportamiento esperado | HTTP |
| --- | --- | :---: |
| Resultados con formato incorrecto o datos corruptos (ej. PDF en lugar de CSV/XLSX, texto en `y`, unidad dentro de la celda) | No se guarda. Mensaje con formato, estructura requerida, enlace a plantilla y errores concretos (RF-RES-04). | 422 |
| Resultados con datos faltantes (`NA`, `No válido`, vacío) | Se guarda. Se excluyen de los cálculos y se avisa cuántos (RF-RES-12). | 201 |
| Cronograma sin las columnas requeridas o con semanas inválidas | No se importa nada. Errores con fila y columna (RF-CRO-03). | 422 |
| Tipo de archivo no permitido (documento, cronograma o resultados) | Rechazo con los tipos aceptados. | 415 |
| Archivo supera el límite de peso | Aborta la carga y notifica el máximo permitido (RF-ARC-02). | 413 |
| Dos estudiantes editan la información general a la vez | Se conservan los cambios del primero. Al segundo se le notifica y se le muestra el estado actual (RF-INF-05). | 409 |
| Dos estudiantes editan el cronograma del mismo entregable a la vez | Igual que arriba, sobre la versión del entregable (RF-ENT-05). | 409 |
| Estudiante accede por URL a la calificación del docente | Acceso denegado y redirección a su vista (RF-EVA-05). | 403 |
| Tutor o docente intenta una escritura no permitida | Rechazo. | 403 |
| Token ausente, inválido o vencido | Redirección al login. | 401 |
| Código de registro incorrecto | No se crea la cuenta. El modal muestra "Código incorrecto" (RF-AUT-08). | 422 |
| Demasiados intentos fallidos de código | Rechazo con el tiempo que falta para reintentar (RF-AUT-09). | 429 |
| Proyecto o entregable inexistente, o sin participación | No se revela su existencia. | 404 |

## 8. Insumos para el modelo de datos (conceptual, no es el diseño final)

| Entidad | Atributos clave | Relaciones y restricciones |
| --- | --- | --- |
| `usuario` | nombre, correo (único, sin distinguir mayúsculas), hash de contraseña, rol, fecha de creación | Rol ∈ {estudiante, docente, tutor}. |
| `proyecto` | título, línea de investigación, resumen, objetivo general, **versión**, creado por, actualizado por y fecha | 1 tutor y 1 docente (FK a `usuario`). Tiene 5 `entregable` y N estudiantes. |
| `proyecto_estudiante` | proyecto, usuario | N:M. Mínimo 1 por proyecto. |
| `objetivo_especifico` | proyecto, orden, descripción | Orden único por proyecto. |
| `entregable` | proyecto, número 1–5, nombre, **fecha de inicio del cronograma** (nullable), **versión** | Único (proyecto, número). El avance **se calcula**, no se guarda. |
| `actividad_cronograma` | entregable, orden, objetivo (texto), actividad, sem. inicio, sem. fin, observaciones, avance 0–100, estado | Orden único por entregable. CHECK de semanas, rango de avance, enum de estado y `Finalizada ⇔ 100`. Se reemplazan todas al reimportar. |
| `archivo` | entregable, tipo ∈ {documento, cronograma, resultados}, nombre original, tipo MIME, tamaño, clave de almacenamiento, subido por, fecha | Un documento y un cronograma vigentes por entregable. N resultados. |
| `conjunto_resultados` | archivo, título, número de filas, tipo de `x`, tiene réplicas, valores faltantes | 1:1 con un `archivo` de tipo resultados. |
| `resultado_punto` | conjunto, serie, x, y (nullable = faltante), réplica (nullable), unidad | Guarda las **mediciones individuales**. Media y DE se calculan al leer. Único (conjunto, serie, x, réplica), con `NULLS NOT DISTINCT` (PostgreSQL 15+). Alternativa: JSONB. A decidir al diseñar la BD. |
| `comentario` | entregable, docente, texto, fecha | Solo inserción en el MVP. |
| `calificacion` | entregable, docente, nota, fecha de actualización | Única por entregable. CHECK 0.0 ≤ nota ≤ 5.0. |
| `intento_registro` | correo (en minúsculas), IP, rol, fecha | Solo guarda intentos **fallidos** de código. Sin FK a `usuario`: el correo puede no existir aún. Se consulta por ventana de 15 minutos y se purga lo antiguo. |
| `historial_avance` (C) | actividad, valor, usuario, fecha | Solo si se implementa RF-CRO-13. |

## 9. Requerimientos no funcionales que condicionan el diseño

- **Seguridad:** contraseñas con hash robusto (argon2id o bcrypt). Token firmado con expiración. Autorización por objeto en cada endpoint. El nombre de archivo del usuario nunca se usa como ruta de almacenamiento. Los XLSX subidos se leen sin ejecutar macros ni resolver vínculos externos. Los códigos de registro viven solo en la configuración del servidor, se comparan en tiempo constante y nunca aparecen en respuestas ni en registros. HTTPS en el despliegue real.
- **Almacenamiento:** archivos en volumen de disco detrás de una interfaz reemplazable. Metadatos en PostgreSQL.
- **Auditoría mínima:** fecha de creación y de actualización, y usuario que actualizó, en proyecto y entregable.
- **Rendimiento orientativo:** gráficos de hasta 10 000 filas se dibujan en menos de 2 s. El cambio de pestaña se siente inmediato con datos ya cargados.
- **Idioma:** interfaz y mensajes en español.

## 10. Fuera de alcance del MVP

Notificaciones por correo o en la aplicación. Chat. Versionado de archivos. Edición colaborativa en tiempo real. Rol Administrador y gestión de usuarios. Recuperación de contraseña. Inicio de sesión con SSO u OAuth. Rúbricas de evaluación. Nota definitiva del proyecto. Edición o borrado de comentarios. Eliminar o archivar proyectos. Exportar informes. Varios roles por usuario. Extraer tablas de documentos Word (D7). Leer fechas absolutas del cronograma. Validar la plausibilidad científica de los datos. Códigos de registro individuales o de un solo uso. Pantalla para administrar o rotar los códigos (se rotan cambiando la configuración).

## 11. Descomposición propuesta en historias

Orden recomendado, cada una entrega algo demostrable. Los RF-UI aplican de forma transversal.

| Historia | Contenido | Requerimientos |
| --- | --- | --- |
| HU1: Autenticación y roles | Registro con código por rol, login con rol en el token, autorización por rol y pertenencia. | RF-AUT-01 a 10 |
| HU2: Proyectos e información general | Crear proyecto, participantes, edición con bloqueo optimista, listado. | RF-PRY, RF-INF |
| HU3: Entregables, documento y archivos | 5 entregables, documento base, límites y validación de archivos. | RF-ENT, RF-ARC |
| HU4: Cronograma y progreso | Plantilla, importación, actividades, avance, barra de progreso. | RF-CRO |
| HU5: Resultados y gráficos | Plantilla, validación, réplicas, persistencia y gráficos interactivos. | RF-RES |
| HU6: Evaluación y vista Tutor | Comentarios, calificación, solo lectura para tutor y docente. | RF-EVA, RF-TUT |

## 12. Trazabilidad con los escenarios de la HU

| Escenario / flujo | Requerimientos |
| --- | --- |
| Esc. 1: información y entregables independientes | RF-INF-01 a 04, RF-ENT-03, RF-ENT-04, RF-UI-02 |
| Esc. 2: cronograma y barra de progreso | RF-CRO-01 a 10 |
| Esc. 3: resultados y gráficos | RF-RES-01 a 13 |
| Esc. 4: Tutor solo lectura | RF-TUT-01, RF-AUT-04, RF-AUT-05 |
| Esc. 5: evaluación del Docente | RF-EVA-01 a 04, RF-EVA-06 |
| Flujo: fallo en gráficos | RF-RES-03, RF-RES-04, RF-RES-12, RF-CRO-03 |
| Flujo: archivos pesados | RF-ARC-02, RF-ARC-03 |
| Flujo: edición simultánea | RF-INF-05, RF-INF-06, RF-ENT-05 |
| Flujo: acceso no autorizado | RF-EVA-05, RF-AUT-04 |
| Notas: UI modular | RF-UI-01, RF-UI-03 |
| Notas: token con rol | RF-AUT-02, RF-AUT-05 |
| Registro con rol validado (D8) | RF-AUT-01, RF-AUT-07 a 10 |

## 13. Pendientes (con el valor por defecto asumido)

| Pregunta | Valor por defecto |
| --- | --- |
| ¿Cada cuánto se rota el código de cada rol? | A mano: al filtrarse o al iniciar cada periodo académico. Se cambia la configuración y se reinicia el servicio. |
| ¿Quién entrega los códigos a estudiantes, tutores y docentes? | La coordinación del programa, por el medio que prefiera, fuera del sistema. |
| ¿Tipos de gráfico necesarios además de línea, barras y dispersión? | Solo esos tres. Confirmar con el equipo y los docentes. |
| ¿Límites de peso reales del servidor? | 25 MB documento, 10 MB cronograma y resultados. |
| ¿Hay tope de estudiantes por proyecto? | No. |
| ¿La nota definitiva del proyecto es el promedio de los 5 entregables? | No se calcula en el MVP (RN-12). |
| ¿El docente puede calificar un entregable con avance menor a 100? | Sí, sin condición. |
| ¿Reimportar el cronograma sobrescribe el avance editado en la aplicación? | Sí, con aviso previo (S12). |
| ¿El Gantt semanal entra en el MVP? | No, es Should (RF-CRO-11). |
| ¿Se usan los archivos de ejemplo como datos de prueba automatizadas? | Propuesto: sí, copiados a `apps/api/tests/fixtures/`. Falta tu visto bueno, son de un proyecto real. |

## 14. Hallazgos de los documentos de ejemplo

| Hallazgo | Efecto en los requerimientos |
| --- | --- |
| **Cronograma:** Gantt con actividades agrupadas por objetivo, columnas `Sem. inicio`, `Sem. fin`, `Avance %` y `Estado`. | El avance es por actividad, no un solo % por entregable. D4 revisada, RF-CRO-04 a 06. |
| `Estado` tiene lista fija: Pendiente, En proceso, Finalizada, Reprogramada. | RN-13. |
| Las fechas mezclan serial de Excel, texto `dd/mm/yyyy` y datetime. En los seriales con día ≤ 12 el día y el mes quedaron invertidos (ej. fin del "03/11/2026" guardado como 11-mar-2026). | El sistema no lee fechas del archivo. Las deriva de la fecha de inicio y las semanas (RF-CRO-02, RN-14). |
| La celda de inicio del proyecto es texto y coincide con la fecha de fin. Las cabeceras semanales dan `#VALUE!`. | La fecha de inicio se registra en la aplicación. Las columnas de presentación se ignoran (6.1). |
| **Resultados:** son un Word con 18 tablas y texto de análisis, no CSV ni Excel. | D7: solo plantillas Excel/CSV. |
| Hay curvas (tiempo × 3 harinas), réplicas con media ± DE (cenizas, pH, acidez, colorimetría) y tablas vacías (CAA, CAAc). | Plantilla larga con réplicas y barras de error (D6, RF-RES-13). |
| Coma decimal (`3,06`), unidades dentro de la celda (`2,70 %`, `34,311g`), `No válido` en columnas numéricas. | RF-RES-03, RF-RES-11, RF-RES-12. |
| La desviación estándar reportada coincide con la muestral (n − 1). | RF-RES-13. |
| Los datos tienen inconsistencias de laboratorio (pesos de crisol incompatibles con la muestra, un peso final menor al crisol vacío). | RN-17: el sistema valida estructura, no plausibilidad. |
