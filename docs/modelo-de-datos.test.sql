-- Pruebas del esquema de docs/modelo-de-datos.sql. Cada caso declara si espera exito o fallo.
-- Las 2 pruebas de orden duplicado (objetivos y actividades) se rechazan en el COMMIT diferido:
-- psql las muestra como ERROR y no aparecen en el informe final. Ver docs/modelo-de-datos.md, seccion 8.
\set ON_ERROR_STOP off

CREATE TEMP TABLE resultados_prueba (caso text, esperado text, obtenido text, ok boolean);

CREATE FUNCTION pg_temp.probar(caso text, esperado text, sentencia text) RETURNS void AS $$
DECLARE obtenido text;
BEGIN
    BEGIN
        EXECUTE sentencia;
        obtenido := 'exito';
    EXCEPTION WHEN OTHERS THEN
        obtenido := 'fallo: ' || SQLERRM;
    END;
    INSERT INTO resultados_prueba VALUES (caso, esperado, obtenido, (esperado = 'exito') = (obtenido = 'exito'));
END $$ LANGUAGE plpgsql;

-- Datos base ------------------------------------------------------------
INSERT INTO usuario (id, nombre, correo, hash_contrasena, rol) VALUES
 ('00000000-0000-0000-0000-000000000001', 'Est Uno',   'est1@u.co',  'x', 'estudiante'),
 ('00000000-0000-0000-0000-000000000002', 'Est Dos',   'est2@u.co',  'x', 'estudiante'),
 ('00000000-0000-0000-0000-0000000000a1', 'Tutor Uno', 'tut1@u.co',  'x', 'tutor'),
 ('00000000-0000-0000-0000-0000000000d1', 'Doc Uno',   'doc1@u.co',  'x', 'docente');

INSERT INTO proyecto (id, titulo, creado_por_id, tutor_id, docente_id) VALUES
 ('10000000-0000-0000-0000-000000000001', 'Proyecto base',
  '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-0000000000d1');
INSERT INTO proyecto_estudiante (proyecto_id, usuario_id) VALUES
 ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001');
