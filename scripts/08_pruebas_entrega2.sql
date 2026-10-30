/* =============================================================================
   TurismoUQ · Script 08 · Pruebas y evidencias de la Entrega 2
   Requiere: 01 a 07 ejecutados. Ejecutar COMPLETO con F5 como dueño del
   esquema. Cada caso imprime "PASA" o "FALLA"; busque FALLA en la salida.

   Para guardar la evidencia en un archivo, quite el comentario de SPOOL
   (al inicio y al final) o copie la pestaña "Salida de script".

   Las pruebas usan fechas de diciembre de 2026 (deben ser futuras para
   sp_crear_reserva) y eligen solas una habitación libre. Todo lo que crean lo
   deshacen (ROLLBACK) o lo borran al final, salvo:
     - las filas de AUDITORIA_TARIFA (son la evidencia; la tarifa se restaura)
     - la liquidación de diciembre de 2025 en LIQUIDACION_MENSUAL
     - el histórico de la primera mitad de 2025 en HIST_RESERVA
   ============================================================================= */

-- SPOOL evidencia_entrega2.txt
SET SERVEROUTPUT ON SIZE UNLIMITED
SET DEFINE OFF
SET LINESIZE 200
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';

VARIABLE v_hab  NUMBER
VARIABLE v_hab2 NUMBER
VARIABLE v_aloj NUMBER
VARIABLE v_cap  NUMBER
VARIABLE v_cli  NUMBER

/* =============================================================================
   0. PREPARACIÓN: una habitación (y otra del mismo alojamiento) libres del
      10 al 20 de diciembre de 2026, con capacidad para 2 o más huéspedes.
   ============================================================================= */
BEGIN
  SELECT id_habitacion, id_alojamiento, capacidad_maxima
    INTO :v_hab, :v_aloj, :v_cap
    FROM habitacion h
   WHERE h.capacidad_maxima >= 2
     AND h.activa = 'S'
     AND pkg_reservas.fn_disponible(h.id_habitacion, DATE '2026-12-10', DATE '2026-12-20') = 'S'
     AND EXISTS (SELECT 1 FROM habitacion h2
                  WHERE h2.id_alojamiento = h.id_alojamiento
                    AND h2.id_habitacion <> h.id_habitacion
                    AND h2.capacidad_maxima >= 2
                    AND pkg_reservas.fn_disponible(h2.id_habitacion, DATE '2026-12-10', DATE '2026-12-20') = 'S')
     AND ROWNUM = 1;            -- la primera que cumpla

  SELECT MIN(id_habitacion) INTO :v_hab2
    FROM habitacion
   WHERE id_alojamiento = :v_aloj
     AND id_habitacion <> :v_hab
     AND capacidad_maxima >= 2
     AND pkg_reservas.fn_disponible(id_habitacion, DATE '2026-12-10', DATE '2026-12-20') = 'S';

  SELECT MIN(id_cliente) INTO :v_cli FROM cliente;

  DBMS_OUTPUT.PUT_LINE('Datos de prueba: habitación ' || :v_hab || ' (capacidad ' || :v_cap
    || '), segunda habitación ' || :v_hab2 || ', alojamiento ' || :v_aloj || ', cliente ' || :v_cli);
END;
/

/* =============================================================================
   PRUEBA 1 · fn_valor_estadia (cálculo noche por noche entre temporadas)
   En el calendario cargado, el 15 de diciembre empieza la temporada ALTA:
   del 12 al 17 de diciembre de 2026 hay 3 noches MEDIA (12, 13, 14) y 2 ALTA
   (15, 16). El día 17 es la salida y no se cobra.
   ============================================================================= */
PROMPT
PROMPT ===== PRUEBA 1 · fn_valor_estadia =====
EXEC pkg_reservas.sp_detalle_estadia(:v_hab, DATE '2026-12-12', DATE '2026-12-17');
EXEC pkg_reservas.sp_detalle_estadia(:v_hab, DATE '2025-12-30', DATE '2026-01-02');

-- Se puede usar directamente desde SQL:
SELECT :v_hab AS habitacion,
       pkg_reservas.fn_valor_estadia(:v_hab, DATE '2026-12-12', DATE '2026-12-17') AS valor_cruce_temporadas,
       pkg_reservas.fn_valor_estadia(:v_hab, DATE '2026-12-01', DATE '2026-12-04') AS valor_una_temporada
  FROM dual;

DECLARE
  v_valor   NUMBER;
  v_media   NUMBER;
  v_alta    NUMBER;
  v_t1      NUMBER;
  v_t2      NUMBER;
  PROCEDURE ok(p_cond BOOLEAN, p_caso VARCHAR2) IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN p_cond THEN 'PASA   ' ELSE 'FALLA  ' END || p_caso);
  END;
  FUNCTION tarifa_dia(p_fecha DATE) RETURN NUMBER IS
    v NUMBER;
  BEGIN
    SELECT t.valor_noche INTO v
      FROM tarifa t JOIN calendario c ON c.id_temporada = t.id_temporada
     WHERE c.fecha = p_fecha AND t.id_habitacion = :v_hab;
    RETURN v;
  END;
