/* =============================================================================
   TurismoUQ · Script 03 · Consultas de análisis para la gerencia
   Requiere: 01_ddl.sql y 02_carga_datos.sql ejecutados.
   Ejecutar con F5 (Ejecutar script) en SQL Developer: la consulta 5 usa
   VARIABLE / EXEC para las variables de enlace.

   Definiciones usadas en todas las consultas:
     - Reserva "efectiva": estado CONFIRMADA o COMPLETADA. Las PENDIENTES aún no
       ocupan la habitación y las CANCELADAS no se hospedaron.
     - Noche ocupada: cada fecha d con checkin <= d < checkout de una línea de
       RESERVA_HABITACION (el día de salida no se cobra ni se ocupa).
     - Ingreso por temporada: cada noche se valora con la TARIFA de la
       temporada a la que pertenece ESE día (CALENDARIO), no la del check-in.
   ============================================================================= */

SET SERVEROUTPUT ON
SET DEFINE OFF

/* =============================================================================
   CONSULTA 1 · Ocupación por municipio y mes (PIVOT)
   Pregunta: ¿qué porcentaje de las noches disponibles se vendió en cada
   municipio, mes a mes?
     ocupación = noches ocupadas / (habitaciones del municipio × días del mes)
   Las filas son municipio-año; PIVOT convierte los 12 meses en columnas.
   ============================================================================= */
WITH noches_ocupadas AS (
  SELECT a.id_municipio, c.anio, c.mes, COUNT(*) AS noches
    FROM reserva_habitacion rh
    JOIN reserva     r ON r.id_reserva     = rh.id_reserva
                      AND r.estado IN ('CONFIRMADA', 'COMPLETADA')
    JOIN alojamiento a ON a.id_alojamiento = rh.id_alojamiento
    JOIN calendario  c ON c.fecha >= rh.fecha_checkin
                      AND c.fecha <  rh.fecha_checkout
   GROUP BY a.id_municipio, c.anio, c.mes
),
noches_disponibles AS (
  SELECT hm.id_municipio, cm.anio, cm.mes, hm.habitaciones * cm.dias AS noches
    FROM (SELECT a.id_municipio, COUNT(*) AS habitaciones
            FROM habitacion h
            JOIN alojamiento a ON a.id_alojamiento = h.id_alojamiento
           GROUP BY a.id_municipio) hm
   CROSS JOIN (SELECT anio, mes, COUNT(*) AS dias
                 FROM calendario GROUP BY anio, mes) cm
),
ocupacion AS (
  SELECT m.nombre AS municipio,
         d.anio,
         d.mes,
         ROUND(100 * NVL(o.noches, 0) / d.noches, 1) AS pct_ocupacion
    FROM noches_disponibles d
    JOIN municipio m ON m.id_municipio = d.id_municipio
    LEFT JOIN noches_ocupadas o
           ON o.id_municipio = d.id_municipio AND o.anio = d.anio AND o.mes = d.mes
)
SELECT *
  FROM ocupacion
 PIVOT (MAX(pct_ocupacion)
        FOR mes IN (1 AS ene, 2 AS feb, 3 AS mar, 4 AS abr, 5 AS may, 6 AS jun,
                    7 AS jul, 8 AS ago, 9 AS sep, 10 AS oct, 11 AS nov, 12 AS dic))
 ORDER BY anio, municipio;


/* =============================================================================
   CONSULTA 2 · Ingresos por municipio, tipo de alojamiento y temporada
                (ROLLUP + GROUPING)
   Pregunta: ¿cuánto ingresa cada tipo de alojamiento de cada municipio en
   temporada alta, media y baja, con subtotales por tipo, por municipio y el
   total del departamento?
   - Estadía: cada noche vendida se valora con su tarifa y se asigna a la
     categoría de temporada de ESA noche (una estadía del 20 al 26 de diciembre
     reparte su ingreso entre MEDIA y ALTA).
   - Servicios: se asignan a la temporada del día de llegada.
   GROUPING(col) = 1 indica que la fila es un subtotal sobre esa columna;
   con eso se etiquetan las filas de subtotal en lugar de mostrar NULL.
   ============================================================================= */
