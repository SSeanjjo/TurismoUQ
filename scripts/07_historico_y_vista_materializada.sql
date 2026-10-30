/* =============================================================================
   TurismoUQ · Script 07 · Histórico de reservas y vista materializada
   Entrega 2 · Bases de Datos II · Universidad del Quindío
   Requiere: 01 a 05 ejecutados y 06 ejecutado como SYSTEM.
   Ejecutar con F5 como DUEÑO DEL ESQUEMA.

   1. HIST_RESERVA en el tablespace TS_TURISMOUQ_HIST + procedimiento
      sp_archivar_reservas que copia allí las reservas cerradas.
   2. MV_OCUPACION_MENSUAL: ocupación por alojamiento y mes, precalculada,
      con refresco completo programado cada noche.
   ============================================================================= */

SET SERVEROUTPUT ON SIZE UNLIMITED
SET DEFINE OFF

/* -----------------------------------------------------------------------------
   0. Limpieza (re-ejecutable)
   ----------------------------------------------------------------------------- */
BEGIN
  DBMS_SCHEDULER.DROP_JOB('JOB_REFRESCO_MV_OCUPACION');
EXCEPTION
  WHEN OTHERS THEN IF SQLCODE != -27475 THEN RAISE; END IF;   -- ORA-27475: el job no existe
END;
/
BEGIN
  EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW mv_ocupacion_mensual';
EXCEPTION
  WHEN OTHERS THEN IF SQLCODE != -12003 THEN RAISE; END IF;   -- ORA-12003: no existe
END;
/
BEGIN
  EXECUTE IMMEDIATE 'DROP PROCEDURE sp_archivar_reservas';
EXCEPTION
  WHEN OTHERS THEN IF SQLCODE != -4043 THEN RAISE; END IF;
END;
/
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE hist_reserva PURGE';
EXCEPTION
  WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

/* =============================================================================
   1. HISTÓRICO DE RESERVAS en TS_TURISMOUQ_HIST
   Justificación del tablespace propio: ver el encabezado del script 06.
   La tabla es desnormalizada a propósito: guarda el nombre del cliente, del
   alojamiento y del municipio TAL COMO ERAN al cerrar la reserva, para que el
   histórico se pueda leer solo y no cambie si después se edita un catálogo.
   Una fila por línea de reserva (habitación).
   ============================================================================= */
CREATE TABLE hist_reserva (
  id_reserva_habitacion NUMBER(10)     NOT NULL,
  id_reserva            NUMBER(10)     NOT NULL,
  estado                VARCHAR2(12)   NOT NULL,
  fecha_reserva         DATE           NOT NULL,
  fecha_checkin         DATE           NOT NULL,
  fecha_checkout        DATE           NOT NULL,
  noches                NUMBER(3)      NOT NULL,
  fecha_cancelacion     DATE,
  id_cliente            NUMBER(8)      NOT NULL,
  documento_cliente     VARCHAR2(25)   NOT NULL,
  nombre_cliente        VARCHAR2(125)  NOT NULL,
  ciudad_origen         VARCHAR2(60)   NOT NULL,
  id_alojamiento        NUMBER(6)      NOT NULL,
  alojamiento           VARCHAR2(100)  NOT NULL,
  tipo_alojamiento      VARCHAR2(40)   NOT NULL,
  municipio             VARCHAR2(60)   NOT NULL,
  id_habitacion         NUMBER(8)      NOT NULL,
  numero_habitacion     VARCHAR2(10)   NOT NULL,
  num_huespedes         NUMBER(2)      NOT NULL,
  valor_estadia         NUMBER(14,2)   NOT NULL,
  valor_servicios_reserva NUMBER(14,2) NOT NULL,
  pagado_reserva        NUMBER(14,2)   NOT NULL,
  fecha_archivo         DATE           DEFAULT SYSDATE NOT NULL,
  CONSTRAINT pk_hist_reserva PRIMARY KEY (id_reserva_habitacion)
    USING INDEX TABLESPACE ts_turismouq_hist,
  CONSTRAINT ck_hist_estado  CHECK (estado IN ('COMPLETADA', 'CANCELADA'))
)
TABLESPACE ts_turismouq_hist
PCTFREE 0;      -- las filas archivadas no se actualizan: no se reserva espacio para crecer

COMMENT ON TABLE  hist_reserva IS 'Histórico de reservas cerradas (completadas o canceladas), una fila por habitación, en el tablespace TS_TURISMOUQ_HIST.';
COMMENT ON COLUMN hist_reserva.valor_servicios_reserva IS 'Servicios de la reserva completa (se repite en cada línea de la misma reserva).';
COMMENT ON COLUMN hist_reserva.pagado_reserva          IS 'Pagos EXITOSOS de la reserva completa al momento de archivar.';