INSERT INTO entregable (id, proyecto_id, numero) VALUES
 ('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 1);

-- Usuario ---------------------------------------------------------------
SELECT pg_temp.probar('usuario: correo duplicado distinto caso', 'fallo',
 $$INSERT INTO usuario (nombre, correo, hash_contrasena, rol) VALUES ('X', 'EST1@U.CO', 'x', 'estudiante')$$);
SELECT pg_temp.probar('usuario: rol invalido', 'fallo',
 $$INSERT INTO usuario (nombre, correo, hash_contrasena, rol) VALUES ('X', 'a@u.co', 'x', 'admin')$$);

-- Proyecto: roles por FK compuesta --------------------------------------
SELECT pg_temp.probar('proyecto: tutor con rol estudiante', 'fallo',
 $$INSERT INTO proyecto (titulo, creado_por_id, tutor_id, docente_id) VALUES ('P',
   '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-0000000000d1')$$);
SELECT pg_temp.probar('proyecto: docente con rol tutor', 'fallo',
 $$INSERT INTO proyecto (titulo, creado_por_id, tutor_id, docente_id) VALUES ('P',
   '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-0000000000a1')$$);
SELECT pg_temp.probar('proyecto: creador con rol docente', 'fallo',
 $$INSERT INTO proyecto (titulo, creado_por_id, tutor_id, docente_id) VALUES ('P',
   '00000000-0000-0000-0000-0000000000d1', '00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-0000000000d1')$$);
SELECT pg_temp.probar('proyecto: titulo vacio', 'fallo',
 $$INSERT INTO proyecto (titulo, creado_por_id, tutor_id, docente_id) VALUES ('  ',
   '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-0000000000d1')$$);
SELECT pg_temp.probar('proyecto: cambiar tutor por otro tutor valido', 'exito',
 $$UPDATE proyecto SET tutor_id = tutor_id WHERE id = '10000000-0000-0000-0000-000000000001'$$);
SELECT pg_temp.probar('usuario: cambiar rol de usuario referenciado', 'fallo',
 $$UPDATE usuario SET rol = 'docente' WHERE id = '00000000-0000-0000-0000-0000000000a1'$$);
SELECT pg_temp.probar('proyecto_estudiante: docente como estudiante', 'fallo',
 $$INSERT INTO proyecto_estudiante (proyecto_id, usuario_id) VALUES ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-0000000000d1')$$);
SELECT pg_temp.probar('proyecto_estudiante: segundo estudiante', 'exito',
 $$INSERT INTO proyecto_estudiante (proyecto_id, usuario_id) VALUES ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002')$$);
SELECT pg_temp.probar('proyecto_estudiante: duplicado', 'fallo',
 $$INSERT INTO proyecto_estudiante (proyecto_id, usuario_id) VALUES ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002')$$);

-- Objetivos: reordenar con restriccion diferida --------------------------
INSERT INTO objetivo_especifico (proyecto_id, orden, descripcion) VALUES
 ('10000000-0000-0000-0000-000000000001', 1, 'A'), ('10000000-0000-0000-0000-000000000001', 2, 'B');
SELECT pg_temp.probar('objetivo: orden duplicado', 'fallo',
 $$INSERT INTO objetivo_especifico (proyecto_id, orden, descripcion) VALUES ('10000000-0000-0000-0000-000000000001', 1, 'C')$$);
SELECT pg_temp.probar('objetivo: intercambiar ordenes en un UPDATE', 'exito',
 $$UPDATE objetivo_especifico SET orden = 3 - orden WHERE proyecto_id = '10000000-0000-0000-0000-000000000001'$$);

-- Entregable --------------------------------------------------------------
SELECT pg_temp.probar('entregable: numero 6', 'fallo',
 $$INSERT INTO entregable (proyecto_id, numero) VALUES ('10000000-0000-0000-0000-000000000001', 6)$$);
SELECT pg_temp.probar('entregable: numero 0', 'fallo',
 $$INSERT INTO entregable (proyecto_id, numero) VALUES ('10000000-0000-0000-0000-000000000001', 0)$$);
SELECT pg_temp.probar('entregable: numero repetido', 'fallo',
 $$INSERT INTO entregable (proyecto_id, numero) VALUES ('10000000-0000-0000-0000-000000000001', 1)$$);
SELECT pg_temp.probar('entregable: numero 2', 'exito',
 $$INSERT INTO entregable (proyecto_id, numero) VALUES ('10000000-0000-0000-0000-000000000001', 2)$$);

-- Actividades ---------------------------------------------------------------
SELECT pg_temp.probar('actividad: valida', 'exito',
 $$INSERT INTO actividad_cronograma (entregable_id, orden, actividad, sem_inicio, sem_fin, avance, estado)
   VALUES ('20000000-0000-0000-0000-000000000001', 1, 'Act 1', 1, 2, 40, 'en_proceso')$$);
SELECT pg_temp.probar('actividad: segunda valida', 'exito',
 $$INSERT INTO actividad_cronograma (entregable_id, orden, actividad, sem_inicio, sem_fin)
   VALUES ('20000000-0000-0000-0000-000000000001', 2, 'Act 2', 3, 3)$$);
SELECT pg_temp.probar('actividad: sem_fin < sem_inicio', 'fallo',
 $$INSERT INTO actividad_cronograma (entregable_id, orden, actividad, sem_inicio, sem_fin)
   VALUES ('20000000-0000-0000-0000-000000000001', 3, 'X', 5, 4)$$);
SELECT pg_temp.probar('actividad: sem_inicio 0', 'fallo',
 $$INSERT INTO actividad_cronograma (entregable_id, orden, actividad, sem_inicio, sem_fin)
   VALUES ('20000000-0000-0000-0000-000000000001', 3, 'X', 0, 1)$$);
SELECT pg_temp.probar('actividad: avance 101', 'fallo',
 $$INSERT INTO actividad_cronograma (entregable_id, orden, actividad, sem_inicio, sem_fin, avance)
   VALUES ('20000000-0000-0000-0000-000000000001', 3, 'X', 1, 1, 101)$$);
SELECT pg_temp.probar('actividad: finalizada con avance 50', 'fallo',
 $$INSERT INTO actividad_cronograma (entregable_id, orden, actividad, sem_inicio, sem_fin, avance, estado)
   VALUES ('20000000-0000-0000-0000-000000000001', 3, 'X', 1, 1, 50, 'finalizada')$$);
SELECT pg_temp.probar('actividad: avance 100 y pendiente', 'fallo',
 $$INSERT INTO actividad_cronograma (entregable_id, orden, actividad, sem_inicio, sem_fin, avance, estado)
   VALUES ('20000000-0000-0000-0000-000000000001', 3, 'X', 1, 1, 100, 'pendiente')$$);
SELECT pg_temp.probar('actividad: finalizada con 100', 'exito',
 $$INSERT INTO actividad_cronograma (entregable_id, orden, actividad, sem_inicio, sem_fin, avance, estado)
   VALUES ('20000000-0000-0000-0000-000000000001', 3, 'X', 1, 1, 100, 'finalizada')$$);
SELECT pg_temp.probar('actividad: estado invalido', 'fallo',
 $$INSERT INTO actividad_cronograma (entregable_id, orden, actividad, sem_inicio, sem_fin, estado)
   VALUES ('20000000-0000-0000-0000-000000000001', 4, 'X', 1, 1, 'listo')$$);
SELECT pg_temp.probar('actividad: orden duplicado', 'fallo',
 $$INSERT INTO actividad_cronograma (entregable_id, orden, actividad, sem_inicio, sem_fin)
   VALUES ('20000000-0000-0000-0000-000000000001', 1, 'X', 1, 1)$$);
SELECT pg_temp.probar('actividad: intercambiar ordenes en un UPDATE', 'exito',
 $$UPDATE actividad_cronograma SET orden = 3 - orden WHERE entregable_id = '20000000-0000-0000-0000-000000000001' AND orden IN (1, 2)$$);

-- Archivos ------------------------------------------------------------------
SELECT pg_temp.probar('archivo: documento', 'exito',
 $$INSERT INTO archivo (id, entregable_id, tipo, nombre_original, mime_type, tamano_bytes, storage_key, subido_por_id)
   VALUES ('30000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 'documento', 'a.pdf', 'application/pdf', 10, 'k1', '00000000-0000-0000-0000-000000000001')$$);
SELECT pg_temp.probar('archivo: segundo documento vigente', 'fallo',
 $$INSERT INTO archivo (entregable_id, tipo, nombre_original, mime_type, tamano_bytes, storage_key, subido_por_id)
   VALUES ('20000000-0000-0000-0000-000000000001', 'documento', 'b.pdf', 'application/pdf', 10, 'k2', '00000000-0000-0000-0000-000000000001')$$);
SELECT pg_temp.probar('archivo: documento en otro entregable', 'exito',
 $$INSERT INTO archivo (entregable_id, tipo, nombre_original, mime_type, tamano_bytes, storage_key, subido_por_id)
   SELECT id, 'documento', 'c.pdf', 'application/pdf', 10, 'k3', '00000000-0000-0000-0000-000000000001' FROM entregable WHERE numero = 2$$);
SELECT pg_temp.probar('archivo: subido por docente', 'fallo',
 $$INSERT INTO archivo (entregable_id, tipo, nombre_original, mime_type, tamano_bytes, storage_key, subido_por_id)
   VALUES ('20000000-0000-0000-0000-000000000001', 'cronograma', 'c.xlsx', 'x', 10, 'k4', '00000000-0000-0000-0000-0000000000d1')$$);
SELECT pg_temp.probar('archivo: tamano 0', 'fallo',
 $$INSERT INTO archivo (entregable_id, tipo, nombre_original, mime_type, tamano_bytes, storage_key, subido_por_id)
   VALUES ('20000000-0000-0000-0000-000000000001', 'cronograma', 'c.xlsx', 'x', 0, 'k5', '00000000-0000-0000-0000-000000000001')$$);
SELECT pg_temp.probar('archivo: storage_key repetida', 'fallo',
 $$INSERT INTO archivo (entregable_id, tipo, nombre_original, mime_type, tamano_bytes, storage_key, subido_por_id)
   VALUES ('20000000-0000-0000-0000-000000000001', 'cronograma', 'c.xlsx', 'x', 10, 'k1', '00000000-0000-0000-0000-000000000001')$$);
SELECT pg_temp.probar('archivo: resultados 1', 'exito',
 $$INSERT INTO archivo (id, entregable_id, tipo, nombre_original, mime_type, tamano_bytes, storage_key, subido_por_id) VALUES
   ('30000000-0000-0000-0000-0000000000b1', '20000000-0000-0000-0000-000000000001', 'resultados', 'r1.csv', 'text/csv', 10, 'kr1', '00000000-0000-0000-0000-000000000001')$$);
SELECT pg_temp.probar('archivo: resultados 2 en el mismo entregable', 'exito',
 $$INSERT INTO archivo (id, entregable_id, tipo, nombre_original, mime_type, tamano_bytes, storage_key, subido_por_id) VALUES
   ('30000000-0000-0000-0000-0000000000b2', '20000000-0000-0000-0000-000000000001', 'resultados', 'r2.csv', 'text/csv', 10, 'kr2', '00000000-0000-0000-0000-000000000001')$$);

-- Conjunto, series y puntos ---------------------------------------------------
SELECT pg_temp.probar('conjunto: sobre archivo de tipo documento', 'fallo',
 $$INSERT INTO conjunto_resultados (archivo_id, titulo, n_filas, tipo_x, tiene_replicas)
   VALUES ('30000000-0000-0000-0000-000000000001', 'T', 1, 'texto', false)$$);
SELECT pg_temp.probar('conjunto: sobre archivo de resultados', 'exito',
 $$INSERT INTO conjunto_resultados (id, archivo_id, titulo, n_filas, tipo_x, tiene_replicas)
   VALUES ('40000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-0000000000b1', 'T', 6, 'texto', true)$$);
SELECT pg_temp.probar('conjunto: segundo conjunto para el mismo archivo', 'fallo',
 $$INSERT INTO conjunto_resultados (archivo_id, titulo, n_filas, tipo_x, tiene_replicas)
   VALUES ('30000000-0000-0000-0000-0000000000b1', 'T2', 1, 'texto', false)$$);
SELECT pg_temp.probar('conjunto: tipo_x invalido', 'fallo',
 $$INSERT INTO conjunto_resultados (archivo_id, titulo, n_filas, tipo_x, tiene_replicas)
   VALUES ('30000000-0000-0000-0000-0000000000b2', 'T', 1, 'color', false)$$);
SELECT pg_temp.probar('serie: Arroz', 'exito',
 $$INSERT INTO serie_resultados (id, conjunto_id, nombre, unidad, orden)
   VALUES ('50000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-000000000001', 'Arroz', NULL, 1)$$);
SELECT pg_temp.probar('serie: nombre repetido', 'fallo',
 $$INSERT INTO serie_resultados (conjunto_id, nombre, orden)
   VALUES ('40000000-0000-0000-0000-000000000001', 'Arroz', 2)$$);
SELECT pg_temp.probar('punto: replica 1', 'exito',
 $$INSERT INTO punto_resultado (serie_id, orden, x_texto, y, replica)
   VALUES ('50000000-0000-0000-0000-000000000001', 1, 'L*', 51.51, '1')$$);
SELECT pg_temp.probar('punto: replica 2 mismo x', 'exito',
 $$INSERT INTO punto_resultado (serie_id, orden, x_texto, y, replica)
   VALUES ('50000000-0000-0000-0000-000000000001', 2, 'L*', 39.68, '2')$$);
SELECT pg_temp.probar('punto: replica repetida', 'fallo',
 $$INSERT INTO punto_resultado (serie_id, orden, x_texto, y, replica)
   VALUES ('50000000-0000-0000-0000-000000000001', 3, 'L*', 44.13, '1')$$);
SELECT pg_temp.probar('punto: sin replica (primero)', 'exito',
 $$INSERT INTO punto_resultado (serie_id, orden, x_texto, y, replica)
   VALUES ('50000000-0000-0000-0000-000000000001', 4, 'a*', 0.10, NULL)$$);
SELECT pg_temp.probar('punto: sin replica duplicado (NULLS NOT DISTINCT)', 'fallo',
 $$INSERT INTO punto_resultado (serie_id, orden, x_texto, y, replica)
   VALUES ('50000000-0000-0000-0000-000000000001', 5, 'a*', 0.03, NULL)$$);
SELECT pg_temp.probar('punto: y faltante (NULL)', 'exito',
 $$INSERT INTO punto_resultado (serie_id, orden, x_texto, y, replica)
   VALUES ('50000000-0000-0000-0000-000000000001', 6, 'b*', NULL, NULL)$$);
SELECT pg_temp.probar('punto: y = NaN', 'fallo',
 $$INSERT INTO punto_resultado (serie_id, orden, x_texto, y, replica)
   VALUES ('50000000-0000-0000-0000-000000000001', 7, 'c*', 'NaN', NULL)$$);
SELECT pg_temp.probar('punto: y = Infinity', 'fallo',
 $$INSERT INTO punto_resultado (serie_id, orden, x_texto, y, replica)
   VALUES ('50000000-0000-0000-0000-000000000001', 8, 'd*', 'Infinity', NULL)$$);
SELECT pg_temp.probar('punto: x numerico y x fecha a la vez', 'fallo',
 $$INSERT INTO punto_resultado (serie_id, orden, x_texto, x_numero, x_fecha, y)
   VALUES ('50000000-0000-0000-0000-000000000001', 9, 'e', 1, DATE '2026-01-01', 1)$$);

-- Evaluacion ---------------------------------------------------------------------
SELECT pg_temp.probar('comentario: autor docente', 'exito',
 $$INSERT INTO comentario (entregable_id, autor_id, texto)
   VALUES ('20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-0000000000d1', 'Bien')$$);
SELECT pg_temp.probar('comentario: autor estudiante', 'fallo',
 $$INSERT INTO comentario (entregable_id, autor_id, texto)
   VALUES ('20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'Hola')$$);
SELECT pg_temp.probar('comentario: autor tutor', 'fallo',
 $$INSERT INTO comentario (entregable_id, autor_id, texto)
   VALUES ('20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-0000000000a1', 'Hola')$$);
SELECT pg_temp.probar('comentario: texto vacio', 'fallo',
 $$INSERT INTO comentario (entregable_id, autor_id, texto)
   VALUES ('20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-0000000000d1', '   ')$$);
SELECT pg_temp.probar('comentario: texto de 2001 caracteres', 'fallo',
 $$INSERT INTO comentario (entregable_id, autor_id, texto)
   VALUES ('20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-0000000000d1', repeat('a', 2001))$$);
SELECT pg_temp.probar('calificacion: 4.5', 'exito',
 $$INSERT INTO calificacion (entregable_id, docente_id, nota)
   VALUES ('20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-0000000000d1', 4.5)$$);
SELECT pg_temp.probar('calificacion: segunda para el mismo entregable', 'fallo',
 $$INSERT INTO calificacion (entregable_id, docente_id, nota)
   VALUES ('20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-0000000000d1', 3.0)$$);
SELECT pg_temp.probar('calificacion: actualizar a 5.0', 'exito',
 $$UPDATE calificacion SET nota = 5.0 WHERE entregable_id = '20000000-0000-0000-0000-000000000001'$$);
SELECT pg_temp.probar('calificacion: 5.1', 'fallo',
 $$UPDATE calificacion SET nota = 5.1 WHERE entregable_id = '20000000-0000-0000-0000-000000000001'$$);
SELECT pg_temp.probar('calificacion: -0.1', 'fallo',
 $$UPDATE calificacion SET nota = -0.1 WHERE entregable_id = '20000000-0000-0000-0000-000000000001'$$);
SELECT pg_temp.probar('calificacion: docente_id de un tutor', 'fallo',
 $$INSERT INTO calificacion (entregable_id, docente_id, nota)
   SELECT id, '00000000-0000-0000-0000-0000000000a1', 3.0 FROM entregable WHERE numero = 2$$);

-- Cascada: borrar el proyecto elimina todo lo que cuelga de el ----------------------
SELECT pg_temp.probar('cascada: borrar proyecto', 'exito',
 $$DELETE FROM proyecto WHERE id = '10000000-0000-0000-0000-000000000001'$$);
SELECT pg_temp.probar('cascada: no quedan huerfanos', 'exito',
 $q$DO $b$ BEGIN
     IF (SELECT count(*) FROM entregable) + (SELECT count(*) FROM actividad_cronograma) + (SELECT count(*) FROM archivo)
      + (SELECT count(*) FROM conjunto_resultados) + (SELECT count(*) FROM serie_resultados) + (SELECT count(*) FROM punto_resultado)
      + (SELECT count(*) FROM comentario) + (SELECT count(*) FROM calificacion) + (SELECT count(*) FROM objetivo_especifico)
      + (SELECT count(*) FROM proyecto_estudiante) > 0 THEN RAISE EXCEPTION 'quedaron filas huerfanas'; END IF;
   END $b$$q$);

-- Intentos fallidos de registro (RF-AUT-09, RN-20) ------------------------------------
SELECT pg_temp.probar('intento: correo en minusculas', 'exito',
 $$INSERT INTO intento_registro (correo, ip, rol) VALUES ('docente@u.co', '10.0.0.1', 'docente')$$);
SELECT pg_temp.probar('intento: correo con mayusculas', 'fallo',
 $$INSERT INTO intento_registro (correo, ip, rol) VALUES ('Docente@U.co', '10.0.0.1', 'docente')$$);
SELECT pg_temp.probar('intento: rol invalido', 'fallo',
 $$INSERT INTO intento_registro (correo, ip, rol) VALUES ('a@u.co', '10.0.0.1', 'admin')$$);
SELECT pg_temp.probar('intento: ip invalida', 'fallo',
 $$INSERT INTO intento_registro (correo, ip, rol) VALUES ('a@u.co', '999.1.1.1', 'tutor')$$);
SELECT pg_temp.probar('intento: sin ip (detras de un proxy)', 'exito',
 $$INSERT INTO intento_registro (correo, ip, rol) VALUES ('b@u.co', NULL, 'tutor')$$);
SELECT pg_temp.probar('intento: correo que no existe como usuario', 'exito',
 $$INSERT INTO intento_registro (correo, ip, rol) VALUES ('nadie@u.co', '10.0.0.9', 'estudiante')$$);

-- Ventana deslizante: 5 intentos en 15 min bloquean; los mas viejos ya no cuentan.
DELETE FROM intento_registro;
INSERT INTO intento_registro (correo, ip, rol, created_at) VALUES
 ('x@u.co', '172.16.0.1', 'docente', now() - interval '40 minutes'),
 ('x@u.co', '172.16.0.1', 'docente', now() - interval '20 minutes'),
 ('x@u.co', '172.16.0.1', 'docente', now() - interval '14 minutes'),
 ('x@u.co', '172.16.0.1', 'docente', now() - interval '10 minutes'),
 ('x@u.co', '172.16.0.1', 'docente', now() - interval '6 minutes'),
 ('x@u.co', '172.16.0.1', 'docente', now() - interval '3 minutes'),
 ('x@u.co', '172.16.0.1', 'docente', now() - interval '1 minute');
SELECT pg_temp.probar('ventana: 5 intentos en 15 min por correo', 'exito',
 $q$DO $b$ BEGIN
     IF (SELECT count(*) FROM intento_registro
          WHERE correo = 'x@u.co' AND created_at > now() - interval '15 minutes') <> 5
     THEN RAISE EXCEPTION 'se esperaban 5 intentos en la ventana'; END IF;
   END $b$$q$);
SELECT pg_temp.probar('ventana: hay bloqueo y reintento en cerca de 1 minuto', 'exito',
 $q$DO $b$ DECLARE espera numeric; BEGIN
     SELECT extract(epoch FROM (created_at + interval '15 minutes' - now())) INTO espera
       FROM intento_registro
      WHERE (correo = 'x@u.co' OR ip = '172.16.0.1') AND created_at > now() - interval '15 minutes'
      ORDER BY created_at DESC OFFSET 4 LIMIT 1;
     IF espera IS NULL THEN RAISE EXCEPTION 'no hay bloqueo'; END IF;
     IF espera NOT BETWEEN 50 AND 70 THEN RAISE EXCEPTION 'espera inesperada: % s', espera; END IF;
   END $b$$q$);
SELECT pg_temp.probar('ventana: otro correo sin intentos no esta bloqueado', 'exito',
 $q$DO $b$ BEGIN
     IF EXISTS (SELECT 1 FROM intento_registro
                 WHERE correo = 'otro@u.co' AND created_at > now() - interval '15 minutes'
                 ORDER BY created_at DESC OFFSET 4 LIMIT 1)
     THEN RAISE EXCEPTION 'no deberia estar bloqueado'; END IF;
   END $b$$q$);
INSERT INTO intento_registro (correo, ip, rol) VALUES
 ('a1@u.co', '192.168.1.5', 'docente'), ('a2@u.co', '192.168.1.5', 'docente'), ('a3@u.co', '192.168.1.5', 'tutor'),
 ('a4@u.co', '192.168.1.5', 'estudiante'), ('a5@u.co', '192.168.1.5', 'docente');
SELECT pg_temp.probar('ventana: 5 intentos desde la misma ip con correos distintos bloquean', 'exito',
 $q$DO $b$ BEGIN
     IF NOT EXISTS (SELECT 1 FROM intento_registro
                     WHERE (correo = 'nuevo@u.co' OR ip = '192.168.1.5') AND created_at > now() - interval '15 minutes'
                     ORDER BY created_at DESC OFFSET 4 LIMIT 1)
     THEN RAISE EXCEPTION 'la ip deberia estar bloqueada'; END IF;
   END $b$$q$);
SELECT pg_temp.probar('purga: borrar intentos de mas de 1 dia', 'exito',
 $$DELETE FROM intento_registro WHERE created_at < now() - interval '1 day'$$);

-- Informe ---------------------------------------------------------------------------
\echo
\echo '=== RESULTADOS ==='
SELECT CASE WHEN ok THEN 'PASS' ELSE 'FAIL' END AS r, caso, esperado, left(obtenido, 95) AS obtenido FROM resultados_prueba;
SELECT count(*) FILTER (WHERE ok) AS pass, count(*) FILTER (WHERE NOT ok) AS fail, count(*) AS total FROM resultados_prueba;