WITH ingresos AS (
  -- estadía, noche por noche
  SELECT rh.id_alojamiento, te.categoria, tf.valor_noche AS valor
    FROM reserva_habitacion rh
    JOIN reserva    r  ON r.id_reserva = rh.id_reserva
                      AND r.estado IN ('CONFIRMADA', 'COMPLETADA')
    JOIN calendario c  ON c.fecha >= rh.fecha_checkin
                      AND c.fecha <  rh.fecha_checkout
    JOIN tarifa     tf ON tf.id_habitacion = rh.id_habitacion
                      AND tf.id_temporada  = c.id_temporada
    JOIN temporada  te ON te.id_temporada  = c.id_temporada
  UNION ALL
  -- servicios, en la temporada del check-in
  SELECT rs.id_alojamiento, te.categoria, rs.subtotal
    FROM reserva_servicio rs
    JOIN reserva    r  ON r.id_reserva = rs.id_reserva
                      AND r.estado IN ('CONFIRMADA', 'COMPLETADA')
    JOIN calendario c  ON c.fecha = r.fecha_checkin
    JOIN temporada  te ON te.id_temporada = c.id_temporada
)
SELECT CASE WHEN GROUPING(m.nombre) = 1 THEN 'TOTAL QUINDÍO'
            ELSE m.nombre END                                AS municipio,
       CASE WHEN GROUPING(m.nombre) = 1 THEN NULL
            WHEN GROUPING(ta.nombre) = 1 THEN '* Subtotal municipio'
            ELSE ta.nombre END                               AS tipo_alojamiento,
       CASE WHEN GROUPING(ta.nombre) = 1 THEN NULL
            WHEN GROUPING(i.categoria) = 1 THEN '* Subtotal tipo'
            ELSE i.categoria END                             AS temporada,
       GROUPING(m.nombre)    AS g_municipio,
       GROUPING(ta.nombre)   AS g_tipo,
       GROUPING(i.categoria) AS g_temporada,
       SUM(i.valor)          AS ingresos
  FROM ingresos i
  JOIN alojamiento      a  ON a.id_alojamiento       = i.id_alojamiento
  JOIN municipio        m  ON m.id_municipio         = a.id_municipio
  JOIN tipo_alojamiento ta ON ta.id_tipo_alojamiento = a.id_tipo_alojamiento
 GROUP BY ROLLUP (m.nombre, ta.nombre, i.categoria)
 ORDER BY GROUPING(m.nombre), m.nombre,
          GROUPING(ta.nombre), ta.nombre,
          GROUPING(i.categoria), DECODE(i.categoria, 'ALTA', 1, 'MEDIA', 2, 'BAJA', 3);


/* =============================================================================
   CONSULTA 3 · Los 3 alojamientos de mayor ingreso dentro de cada municipio
                (RANK con PARTITION BY)
   Pregunta: ¿cuáles son los alojamientos más rentables de cada municipio y
   qué parte del ingreso del municipio concentran?
   Ingreso = estadía + servicios de las reservas efectivas (vista
   vw_valor_reserva). RANK reinicia la numeración en cada municipio y da el
   mismo puesto a empates. Los municipios con un solo alojamiento muestran
   una sola fila.
   ============================================================================= */