/* -----------------------------------------------------------------------------
   1.1 sp_archivar_reservas(p_hasta): copia al histórico las reservas
       COMPLETADAS o CANCELADAS con check-out anterior a p_hasta que aún no
       estén archivadas (se puede ejecutar varias veces sin duplicar).
       Copia y no borra de las tablas operativas para no romper las consultas
       de análisis de la Entrega 1 ni las FK de PAGO y RESENA; en producción,
       un segundo paso purgaría las operativas una vez verificado el archivo.
   ----------------------------------------------------------------------------- */
CREATE OR REPLACE PROCEDURE sp_archivar_reservas (p_hasta IN DATE) IS
  v_filas PLS_INTEGER;
BEGIN
  IF p_hasta IS NULL OR p_hasta > TRUNC(SYSDATE) THEN
    RAISE_APPLICATION_ERROR(-20131, 'La fecha de corte del archivo debe ser una fecha pasada.');
  END IF;

  INSERT INTO hist_reserva
    (id_reserva_habitacion, id_reserva, estado, fecha_reserva, fecha_checkin, fecha_checkout,
     noches, fecha_cancelacion, id_cliente, documento_cliente, nombre_cliente, ciudad_origen,
     id_alojamiento, alojamiento, tipo_alojamiento, municipio, id_habitacion, numero_habitacion,
     num_huespedes, valor_estadia, valor_servicios_reserva, pagado_reserva)
  SELECT rh.id_reserva_habitacion, r.id_reserva, r.estado, r.fecha_reserva,
         rh.fecha_checkin, rh.fecha_checkout, rh.fecha_checkout - rh.fecha_checkin,
         r.fecha_cancelacion, cl.id_cliente,
         cl.tipo_documento || ' ' || cl.numero_documento,
         cl.nombres || ' ' || cl.apellidos,
         ci.nombre, a.id_alojamiento, a.nombre_comercial, ta.nombre, m.nombre,
         h.id_habitacion, h.numero, rh.num_huespedes, rh.valor_estadia,
         v.valor_servicios, v.pagado_exitoso
    FROM reserva r
    JOIN reserva_habitacion rh ON rh.id_reserva           = r.id_reserva
    JOIN habitacion         h  ON h.id_habitacion         = rh.id_habitacion
    JOIN alojamiento        a  ON a.id_alojamiento        = r.id_alojamiento
    JOIN tipo_alojamiento   ta ON ta.id_tipo_alojamiento  = a.id_tipo_alojamiento
    JOIN municipio          m  ON m.id_municipio          = a.id_municipio
    JOIN cliente            cl ON cl.id_cliente           = r.id_cliente
    JOIN ciudad             ci ON ci.id_ciudad            = cl.id_ciudad_origen
    JOIN vw_valor_reserva   v  ON v.id_reserva            = r.id_reserva
   WHERE r.estado IN ('COMPLETADA', 'CANCELADA')
     AND r.fecha_checkout < p_hasta
     AND NOT EXISTS (SELECT 1 FROM hist_reserva x
                      WHERE x.id_reserva_habitacion = rh.id_reserva_habitacion);
  v_filas := SQL%ROWCOUNT;
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Archivadas ' || v_filas || ' líneas de reserva cerradas antes del '
    || TO_CHAR(p_hasta, 'YYYY-MM-DD') || ' en TS_TURISMOUQ_HIST.');
END sp_archivar_reservas;
/

-- 1.2 Carga inicial del histórico: todo 2024 (año cerrado).
BEGIN
  sp_archivar_reservas(DATE '2025-01-01');
END;
/

/* =============================================================================
   2. VISTA MATERIALIZADA MV_OCUPACION_MENSUAL
   Una fila por alojamiento y mes (60 alojamientos × 36 meses): habitaciones,
   noches disponibles, noches ocupadas y % de ocupación. Calcularla en vivo
   exige expandir cada línea de reserva en sus noches (unas 100.000 filas
   cruzadas con CALENDARIO); la vista guarda el resultado ya agregado y la
   gerencia lo consulta al instante.

   POLÍTICA DE REFRESCO: COMPLETE, ON DEMAND, programada cada noche a las 2 a. m.
   - Por qué no FAST (incremental): exige registros de cambios (MATERIALIZED
     VIEW LOG) y una consulta que Oracle sepa actualizar por partes; esta une
     las reservas con el calendario por RANGO de fechas
     (c.fecha >= checkin AND c.fecha < checkout) y agrega sobre eso, algo que
     el refresco rápido no admite.
   - Por qué no ON COMMIT: recalcularía la ocupación de todo el departamento
     dentro de CADA transacción de reserva, haciendo lenta la operación de
     venta, que es la más importante del negocio.
   - Por qué basta una vez al día: la ocupación mensual es un indicador de
     gestión para decidir precios y campañas; un día de retraso no cambia
     ninguna decisión. A las 2 a. m. casi no hay reservas en curso.
   - Cuando haga falta el dato al minuto (por ejemplo, al cerrar el mes) se
     refresca a mano: EXEC DBMS_MVIEW.REFRESH('MV_OCUPACION_MENSUAL', 'C');
   - atomic_refresh => TRUE: el refresco borra e inserta dentro de una sola
     transacción, así que quien consulte durante el refresco sigue viendo los
     datos anteriores y nunca una vista vacía.
   ============================================================================= */
