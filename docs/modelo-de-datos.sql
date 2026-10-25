-- Modelo de datos de referencia (PostgreSQL 17). Verificado con psql.
-- Fuente: docs/requisitos-funcionales.md v0.3. Explicación: docs/modelo-de-datos.md.
-- La fuente de verdad pasa a ser la migración Alembic cuando exista; este archivo documenta la intención.

-- ---------------------------------------------------------------------------
-- Usuarios
-- ---------------------------------------------------------------------------
CREATE TABLE usuario (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre          varchar(150) NOT NULL,
    correo          varchar(254) NOT NULL,
    hash_contrasena text         NOT NULL,
    rol             varchar(10)  NOT NULL CHECK (rol IN ('estudiante', 'docente', 'tutor')),
    activo          boolean      NOT NULL DEFAULT true,
    created_at      timestamptz  NOT NULL DEFAULT now(),
    updated_at      timestamptz  NOT NULL DEFAULT now(),
    -- Permite las FK compuestas (id, rol) que fijan el rol exigido en cada relación.
    CONSTRAINT uq_usuario_id_rol UNIQUE (id, rol)
);
CREATE UNIQUE INDEX uq_usuario_correo_lower ON usuario (lower(correo));
CREATE INDEX ix_usuario_rol_nombre ON usuario (rol, nombre);

-- ---------------------------------------------------------------------------
-- Proyecto, participantes y objetivos
-- ---------------------------------------------------------------------------
CREATE TABLE proyecto (
    id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    titulo              varchar(200) NOT NULL CHECK (length(btrim(titulo)) >= 1),
    linea_investigacion varchar(150),
    resumen             varchar(3000),
    objetivo_general    varchar(1000),
    creado_por_id       uuid         NOT NULL,
    creado_por_rol      varchar(10)  NOT NULL DEFAULT 'estudiante' CHECK (creado_por_rol = 'estudiante'),
    tutor_id            uuid         NOT NULL,
    tutor_rol           varchar(10)  NOT NULL DEFAULT 'tutor'      CHECK (tutor_rol = 'tutor'),
    docente_id          uuid         NOT NULL,
    docente_rol         varchar(10)  NOT NULL DEFAULT 'docente'    CHECK (docente_rol = 'docente'),
    version             integer      NOT NULL DEFAULT 1 CHECK (version >= 1),
    actualizado_por_id  uuid REFERENCES usuario (id),
    created_at          timestamptz  NOT NULL DEFAULT now(),
    updated_at          timestamptz  NOT NULL DEFAULT now(),
    FOREIGN KEY (creado_por_id, creado_por_rol) REFERENCES usuario (id, rol),
    FOREIGN KEY (tutor_id, tutor_rol)           REFERENCES usuario (id, rol),
    FOREIGN KEY (docente_id, docente_rol)       REFERENCES usuario (id, rol)
);
CREATE INDEX ix_proyecto_tutor   ON proyecto (tutor_id);
CREATE INDEX ix_proyecto_docente ON proyecto (docente_id);

CREATE TABLE proyecto_estudiante (
    proyecto_id uuid        NOT NULL REFERENCES proyecto (id) ON DELETE CASCADE,
    usuario_id  uuid        NOT NULL,
    rol         varchar(10) NOT NULL DEFAULT 'estudiante' CHECK (rol = 'estudiante'),
    created_at  timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (proyecto_id, usuario_id),
    FOREIGN KEY (usuario_id, rol) REFERENCES usuario (id, rol)
);
CREATE INDEX ix_proyecto_estudiante_usuario ON proyecto_estudiante (usuario_id);

CREATE TABLE objetivo_especifico (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    proyecto_id uuid         NOT NULL REFERENCES proyecto (id) ON DELETE CASCADE,
    orden       smallint     NOT NULL CHECK (orden >= 1),
    descripcion varchar(500) NOT NULL CHECK (length(btrim(descripcion)) >= 1),
    -- Diferida: permite reordenar intercambiando valores dentro de una transacción.
    CONSTRAINT uq_objetivo_orden UNIQUE (proyecto_id, orden) DEFERRABLE INITIALLY DEFERRED
);