BEGIN
  v_media := tarifa_dia(DATE '2026-12-12');
  v_alta  := tarifa_dia(DATE '2026-12-15');

  v_valor := pkg_reservas.fn_valor_estadia(:v_hab, DATE '2026-12-12', DATE '2026-12-17');
  ok(v_valor = 3 * v_media + 2 * v_alta,
     '1.1 Cruce MEDIA->ALTA: 3 x ' || v_media || ' + 2 x ' || v_alta || ' = ' || v_valor);

  v_valor := pkg_reservas.fn_valor_estadia(:v_hab, DATE '2026-12-01', DATE '2026-12-04');
  ok(v_valor = 3 * v_media, '1.2 Una sola temporada: 3 x ' || v_media || ' = ' || v_valor);

  v_t1 := tarifa_dia(DATE '2025-12-30');
  v_t2 := tarifa_dia(DATE '2026-01-01');
  v_valor := pkg_reservas.fn_valor_estadia(:v_hab, DATE '2025-12-30', DATE '2026-01-02');
  ok(v_valor = 2 * v_t1 + v_t2,
     '1.3 Cruce de año: 2 x ' || v_t1 || ' (2025) + 1 x ' || v_t2 || ' (2026) = ' || v_valor);

  v_valor := pkg_reservas.fn_valor_estadia(:v_hab, DATE '2026-12-15', DATE '2026-12-16');
  ok(v_valor = v_alta, '1.4 Una noche = tarifa de esa noche (' || v_valor || ')');

  BEGIN
    v_valor := pkg_reservas.fn_valor_estadia(:v_hab, DATE '2026-12-12', DATE '2026-12-12');
    ok(FALSE, '1.5 Check-out igual al check-in debía fallar');
  EXCEPTION WHEN OTHERS THEN
    ok(SQLCODE = -20102, '1.5 Check-out = check-in  -> ' || SQLERRM);
  END;

  BEGIN
    v_valor := pkg_reservas.fn_valor_estadia(:v_hab, DATE '2026-12-17', DATE '2026-12-12');
    ok(FALSE, '1.6 Check-out anterior al check-in debía fallar');
  EXCEPTION WHEN OTHERS THEN
    ok(SQLCODE = -20102, '1.6 Check-out < check-in  -> ' || SQLERRM);
  END;

  BEGIN
    v_valor := pkg_reservas.fn_valor_estadia(:v_hab, DATE '2026-12-30', DATE '2027-01-03');
    ok(FALSE, '1.7 Fechas fuera del calendario debían fallar');
  EXCEPTION WHEN OTHERS THEN
    ok(SQLCODE = -20106, '1.7 Fuera del calendario   -> ' || SQLERRM);
  END;

  BEGIN
    v_valor := pkg_reservas.fn_valor_estadia(-1, DATE '2026-12-12', DATE '2026-12-17');
    ok(FALSE, '1.8 Habitación inexistente debía fallar');
  EXCEPTION WHEN OTHERS THEN
    ok(SQLCODE = -20104, '1.8 Habitación inexistente -> ' || SQLERRM);
  END;
END;
/

/* =============================================================================
   PRUEBA 2 · sp_crear_reserva y sp_agregar_habitacion
   ============================================================================= */
PROMPT
PROMPT ===== PRUEBA 2 · sp_crear_reserva =====
DECLARE
  v_id        reserva.id_reserva%TYPE;
  v_id2       reserva.id_reserva%TYPE;
  v_estado    reserva.estado%TYPE;
  v_valor     NUMBER;
  v_lineas    PLS_INTEGER;
  v_out       DATE;
  v_antes     PLS_INTEGER;
  v_despues   PLS_INTEGER;
  v_cap2      NUMBER;
  v_otra_hab  NUMBER;
  PROCEDURE ok(p_cond BOOLEAN, p_caso VARCHAR2) IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN p_cond THEN 'PASA   ' ELSE 'FALLA  ' END || p_caso);
  END;