WITH ingreso_alojamiento AS (
  SELECT a.id_municipio,
         a.id_alojamiento,
         a.nombre_comercial,
         ta.nombre            AS tipo,
         COUNT(*)             AS reservas,
         SUM(v.valor_total)   AS ingresos
    FROM vw_valor_reserva v
    JOIN alojamiento      a  ON a.id_alojamiento       = v.id_alojamiento
    JOIN tipo_alojamiento ta ON ta.id_tipo_alojamiento = a.id_tipo_alojamiento
   WHERE v.estado IN ('CONFIRMADA', 'COMPLETADA')
   GROUP BY a.id_municipio, a.id_alojamiento, a.nombre_comercial, ta.nombre
),
ranking AS (
  SELECT m.nombre AS municipio,
         i.nombre_comercial,
         i.tipo,
         i.reservas,
         i.ingresos,
         ROUND(100 * i.ingresos / SUM(i.ingresos) OVER (PARTITION BY i.id_municipio), 1)
                                                         AS pct_del_municipio,
         RANK() OVER (PARTITION BY i.id_municipio ORDER BY i.ingresos DESC) AS puesto
    FROM ingreso_alojamiento i
    JOIN municipio m ON m.id_municipio = i.id_municipio
)
SELECT municipio, puesto, nombre_comercial, tipo, reservas, ingresos, pct_del_municipio
  FROM ranking
 WHERE puesto <= 3
 ORDER BY municipio, puesto;


/* =============================================================================
   CONSULTA 4 · Variación del recaudo mes contra mes (LAG)
   Pregunta: ¿cuánto dinero entró cada mes y cuánto cambió frente al mes
   anterior (y frente al mismo mes del año anterior)?
   Recaudo neto del mes = pagos EXITOSOS o luego REEMBOLSADOS (por fecha de
   pago) − reembolsos devueltos (por fecha de reembolso).
   LAG(x)     → valor del mes anterior.
   LAG(x, 12) → valor del mismo mes del año anterior (estacionalidad).
   ============================================================================= */
WITH movimientos AS (
  SELECT TRUNC(fecha_pago, 'MM') AS mes, monto AS valor
    FROM pago
   WHERE estado IN ('EXITOSO', 'REEMBOLSADO')
  UNION ALL
  SELECT TRUNC(fecha_reembolso, 'MM'), -monto_reembolsado
    FROM pago
   WHERE estado = 'REEMBOLSADO'
),
mensual AS (
  SELECT mes, SUM(valor) AS recaudo
    FROM movimientos
   GROUP BY mes
)
SELECT TO_CHAR(mes, 'YYYY-MM')                                 AS mes,
       recaudo,
       LAG(recaudo) OVER (ORDER BY mes)                        AS recaudo_mes_anterior,
       recaudo - LAG(recaudo) OVER (ORDER BY mes)              AS variacion,
       ROUND(100 * (recaudo - LAG(recaudo) OVER (ORDER BY mes))
             / NULLIF(LAG(recaudo) OVER (ORDER BY mes), 0), 1) AS variacion_pct,
       LAG(recaudo, 12) OVER (ORDER BY mes)                    AS recaudo_mismo_mes_anio_ant,
       ROUND(100 * (recaudo - LAG(recaudo, 12) OVER (ORDER BY mes))
             / NULLIF(LAG(recaudo, 12) OVER (ORDER BY mes), 0), 1) AS variacion_anual_pct
  FROM mensual
 ORDER BY mes;
-- Nota: LAG(recaudo, 12) supone que hay recaudo todos los meses, lo que se
-- cumple con estos datos (enero 2024 a octubre 2026 sin meses vacíos).


/* =============================================================================
   CONSULTA 5 · Desempeño de los alojamientos en un rango de fechas
                (consulta parametrizada con variables de enlace)
   Pregunta: entre :fecha_ini y :fecha_fin (ambas incluidas), ¿cuántas noches
   vendió cada alojamiento, con qué ocupación y cuánto ingresó por estadía?
   Solo cuenta las noches que caen dentro del rango, aunque la reserva empiece
   antes o termine después.
   Con variables de enlace el plan de ejecución se reutiliza al cambiar las
   fechas (no se re-analiza la sentencia) y se evita inyección SQL.
   Para otro rango basta cambiar los EXEC (ej. Semana Santa 2025:
   '2025-04-12' a '2025-04-20').
   ============================================================================= */