-- ---------------------------------------------------------------------------
-- Entregables y cronograma
-- ---------------------------------------------------------------------------
CREATE TABLE entregable (
    id                       uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    proyecto_id              uuid        NOT NULL REFERENCES proyecto (id) ON DELETE CASCADE,
    numero                   smallint    NOT NULL CHECK (numero BETWEEN 1 AND 5),
    nombre                   varchar(100),
    fecha_inicio_cronograma  date,
    version                  integer     NOT NULL DEFAULT 1 CHECK (version >= 1),
    actualizado_por_id       uuid REFERENCES usuario (id),
    created_at               timestamptz NOT NULL DEFAULT now(),
    updated_at               timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_entregable_numero UNIQUE (proyecto_id, numero)
);

CREATE TABLE actividad_cronograma (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    entregable_id uuid         NOT NULL REFERENCES entregable (id) ON DELETE CASCADE,
    orden         integer      NOT NULL CHECK (orden >= 1),
    objetivo      varchar(100),
    actividad     varchar(300) NOT NULL CHECK (length(btrim(actividad)) >= 1),
    sem_inicio    smallint     NOT NULL CHECK (sem_inicio >= 1),
    sem_fin       smallint     NOT NULL,
    observaciones varchar(500),
    avance        numeric(5, 2) NOT NULL DEFAULT 0 CHECK (avance BETWEEN 0 AND 100),
    estado        varchar(12)  NOT NULL DEFAULT 'pendiente'
                  CHECK (estado IN ('pendiente', 'en_proceso', 'finalizada', 'reprogramada')),
    CONSTRAINT ck_actividad_semanas CHECK (sem_fin >= sem_inicio),
    -- RN-13: Finalizada <=> avance 100.
    CONSTRAINT ck_actividad_finalizada CHECK ((estado = 'finalizada') = (avance = 100)),
    CONSTRAINT uq_actividad_orden UNIQUE (entregable_id, orden) DEFERRABLE INITIALLY DEFERRED
);

-- ---------------------------------------------------------------------------
-- Archivos y resultados
-- ---------------------------------------------------------------------------
CREATE TABLE archivo (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    entregable_id   uuid         NOT NULL REFERENCES entregable (id) ON DELETE CASCADE,
    tipo            varchar(10)  NOT NULL CHECK (tipo IN ('documento', 'cronograma', 'resultados')),
    nombre_original varchar(255) NOT NULL,
    mime_type       varchar(127) NOT NULL,
    tamano_bytes    bigint       NOT NULL CHECK (tamano_bytes > 0),
    storage_key     varchar(255) NOT NULL UNIQUE,
    subido_por_id   uuid         NOT NULL,
    subido_por_rol  varchar(10)  NOT NULL DEFAULT 'estudiante' CHECK (subido_por_rol = 'estudiante'),
    created_at      timestamptz  NOT NULL DEFAULT now(),
    FOREIGN KEY (subido_por_id, subido_por_rol) REFERENCES usuario (id, rol),
    -- Permite la FK compuesta (id, tipo) desde conjunto_resultados.
    CONSTRAINT uq_archivo_id_tipo UNIQUE (id, tipo)
);
CREATE INDEX ix_archivo_entregable_tipo ON archivo (entregable_id, tipo);
-- S7: un documento y un cronograma vigentes por entregable. Resultados: varios.
CREATE UNIQUE INDEX uq_archivo_vigente ON archivo (entregable_id, tipo)
    WHERE tipo IN ('documento', 'cronograma');

CREATE TABLE conjunto_resultados (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    archivo_id     uuid         NOT NULL UNIQUE,
    archivo_tipo   varchar(10)  NOT NULL DEFAULT 'resultados' CHECK (archivo_tipo = 'resultados'),
    titulo         varchar(150) NOT NULL CHECK (length(btrim(titulo)) >= 1),
    n_filas        integer      NOT NULL CHECK (n_filas >= 1),
    tipo_x         varchar(6)   NOT NULL CHECK (tipo_x IN ('numero', 'fecha', 'texto')),
    tiene_replicas boolean      NOT NULL,
    n_faltantes    integer      NOT NULL DEFAULT 0 CHECK (n_faltantes >= 0),
    created_at     timestamptz  NOT NULL DEFAULT now(),
    updated_at     timestamptz  NOT NULL DEFAULT now(),
    FOREIGN KEY (archivo_id, archivo_tipo) REFERENCES archivo (id, tipo) ON DELETE CASCADE
);