BEGIN
  SELECT capacidad_maxima INTO v_cap2 FROM habitacion WHERE id_habitacion = :v_hab2;

  -- 2.1 Reserva válida
  pkg_reservas.sp_crear_reserva(:v_cli, :v_hab, DATE '2026-12-12', DATE '2026-12-17', 2, v_id);
  SELECT r.estado, rh.valor_estadia INTO v_estado, v_valor
    FROM reserva r JOIN reserva_habitacion rh ON rh.id_reserva = r.id_reserva
   WHERE r.id_reserva = v_id;
  ok(v_id IS NOT NULL AND v_estado = 'PENDIENTE'
     AND v_valor = pkg_reservas.fn_valor_estadia(:v_hab, DATE '2026-12-12', DATE '2026-12-17'),
     '2.1 Reserva creada: id ' || v_id || ', estado ' || v_estado || ', valor ' || v_valor
     || ' (= fn_valor_estadia)');

  SELECT COUNT(*) INTO v_antes FROM reserva;

  -- 2.2 Habitación no disponible (se cruza con 2.1)
  BEGIN
    pkg_reservas.sp_crear_reserva(:v_cli, :v_hab, DATE '2026-12-14', DATE '2026-12-16', 2, v_id2);
    ok(FALSE, '2.2 Debía rechazar por no disponible');
  EXCEPTION WHEN OTHERS THEN
    ok(SQLCODE = -20101, '2.2 No disponible -> ' || SQLERRM);
  END;

  -- 2.3 Captura por nombre de la excepción del paquete
  BEGIN
    pkg_reservas.sp_crear_reserva(:v_cli, :v_hab, DATE '2026-12-16', DATE '2026-12-19', 1, v_id2);
    ok(FALSE, '2.3 Debía lanzar e_no_disponible');
  EXCEPTION WHEN pkg_reservas.e_no_disponible THEN
    ok(TRUE, '2.3 Capturada como pkg_reservas.e_no_disponible');
  END;

  -- 2.4 Check-out anterior o igual al check-in
  BEGIN
    pkg_reservas.sp_crear_reserva(:v_cli, :v_hab2, DATE '2026-12-20', DATE '2026-12-18', 2, v_id2);
    ok(FALSE, '2.4 Debía rechazar las fechas');
  EXCEPTION WHEN OTHERS THEN
    ok(SQLCODE = -20102, '2.4 Check-out < check-in -> ' || SQLERRM);
  END;
  BEGIN
    pkg_reservas.sp_crear_reserva(:v_cli, :v_hab2, DATE '2026-12-18', DATE '2026-12-18', 2, v_id2);
    ok(FALSE, '2.5 Debía rechazar las fechas');
  EXCEPTION WHEN OTHERS THEN
    ok(SQLCODE = -20102, '2.5 Check-out = check-in -> ' || SQLERRM);
  END;

  -- 2.6 Capacidad excedida (habitación libre, un huésped más de su capacidad)
  BEGIN
    pkg_reservas.sp_crear_reserva(:v_cli, :v_hab2, DATE '2026-12-12', DATE '2026-12-14', v_cap2 + 1, v_id2);
    ok(FALSE, '2.6 Debía rechazar por capacidad');
  EXCEPTION WHEN OTHERS THEN
    ok(SQLCODE = -20103, '2.6 Capacidad excedida -> ' || SQLERRM);
  END;

  -- 2.7 Otras validaciones del procedimiento
  BEGIN
    pkg_reservas.sp_crear_reserva(-1, :v_hab2, DATE '2026-12-12', DATE '2026-12-14', 1, v_id2);
    ok(FALSE, '2.7 Debía rechazar el cliente');
  EXCEPTION WHEN OTHERS THEN
    ok(SQLCODE = -20105, '2.7 Cliente inexistente -> ' || SQLERRM);
  END;
  BEGIN
    pkg_reservas.sp_crear_reserva(:v_cli, :v_hab2, DATE '2025-06-01', DATE '2025-06-03', 1, v_id2);
    ok(FALSE, '2.8 Debía rechazar fechas pasadas');
  EXCEPTION WHEN OTHERS THEN
    ok(SQLCODE = -20107, '2.8 Check-in en el pasado -> ' || SQLERRM);
  END;

  -- 2.9 Los intentos fallidos no dejaron reservas a medias (ROLLBACK TO SAVEPOINT)
  SELECT COUNT(*) INTO v_despues FROM reserva;
  ok(v_antes = v_despues, '2.9 Los 7 intentos fallidos no dejaron filas: reservas antes '
     || v_antes || ' = después ' || v_despues || ' (incluye la de 2.1)');

  -- 2.10 Reserva de grupo: segunda habitación que llega un día después y se
  --      va un día más tarde; el rango general se amplía.
  pkg_reservas.sp_agregar_habitacion(v_id, :v_hab2, DATE '2026-12-13', DATE '2026-12-18', 2);
  SELECT COUNT(*) INTO v_lineas FROM reserva_habitacion WHERE id_reserva = v_id;
  SELECT fecha_checkout INTO v_out FROM reserva WHERE id_reserva = v_id;
  ok(v_lineas = 2 AND v_out = DATE '2026-12-18',
     '2.10 Reserva ' || v_id || ' con ' || v_lineas || ' habitaciones, rango hasta ' || TO_CHAR(v_out, 'YYYY-MM-DD'));

  -- 2.11 No se puede agregar una habitación de otro alojamiento
  SELECT id_habitacion INTO v_otra_hab
    FROM habitacion
   WHERE id_alojamiento <> :v_aloj
     AND pkg_reservas.fn_disponible(id_habitacion, DATE '2026-12-12', DATE '2026-12-17') = 'S'
     AND ROWNUM = 1;
  BEGIN
    pkg_reservas.sp_agregar_habitacion(v_id, v_otra_hab, DATE '2026-12-12', DATE '2026-12-17', 1);
    ok(FALSE, '2.11 Debía rechazar la habitación de otro alojamiento');
  EXCEPTION WHEN OTHERS THEN
    ok(SQLCODE = -20110, '2.11 Otro alojamiento -> ' || SQLERRM);
  END;

  ROLLBACK;   -- deja la base como estaba
  DBMS_OUTPUT.PUT_LINE('(ROLLBACK: las reservas de prueba se deshicieron)');