VARIABLE fecha_ini VARCHAR2(10)
VARIABLE fecha_fin VARCHAR2(10)
EXEC :fecha_ini := '2025-12-15';
EXEC :fecha_fin := '2026-01-12';

SELECT m.nombre                                   AS municipio,
       a.nombre_comercial,
       ta.nombre                                  AS tipo,
       NVL(v.reservas, 0)                         AS reservas,
       NVL(v.noches_vendidas, 0)                  AS noches_vendidas,
       h.habitaciones * (TO_DATE(:fecha_fin, 'YYYY-MM-DD')
                         - TO_DATE(:fecha_ini, 'YYYY-MM-DD') + 1)
                                                  AS noches_disponibles,
       ROUND(100 * NVL(v.noches_vendidas, 0)
             / (h.habitaciones * (TO_DATE(:fecha_fin, 'YYYY-MM-DD')
                                  - TO_DATE(:fecha_ini, 'YYYY-MM-DD') + 1)), 1)
                                                  AS pct_ocupacion,
       NVL(v.ingreso_estadia, 0)                  AS ingreso_estadia
  FROM alojamiento a
  JOIN municipio        m  ON m.id_municipio         = a.id_municipio
  JOIN tipo_alojamiento ta ON ta.id_tipo_alojamiento = a.id_tipo_alojamiento
  JOIN (SELECT id_alojamiento, COUNT(*) AS habitaciones
          FROM habitacion GROUP BY id_alojamiento) h
    ON h.id_alojamiento = a.id_alojamiento
  LEFT JOIN (SELECT rh.id_alojamiento,
                    COUNT(DISTINCT rh.id_reserva) AS reservas,
                    COUNT(*)                      AS noches_vendidas,
                    SUM(tf.valor_noche)           AS ingreso_estadia
               FROM reserva_habitacion rh
               JOIN reserva    r  ON r.id_reserva = rh.id_reserva
                                 AND r.estado IN ('CONFIRMADA', 'COMPLETADA')
               JOIN calendario c  ON c.fecha >= rh.fecha_checkin
                                 AND c.fecha <  rh.fecha_checkout
               JOIN tarifa     tf ON tf.id_habitacion = rh.id_habitacion
                                 AND tf.id_temporada  = c.id_temporada
              WHERE c.fecha BETWEEN TO_DATE(:fecha_ini, 'YYYY-MM-DD')
                                AND TO_DATE(:fecha_fin, 'YYYY-MM-DD')
              GROUP BY rh.id_alojamiento) v
    ON v.id_alojamiento = a.id_alojamiento
 ORDER BY pct_ocupacion DESC, ingreso_estadia DESC;


/* =============================================================================
   CONSULTA 6 · Indicadores de cada municipio en formato largo (UNPIVOT)
   Pregunta: para 2025, ¿cuáles son los indicadores clave de cada municipio
   (reservas, noches, huéspedes, ingreso por estadía y por servicios)?
   Primero se calculan en formato ancho (una columna por indicador) y UNPIVOT
   los convierte en filas (municipio, indicador, valor): el formato que
   necesita un tablero o una herramienta de gráficos para filtrar por
   indicador.
   ============================================================================= */