CREATE TABLE serie_resultados (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    conjunto_id uuid         NOT NULL REFERENCES conjunto_resultados (id) ON DELETE CASCADE,
    nombre      varchar(100) NOT NULL CHECK (length(btrim(nombre)) >= 1),
    unidad      varchar(20),   -- RN-16: una sola unidad por serie
    orden       smallint     NOT NULL CHECK (orden >= 1),
    CONSTRAINT uq_serie_nombre UNIQUE (conjunto_id, nombre),
    CONSTRAINT uq_serie_orden  UNIQUE (conjunto_id, orden)
);

CREATE TABLE punto_resultado (
    id       bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    serie_id uuid         NOT NULL REFERENCES serie_resultados (id) ON DELETE CASCADE,
    orden    integer      NOT NULL CHECK (orden >= 1),   -- posición en el archivo
    x_texto  varchar(100) NOT NULL,                      -- forma canónica, siempre presente
    x_numero double precision,                           -- si conjunto.tipo_x = 'numero'
    x_fecha  date,                                       -- si conjunto.tipo_x = 'fecha'
    y        double precision,                           -- NULL = dato faltante (RF-RES-12)
    replica  varchar(20),
    CONSTRAINT ck_punto_x_unico CHECK (num_nonnulls(x_numero, x_fecha) <= 1),
    CONSTRAINT ck_punto_y_finito CHECK (
        y IS NULL OR y NOT IN ('NaN'::float8, 'Infinity'::float8, '-Infinity'::float8)
    ),
    -- RN-15: (serie, x, réplica) único; sin réplica, (serie, x) único.
    CONSTRAINT uq_punto UNIQUE NULLS NOT DISTINCT (serie_id, x_texto, replica)
);
CREATE INDEX ix_punto_serie_orden ON punto_resultado (serie_id, orden);

-- ---------------------------------------------------------------------------
-- Evaluación
-- ---------------------------------------------------------------------------
CREATE TABLE comentario (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    entregable_id uuid         NOT NULL REFERENCES entregable (id) ON DELETE CASCADE,
    autor_id      uuid         NOT NULL,
    autor_rol     varchar(10)  NOT NULL DEFAULT 'docente' CHECK (autor_rol = 'docente'),
    texto         varchar(2000) NOT NULL CHECK (length(btrim(texto)) >= 1),
    created_at    timestamptz  NOT NULL DEFAULT now(),
    FOREIGN KEY (autor_id, autor_rol) REFERENCES usuario (id, rol)
);
CREATE INDEX ix_comentario_entregable_fecha ON comentario (entregable_id, created_at);

CREATE TABLE calificacion (
    entregable_id uuid PRIMARY KEY REFERENCES entregable (id) ON DELETE CASCADE,
    docente_id    uuid         NOT NULL,
    docente_rol   varchar(10)  NOT NULL DEFAULT 'docente' CHECK (docente_rol = 'docente'),
    nota          numeric(2, 1) NOT NULL CHECK (nota BETWEEN 0.0 AND 5.0),
    created_at    timestamptz  NOT NULL DEFAULT now(),
    updated_at    timestamptz  NOT NULL DEFAULT now(),
    FOREIGN KEY (docente_id, docente_rol) REFERENCES usuario (id, rol)
);

-- ---------------------------------------------------------------------------
-- Registro: intentos fallidos de código (RF-AUT-09, RN-20)
-- Sin FK a usuario: el correo puede no existir todavía.
-- ---------------------------------------------------------------------------
CREATE TABLE intento_registro (
    id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    correo     varchar(254) NOT NULL CHECK (correo = lower(correo)),
    ip         inet,
    rol        varchar(10)  NOT NULL CHECK (rol IN ('estudiante', 'docente', 'tutor')),
    created_at timestamptz  NOT NULL DEFAULT now()
);
CREATE INDEX ix_intento_registro_correo_fecha ON intento_registro (correo, created_at);
CREATE INDEX ix_intento_registro_ip_fecha     ON intento_registro (ip, created_at);