END;
/

/* =============================================================================
   PRUEBA 3 · Disparador de fila trg_rh_sin_solape
   Se inserta DIRECTAMENTE en las tablas, sin pasar por el paquete (como lo
   haría otra aplicación o un script con errores): el disparador debe impedir
   el solape por su cuenta.
   ============================================================================= */
PROMPT
PROMPT ===== PRUEBA 3 · Disparador de fila (solape de reservas) =====
DECLARE
  v_id_a  reserva.id_reserva%TYPE;
  v_id_b  reserva.id_reserva%TYPE;
  v_id_c  reserva.id_reserva%TYPE;
  PROCEDURE ok(p_cond BOOLEAN, p_caso VARCHAR2) IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN p_cond THEN 'PASA   ' ELSE 'FALLA  ' END || p_caso);
  END;
BEGIN
  -- Reserva A ocupa la habitación del 12 al 17 de diciembre de 2026.
  pkg_reservas.sp_crear_reserva(:v_cli, :v_hab, DATE '2026-12-12', DATE '2026-12-17', 2, v_id_a);
  DBMS_OUTPUT.PUT_LINE('Reserva A = ' || v_id_a || ' (habitación ' || :v_hab || ', 2026-12-12 a 2026-12-17)');

  -- Reserva B: encabezado insertado a mano.
  INSERT INTO reserva (id_cliente, id_alojamiento, fecha_reserva, fecha_checkin, fecha_checkout, estado)
  VALUES (:v_cli, :v_aloj, TRUNC(SYSDATE), DATE '2026-12-15', DATE '2026-12-19', 'CONFIRMADA')
  RETURNING id_reserva INTO v_id_b;

  -- 3.1 Línea que se cruza con A (15 al 19): el disparador la rechaza.
  BEGIN
    INSERT INTO reserva_habitacion (id_reserva, id_alojamiento, id_habitacion,
                                    fecha_checkin, fecha_checkout, num_huespedes, valor_estadia)
    VALUES (v_id_b, :v_aloj, :v_hab, DATE '2026-12-15', DATE '2026-12-19', 1, 0);
    ok(FALSE, '3.1 El disparador debía impedir el solape');
  EXCEPTION WHEN OTHERS THEN
    ok(SQLCODE = -20120, '3.1 Solape rechazado -> ' || SQLERRM);
  END;

  -- 3.2 Llegar el mismo día en que A sale (17) NO es solape.
  BEGIN
    INSERT INTO reserva_habitacion (id_reserva, id_alojamiento, id_habitacion,
                                    fecha_checkin, fecha_checkout, num_huespedes, valor_estadia)
    VALUES (v_id_b, :v_aloj, :v_hab, DATE '2026-12-17', DATE '2026-12-19', 1, 0);
    ok(TRUE, '3.2 Llegada el día de salida de A: aceptada');
  EXCEPTION WHEN OTHERS THEN
    ok(FALSE, '3.2 Llegada el día de salida de A debía aceptarse: ' || SQLERRM);
  END;

  -- 3.3 Una reserva CANCELADA no ocupa la habitación: se acepta aunque se cruce.
  INSERT INTO reserva (id_cliente, id_alojamiento, fecha_reserva, fecha_checkin, fecha_checkout,
                       estado, fecha_cancelacion)
  VALUES (:v_cli, :v_aloj, TRUNC(SYSDATE), DATE '2026-12-13', DATE '2026-12-15',
          'CANCELADA', TRUNC(SYSDATE))
  RETURNING id_reserva INTO v_id_c;
  BEGIN
    INSERT INTO reserva_habitacion (id_reserva, id_alojamiento, id_habitacion,
                                    fecha_checkin, fecha_checkout, num_huespedes, valor_estadia)
    VALUES (v_id_c, :v_aloj, :v_hab, DATE '2026-12-13', DATE '2026-12-15', 1, 0);
    ok(TRUE, '3.3 Línea de reserva cancelada que se cruza: aceptada');
  EXCEPTION WHEN OTHERS THEN
    ok(FALSE, '3.3 La reserva cancelada debía aceptarse: ' || SQLERRM);
  END;

  ROLLBACK;
  DBMS_OUTPUT.PUT_LINE('(ROLLBACK: las reservas de prueba se deshicieron)');