WITH estadia AS (
  SELECT a.id_municipio,
         COUNT(DISTINCT r.id_reserva)                   AS reservas,
         SUM(rh.fecha_checkout - rh.fecha_checkin)      AS noches_vendidas,
         SUM(rh.num_huespedes)                          AS huespedes,
         SUM(rh.valor_estadia)                          AS ingreso_estadia
    FROM reserva r
    JOIN reserva_habitacion rh ON rh.id_reserva     = r.id_reserva
    JOIN alojamiento        a  ON a.id_alojamiento  = r.id_alojamiento
   WHERE r.estado IN ('CONFIRMADA', 'COMPLETADA')
     AND r.fecha_checkin >= DATE '2025-01-01'
     AND r.fecha_checkin <  DATE '2026-01-01'
   GROUP BY a.id_municipio
),
servicios AS (
  SELECT a.id_municipio, SUM(rs.subtotal) AS ingreso_servicios
    FROM reserva r
    JOIN reserva_servicio rs ON rs.id_reserva    = r.id_reserva
    JOIN alojamiento      a  ON a.id_alojamiento = r.id_alojamiento
   WHERE r.estado IN ('CONFIRMADA', 'COMPLETADA')
     AND r.fecha_checkin >= DATE '2025-01-01'
     AND r.fecha_checkin <  DATE '2026-01-01'
   GROUP BY a.id_municipio
),
ancho AS (
  SELECT m.nombre AS municipio,
         e.reservas, e.noches_vendidas, e.huespedes, e.ingreso_estadia,
         NVL(s.ingreso_servicios, 0) AS ingreso_servicios
    FROM estadia e
    JOIN municipio m      ON m.id_municipio = e.id_municipio
    LEFT JOIN servicios s ON s.id_municipio = e.id_municipio
)
SELECT municipio, indicador, valor
  FROM ancho
UNPIVOT (valor FOR indicador IN (reservas          AS 'Reservas',
                                 noches_vendidas   AS 'Noches vendidas',
                                 huespedes         AS 'Huéspedes',
                                 ingreso_estadia   AS 'Ingreso por estadía',
                                 ingreso_servicios AS 'Ingreso por servicios'))
 ORDER BY municipio, indicador;


/* =============================================================================
   CONSULTA 7 · Consulta libre: ¿las estrellas que se autoasigna cada
                alojamiento coinciden con lo que opinan sus huéspedes?
   Pregunta de negocio: la plataforma muestra las estrellas que el propio
   alojamiento declara. ¿Qué alojamientos prometen más de lo que entregan
   (riesgo de quejas) y cuáles entregan más de lo que prometen (candidatos a
   destacar en la portada)?
   - Promedio de reseñas, % de 5 estrellas y % de negativas (1-2).
   - brecha = promedio de reseñas − estrellas autoasignadas.
   - Puesto dentro de su tipo de alojamiento (DENSE_RANK).
   - Solo alojamientos con al menos 20 reseñas, para que el promedio sea fiable.
   ============================================================================= */
WITH calificacion AS (
  SELECT r.id_alojamiento,
         COUNT(*)                                                  AS resenas,
         ROUND(AVG(s.calificacion), 2)                             AS promedio,
         ROUND(100 * AVG(CASE WHEN s.calificacion = 5 THEN 1 ELSE 0 END), 1) AS pct_5_estrellas,
         ROUND(100 * AVG(CASE WHEN s.calificacion <= 2 THEN 1 ELSE 0 END), 1) AS pct_negativas
    FROM resena s
    JOIN reserva r ON r.id_reserva = s.id_reserva
   GROUP BY r.id_alojamiento
  HAVING COUNT(*) >= 20
)
SELECT a.nombre_comercial,
       ta.nombre                      AS tipo,
       m.nombre                       AS municipio,
       a.estrellas                    AS estrellas_declaradas,
       c.promedio                     AS calificacion_huespedes,
       c.promedio - a.estrellas       AS brecha,
       CASE WHEN c.promedio - a.estrellas <= -1   THEN 'Promete más de lo que entrega'
            WHEN c.promedio - a.estrellas >= 0.5  THEN 'Supera lo que promete'
            ELSE 'Coherente' END      AS diagnostico,
       c.resenas,
       c.pct_5_estrellas,
       c.pct_negativas,
       DENSE_RANK() OVER (PARTITION BY ta.nombre ORDER BY c.promedio DESC) AS puesto_en_su_tipo
  FROM calificacion c
  JOIN alojamiento      a  ON a.id_alojamiento       = c.id_alojamiento
  JOIN tipo_alojamiento ta ON ta.id_tipo_alojamiento = a.id_tipo_alojamiento
  JOIN municipio        m  ON m.id_municipio         = a.id_municipio
 ORDER BY brecha;