CREATE MATERIALIZED VIEW mv_ocupacion_mensual
  BUILD IMMEDIATE
  REFRESH COMPLETE ON DEMAND
AS
SELECT a.id_alojamiento,
       a.nombre_comercial,
       m.nombre                                       AS municipio,
       ta.nombre                                      AS tipo_alojamiento,
       cm.anio,
       cm.mes,
       h.habitaciones,
       cm.dias,
       h.habitaciones * cm.dias                       AS noches_disponibles,
       NVL(o.noches_ocupadas, 0)                      AS noches_ocupadas,
       ROUND(100 * NVL(o.noches_ocupadas, 0) / (h.habitaciones * cm.dias), 2)
                                                      AS pct_ocupacion
  FROM alojamiento a
  JOIN municipio        m  ON m.id_municipio         = a.id_municipio
  JOIN tipo_alojamiento ta ON ta.id_tipo_alojamiento = a.id_tipo_alojamiento
  JOIN (SELECT id_alojamiento, COUNT(*) AS habitaciones
          FROM habitacion
         GROUP BY id_alojamiento) h
    ON h.id_alojamiento = a.id_alojamiento
 CROSS JOIN (SELECT anio, mes, COUNT(*) AS dias
               FROM calendario
              GROUP BY anio, mes) cm
  LEFT JOIN (SELECT rh.id_alojamiento, c.anio, c.mes, COUNT(*) AS noches_ocupadas
               FROM reserva_habitacion rh
               JOIN reserva    r ON r.id_reserva = rh.id_reserva
                                AND r.estado IN ('CONFIRMADA', 'COMPLETADA')
               JOIN calendario c ON c.fecha >= rh.fecha_checkin
                                AND c.fecha <  rh.fecha_checkout
              GROUP BY rh.id_alojamiento, c.anio, c.mes) o
    ON o.id_alojamiento = a.id_alojamiento
   AND o.anio = cm.anio
   AND o.mes  = cm.mes;

COMMENT ON MATERIALIZED VIEW mv_ocupacion_mensual IS 'Ocupación mensual por alojamiento. Refresco COMPLETE ON DEMAND programado a las 2 a. m. (JOB_REFRESCO_MV_OCUPACION).';

-- 2.1 Refresco nocturno programado con DBMS_SCHEDULER.
BEGIN
  DBMS_SCHEDULER.CREATE_JOB(
    job_name        => 'JOB_REFRESCO_MV_OCUPACION',
    job_type        => 'PLSQL_BLOCK',
    job_action      => 'BEGIN DBMS_MVIEW.REFRESH(list => ''MV_OCUPACION_MENSUAL'', '
                       || 'method => ''C'', atomic_refresh => TRUE); END;',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=DAILY; BYHOUR=2; BYMINUTE=0; BYSECOND=0',
    enabled         => TRUE,
    comments        => 'Refresco completo nocturno de MV_OCUPACION_MENSUAL (TurismoUQ).');
END;
/

/* -----------------------------------------------------------------------------
   3. Verificación
   ----------------------------------------------------------------------------- */
-- 3.1 La tabla del histórico y su índice viven en el tablespace propio.
SELECT segment_name, segment_type, tablespace_name,
       ROUND(bytes / 1024 / 1024, 2) AS mb
  FROM user_segments
 WHERE segment_name IN ('HIST_RESERVA', 'PK_HIST_RESERVA')
 ORDER BY segment_name;

SELECT COUNT(*) AS lineas_archivadas,
       MIN(fecha_checkout) AS desde,
       MAX(fecha_checkout) AS hasta
  FROM hist_reserva;

-- 3.2 Definición de la vista materializada y su política.
SELECT mview_name, build_mode, refresh_method, refresh_mode,
       last_refresh_type, last_refresh_date, staleness
  FROM user_mviews
 WHERE mview_name = 'MV_OCUPACION_MENSUAL';

SELECT job_name, enabled, state, repeat_interval, next_run_date
  FROM user_scheduler_jobs
 WHERE job_name = 'JOB_REFRESCO_MV_OCUPACION';

SELECT COUNT(*) AS filas_mv FROM mv_ocupacion_mensual;

PROMPT === 07_historico_y_vista_materializada.sql terminado ===