END;
/

/* =============================================================================
   PRUEBA 4 · Disparador de sentencia trg_auditoria_tarifa
   Un UPDATE sube 10.000 las tarifas de la habitación en las dos temporadas de
   la estadía de prueba (2 filas) y otro las devuelve. Ambas sentencias quedan
   auditadas; un UPDATE que no cambia el valor no deja rastro.
   ============================================================================= */
PROMPT
PROMPT ===== PRUEBA 4 · Disparador de sentencia (auditoría de TARIFA) =====
DECLARE
  v_ult_sent   NUMBER;
  v_filas      PLS_INTEGER;
  v_aud        PLS_INTEGER;
  v_bien       PLS_INTEGER;
  v_sents      PLS_INTEGER;
  v_antes      NUMBER;
  v_despues    NUMBER;
  PROCEDURE ok(p_cond BOOLEAN, p_caso VARCHAR2) IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN p_cond THEN 'PASA   ' ELSE 'FALLA  ' END || p_caso);
  END;
BEGIN
  SELECT NVL(MAX(id_sentencia), 0) INTO v_ult_sent FROM auditoria_tarifa;
  v_antes := pkg_reservas.fn_valor_estadia(:v_hab, DATE '2026-12-12', DATE '2026-12-17');

  -- 4.1 Subida de tarifas: una sentencia, 2 filas.
  UPDATE tarifa
     SET valor_noche = valor_noche + 10000
   WHERE id_habitacion = :v_hab
     AND id_temporada IN (SELECT id_temporada FROM calendario
                           WHERE fecha IN (DATE '2026-12-12', DATE '2026-12-15'));
  v_filas := SQL%ROWCOUNT;

  SELECT COUNT(*),
         SUM(CASE WHEN operacion = 'UPDATE' AND valor_nuevo - valor_anterior = 10000
                   AND usuario_bd = USER AND filas_sentencia = v_filas THEN 1 ELSE 0 END),
         COUNT(DISTINCT id_sentencia)
    INTO v_aud, v_bien, v_sents
    FROM auditoria_tarifa
   WHERE id_sentencia > v_ult_sent;
  ok(v_filas = 2 AND v_aud = v_filas AND v_bien = v_filas AND v_sents = 1,
     '4.1 UPDATE de ' || v_filas || ' tarifas -> ' || v_aud
     || ' filas de auditoría de 1 sentencia, con usuario, hora, valor anterior y nuevo');

  -- 4.2 Efecto en el cálculo: las 5 noches de la estadía suben 10.000 cada una.
  v_despues := pkg_reservas.fn_valor_estadia(:v_hab, DATE '2026-12-12', DATE '2026-12-17');
  ok(v_despues = v_antes + 50000,
     '4.2 fn_valor_estadia pasó de ' || v_antes || ' a ' || v_despues || ' (+5 noches x 10.000)');

  -- 4.3 UPDATE sin cambio real: no se audita.
  SELECT NVL(MAX(id_sentencia), 0) INTO v_ult_sent FROM auditoria_tarifa;
  UPDATE tarifa SET valor_noche = valor_noche
   WHERE id_habitacion = :v_hab
     AND id_temporada IN (SELECT id_temporada FROM calendario WHERE fecha = DATE '2026-12-12');
  SELECT COUNT(*) INTO v_aud FROM auditoria_tarifa WHERE id_sentencia > v_ult_sent;
  ok(v_aud = 0, '4.3 UPDATE que no cambia el valor: ' || v_aud || ' filas de auditoría');

  -- 4.4 Se restauran las tarifas (también queda auditado).
  UPDATE tarifa
     SET valor_noche = valor_noche - 10000
   WHERE id_habitacion = :v_hab
     AND id_temporada IN (SELECT id_temporada FROM calendario
                           WHERE fecha IN (DATE '2026-12-12', DATE '2026-12-15'));
  v_despues := pkg_reservas.fn_valor_estadia(:v_hab, DATE '2026-12-12', DATE '2026-12-17');
  ok(v_despues = v_antes, '4.4 Tarifas restauradas: valor vuelve a ' || v_despues);

  COMMIT;   -- se conserva la auditoría como evidencia
END;
/

-- Evidencia: últimas filas de la auditoría
SELECT id_auditoria, id_sentencia, operacion, id_tarifa, id_habitacion, id_temporada,
       valor_anterior, valor_nuevo, usuario_bd, usuario_so, equipo, programa,
       TO_CHAR(fecha_hora, 'YYYY-MM-DD HH24:MI:SS.FF3') AS fecha_hora, filas_sentencia
  FROM auditoria_tarifa
 ORDER BY id_auditoria DESC
 FETCH FIRST 6 ROWS ONLY;

/* =============================================================================
   PRUEBA 5 · Cursor explícito con parámetros: liquidación mensual
   ============================================================================= */
PROMPT
PROMPT ===== PRUEBA 5 · Liquidación mensual (cursor con parámetros) =====
EXEC pkg_reservas.sp_liquidacion_mensual(2025, 12);

DECLARE
  v_filas      PLS_INTEGER;
  v_estadia    NUMBER;
  v_esperado   NUMBER;
  v_malas      PLS_INTEGER;
  v_aloj_tot   PLS_INTEGER;
  PROCEDURE ok(p_cond BOOLEAN, p_caso VARCHAR2) IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN p_cond THEN 'PASA   ' ELSE 'FALLA  ' END || p_caso);
  END;
BEGIN
  SELECT COUNT(*) INTO v_aloj_tot FROM alojamiento;
  SELECT COUNT(*), SUM(ingreso_estadia),
         SUM(CASE WHEN neto_alojamiento + comision_plataforma <> total_bruto
                    OR total_bruto <> ingreso_estadia + ingreso_servicios + ingreso_cancelaciones
                  THEN 1 ELSE 0 END)
    INTO v_filas, v_estadia, v_malas
    FROM liquidacion_mensual WHERE anio = 2025 AND mes = 12;

  SELECT NVL(SUM(rh.valor_estadia), 0) INTO v_esperado
    FROM reserva r JOIN reserva_habitacion rh ON rh.id_reserva = r.id_reserva
   WHERE r.estado = 'COMPLETADA'
     AND r.fecha_checkout BETWEEN DATE '2025-12-01' AND DATE '2025-12-31';

  ok(v_filas = v_aloj_tot, '5.1 Una fila por alojamiento: ' || v_filas);
  ok(v_estadia = v_esperado,
     '5.2 Ingreso por estadía cuadra con la consulta directa: ' || v_estadia || ' = ' || v_esperado);
  ok(v_malas = 0, '5.3 bruto = estadía + servicios + cancelaciones y neto = bruto - comisión en todas las filas');

  -- 5.4 Re-ejecutar para un solo alojamiento reemplaza solo esa fila.
  pkg_reservas.sp_liquidacion_mensual(2025, 12, :v_aloj);
  SELECT COUNT(*) INTO v_filas FROM liquidacion_mensual WHERE anio = 2025 AND mes = 12;
  ok(v_filas = v_aloj_tot,
     '5.4 Re-ejecución para el alojamiento ' || :v_aloj || ': siguen ' || v_filas || ' filas, sin duplicados');

  -- 5.5 Periodo inválido
  BEGIN
    pkg_reservas.sp_liquidacion_mensual(2025, 13);
    ok(FALSE, '5.5 Mes 13 debía fallar');
  EXCEPTION WHEN OTHERS THEN
    ok(SQLCODE = -20113, '5.5 Periodo inválido -> ' || SQLERRM);
  END;
END;
/

-- Evidencia: los 10 alojamientos con mayor neto en diciembre de 2025
SELECT a.nombre_comercial, l.reservas, l.noches, l.ingreso_estadia, l.ingreso_servicios,
       l.ingreso_cancelaciones, l.total_bruto, l.comision_plataforma, l.neto_alojamiento
  FROM liquidacion_mensual l
  JOIN alojamiento a ON a.id_alojamiento = l.id_alojamiento
 WHERE l.anio = 2025 AND l.mes = 12
 ORDER BY l.neto_alojamiento DESC
 FETCH FIRST 10 ROWS ONLY;

/* =============================================================================
   PRUEBA 6 · Paquete: compilado y con todos sus subprogramas
   ============================================================================= */
PROMPT
PROMPT ===== PRUEBA 6 · Paquete PKG_RESERVAS =====
SELECT object_name, object_type, status, last_ddl_time
  FROM user_objects
 WHERE object_name = 'PKG_RESERVAS';

SELECT procedure_name AS subprograma
  FROM user_procedures
 WHERE object_name = 'PKG_RESERVAS' AND procedure_name IS NOT NULL
 ORDER BY subprogram_id;

/* =============================================================================
   PRUEBA 7 · Tablespace del histórico
   ============================================================================= */
PROMPT
PROMPT ===== PRUEBA 7 · Tablespace TS_TURISMOUQ_HIST =====
DECLARE
  v_antes    PLS_INTEGER;
  v_despues  PLS_INTEGER;
  v_faltan   PLS_INTEGER;
  v_ts       VARCHAR2(30);
  PROCEDURE ok(p_cond BOOLEAN, p_caso VARCHAR2) IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN p_cond THEN 'PASA   ' ELSE 'FALLA  ' END || p_caso);
  END;
BEGIN
  SELECT tablespace_name INTO v_ts FROM user_tables WHERE table_name = 'HIST_RESERVA';
  ok(v_ts = 'TS_TURISMOUQ_HIST', '7.1 HIST_RESERVA está en ' || v_ts);

  SELECT COUNT(*) INTO v_antes FROM hist_reserva;
  sp_archivar_reservas(DATE '2025-01-01');          -- ya archivado: no debe duplicar
  SELECT COUNT(*) INTO v_despues FROM hist_reserva;
  ok(v_antes = v_despues, '7.2 Re-archivar 2024 no duplica: ' || v_antes || ' = ' || v_despues);

  -- Líneas cerradas antes del 2025-07-01 que todavía no están en el histórico
  -- (en la primera ejecución son las del primer semestre de 2025; si el script
  -- se repite, ya están archivadas y el resultado correcto es 0).
  SELECT COUNT(*) INTO v_faltan
    FROM reserva r JOIN reserva_habitacion rh ON rh.id_reserva = r.id_reserva
   WHERE r.estado IN ('COMPLETADA', 'CANCELADA')
     AND r.fecha_checkout < DATE '2025-07-01'
     AND NOT EXISTS (SELECT 1 FROM hist_reserva h
                      WHERE h.id_reserva_habitacion = rh.id_reserva_habitacion);
  sp_archivar_reservas(DATE '2025-07-01');
  SELECT COUNT(*) INTO v_despues FROM hist_reserva;
  ok(v_despues = v_antes + v_faltan,
     '7.3 Archivo hasta 2025-07-01: faltaban ' || v_faltan || ', histórico ' || v_antes || ' -> ' || v_despues);

  -- 7.4 Todo lo cerrado antes del corte quedó en el histórico.
  SELECT COUNT(*) INTO v_faltan
    FROM reserva r JOIN reserva_habitacion rh ON rh.id_reserva = r.id_reserva
   WHERE r.estado IN ('COMPLETADA', 'CANCELADA')
     AND r.fecha_checkout < DATE '2025-07-01'
     AND NOT EXISTS (SELECT 1 FROM hist_reserva h
                      WHERE h.id_reserva_habitacion = rh.id_reserva_habitacion);
  ok(v_faltan = 0, '7.4 No queda ninguna línea cerrada antes del 2025-07-01 sin archivar');
END;
/

SELECT segment_name, segment_type, tablespace_name, ROUND(bytes / 1024 / 1024, 2) AS mb
  FROM user_segments
 WHERE tablespace_name = 'TS_TURISMOUQ_HIST';

SELECT estado, COUNT(*) AS lineas, MIN(fecha_checkout) AS desde, MAX(fecha_checkout) AS hasta
  FROM hist_reserva
 GROUP BY estado;

/* =============================================================================
   PRUEBA 8 · Vista materializada y su refresco
   ============================================================================= */
PROMPT
PROMPT ===== PRUEBA 8 · Vista materializada MV_OCUPACION_MENSUAL =====
SELECT mview_name, refresh_method, refresh_mode, last_refresh_type, last_refresh_date
  FROM user_mviews WHERE mview_name = 'MV_OCUPACION_MENSUAL';

SELECT job_name, enabled, state, repeat_interval, next_run_date
  FROM user_scheduler_jobs WHERE job_name = 'JOB_REFRESCO_MV_OCUPACION';

-- Muestra: ocupación de 2025 en el alojamiento de prueba
SELECT nombre_comercial, anio, mes, habitaciones, noches_disponibles, noches_ocupadas, pct_ocupacion
  FROM mv_ocupacion_mensual
 WHERE id_alojamiento = :v_aloj AND anio = 2025
 ORDER BY mes;

-- Tiempo: misma información calculada en vivo vs leída de la vista
SET TIMING ON
SELECT COUNT(*) AS filas, ROUND(AVG(pct), 2) AS ocupacion_promedio
  FROM (SELECT rh.id_alojamiento, c.anio, c.mes, COUNT(*) AS pct
          FROM reserva_habitacion rh
          JOIN reserva r    ON r.id_reserva = rh.id_reserva AND r.estado IN ('CONFIRMADA', 'COMPLETADA')
          JOIN calendario c ON c.fecha >= rh.fecha_checkin AND c.fecha < rh.fecha_checkout
         GROUP BY rh.id_alojamiento, c.anio, c.mes);
SELECT COUNT(*) AS filas, ROUND(AVG(noches_ocupadas), 2) AS ocupacion_promedio
  FROM mv_ocupacion_mensual WHERE noches_ocupadas > 0;
SET TIMING OFF

-- Costo estimado por el optimizador (estable, no depende de la caché ni de la
-- pantalla): cálculo en vivo vs lectura de la vista materializada.
DELETE FROM plan_table WHERE statement_id IN ('OCUP_VIVO', 'OCUP_MV');
EXPLAIN PLAN SET STATEMENT_ID = 'OCUP_VIVO' FOR
SELECT rh.id_alojamiento, c.anio, c.mes, COUNT(*) AS noches_ocupadas
  FROM reserva_habitacion rh
  JOIN reserva r    ON r.id_reserva = rh.id_reserva AND r.estado IN ('CONFIRMADA', 'COMPLETADA')
  JOIN calendario c ON c.fecha >= rh.fecha_checkin AND c.fecha < rh.fecha_checkout
 GROUP BY rh.id_alojamiento, c.anio, c.mes;
EXPLAIN PLAN SET STATEMENT_ID = 'OCUP_MV' FOR
SELECT id_alojamiento, anio, mes, noches_ocupadas
  FROM mv_ocupacion_mensual;
SELECT CASE statement_id WHEN 'OCUP_VIVO' THEN 'Cálculo en vivo' ELSE 'Vista materializada' END AS origen,
       cost AS costo_optimizador, cardinality AS filas_estimadas, bytes
  FROM plan_table
 WHERE statement_id IN ('OCUP_VIVO', 'OCUP_MV') AND id = 0
 ORDER BY cost DESC;

-- Política ON DEMAND: un cambio no aparece hasta el refresco.
DECLARE
  v_id      reserva.id_reserva%TYPE;
  v_mv      NUMBER;
  v_vivo    NUMBER;
  v_mv_ini  NUMBER;
  PROCEDURE ok(p_cond BOOLEAN, p_caso VARCHAR2) IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN p_cond THEN 'PASA   ' ELSE 'FALLA  ' END || p_caso);
  END;
  FUNCTION noches_vivo RETURN NUMBER IS
    v NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v
      FROM reserva_habitacion rh
      JOIN reserva r    ON r.id_reserva = rh.id_reserva AND r.estado IN ('CONFIRMADA', 'COMPLETADA')
      JOIN calendario c ON c.fecha >= rh.fecha_checkin AND c.fecha < rh.fecha_checkout
     WHERE rh.id_alojamiento = :v_aloj AND c.anio = 2026 AND c.mes = 12;
    RETURN v;
  END;
  FUNCTION noches_mv RETURN NUMBER IS
    v NUMBER;
  BEGIN
    SELECT noches_ocupadas INTO v FROM mv_ocupacion_mensual
     WHERE id_alojamiento = :v_aloj AND anio = 2026 AND mes = 12;
    RETURN v;
  END;
BEGIN
  DBMS_MVIEW.REFRESH('MV_OCUPACION_MENSUAL', 'C');
  v_mv_ini := noches_mv;
  ok(v_mv_ini = noches_vivo, '8.1 Recién refrescada coincide con el cálculo en vivo: ' || v_mv_ini);

  -- Nueva reserva confirmada de 5 noches en diciembre de 2026
  pkg_reservas.sp_crear_reserva(:v_cli, :v_hab, DATE '2026-12-12', DATE '2026-12-17', 2, v_id);
  UPDATE reserva SET estado = 'CONFIRMADA' WHERE id_reserva = v_id;
  COMMIT;

  v_mv := noches_mv; v_vivo := noches_vivo;
  ok(v_mv = v_mv_ini AND v_vivo = v_mv_ini + 5,
     '8.2 Tras confirmar la reserva ' || v_id || ': vista ' || v_mv || ' (desactualizada), en vivo ' || v_vivo);

  DBMS_MVIEW.REFRESH('MV_OCUPACION_MENSUAL', 'C');
  v_mv := noches_mv;
  ok(v_mv = v_vivo, '8.3 Después de DBMS_MVIEW.REFRESH la vista muestra ' || v_mv);

  -- Limpieza: se borra la reserva de prueba y se vuelve a refrescar.
  DELETE FROM reserva WHERE id_reserva = v_id;     -- ON DELETE CASCADE borra su línea
  COMMIT;
  DBMS_MVIEW.REFRESH('MV_OCUPACION_MENSUAL', 'C');
  ok(noches_mv = v_mv_ini, '8.4 Reserva de prueba eliminada y vista refrescada: ' || v_mv_ini);
END;
/

PROMPT
PROMPT === 08_pruebas_entrega2.sql terminado: busque FALLA en la salida ===
-- SPOOL OFF
