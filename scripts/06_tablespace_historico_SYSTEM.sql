/* =============================================================================
   TurismoUQ · Script 06 · Tablespace del histórico de reservas
   Entrega 2 · Bases de Datos II · Universidad del Quindío

   *** EJECUTAR COMO SYSTEM (o un usuario con privilegio DBA) ***
   En Oracle XE 21c conéctese a la base conectable XEPDB1 (no a la raíz
   CDB$ROOT): en SQL Developer, una conexión SYSTEM con nombre de servicio
   XEPDB1. Crear tablespaces y dar cuotas son privilegios de sistema que el
   dueño del esquema normalmente no tiene.

   ANTES DE EJECUTAR: cambie TURISMOUQ en la línea DEFINE por el usuario dueño
   del esquema (el resultado de SELECT USER FROM dual en su conexión de trabajo).
   ============================================================================= */

SET SERVEROUTPUT ON
SET DEFINE ON
SET VERIFY OFF

DEFINE esquema = TURISMOUQ

/* -----------------------------------------------------------------------------
   POR QUÉ UN TABLESPACE SEPARADO PARA EL HISTÓRICO
   Las reservas cerradas (completadas o canceladas de periodos anteriores) se
   comportan distinto de las reservas vivas:
     - Patrón de uso: el histórico solo crece (se agrega una vez y no se
       modifica) y se lee de vez en cuando para auditorías y análisis; las
       reservas vivas se insertan y actualizan todo el día. Separarlos evita
       que los bloques de un tipo de dato fragmenten y compitan con los del
       otro, y permite PCTFREE 0 en el histórico (no se reserva espacio para
       actualizaciones que nunca ocurren).
     - Crecimiento controlado: el histórico crece sin límite; en su propio
       tablespace tiene su propio tope (MAXSIZE) y no puede llenar el
       tablespace USERS donde viven las tablas operativas y detener las ventas.
     - Respaldo y recuperación: un periodo cerrado no cambia, así que su
       tablespace se puede respaldar con menos frecuencia (o pasarse a READ
       ONLY al cerrar un año) mientras el operativo se respalda a diario.
     - Ubicación física: su datafile puede moverse a un disco más barato y
       lento sin tocar el disco rápido de la operación.
   ----------------------------------------------------------------------------- */

/* -----------------------------------------------------------------------------
   1. Crear el tablespace junto a los datafiles existentes de la base.
      La carpeta se toma de un datafile de USERS, así el script funciona igual
      en Windows (C:\...\XEPDB1\) que en Linux (/opt/oracle/oradata/XE/XEPDB1/).
   ----------------------------------------------------------------------------- */
DECLARE
  v_contenedor VARCHAR2(128) := SYS_CONTEXT('USERENV', 'CON_NAME');
  v_existe     PLS_INTEGER;
  v_ruta       VARCHAR2(600);
  v_sep        VARCHAR2(1);
BEGIN
  IF v_contenedor = 'CDB$ROOT' THEN
    RAISE_APPLICATION_ERROR(-20130, 'Está conectado a CDB$ROOT. Conéctese a XEPDB1 (la base donde está el esquema).');
  END IF;

  SELECT COUNT(*) INTO v_existe FROM dba_tablespaces WHERE tablespace_name = 'TS_TURISMOUQ_HIST';
  IF v_existe > 0 THEN
    DBMS_OUTPUT.PUT_LINE('El tablespace TS_TURISMOUQ_HIST ya existe en ' || v_contenedor || '.');
  ELSE
    SELECT file_name INTO v_ruta
      FROM (SELECT file_name FROM dba_data_files
             ORDER BY CASE tablespace_name WHEN 'USERS' THEN 0 ELSE 1 END, file_id)
     WHERE ROWNUM = 1;
    v_sep  := CASE WHEN INSTR(v_ruta, '\') > 0 THEN '\' ELSE '/' END;
    v_ruta := SUBSTR(v_ruta, 1, INSTR(v_ruta, v_sep, -1)) || 'TS_TURISMOUQ_HIST01.DBF';

    EXECUTE IMMEDIATE
      'CREATE TABLESPACE ts_turismouq_hist '
      || 'DATAFILE ''' || v_ruta || ''' SIZE 50M '
      || 'AUTOEXTEND ON NEXT 10M MAXSIZE 1G '
      || 'EXTENT MANAGEMENT LOCAL AUTOALLOCATE '
      || 'SEGMENT SPACE MANAGEMENT AUTO';
    DBMS_OUTPUT.PUT_LINE('Tablespace TS_TURISMOUQ_HIST creado en ' || v_contenedor || ': ' || v_ruta);
  END IF;
END;
/

/* -----------------------------------------------------------------------------
   2. Privilegios para el dueño del esquema
      - Cuota en el nuevo tablespace (sin cuota no puede crear segmentos allí).
      - CREATE MATERIALIZED VIEW: no viene en los roles CONNECT ni RESOURCE.
      - CREATE JOB: para programar el refresco nocturno de la vista
        materializada con DBMS_SCHEDULER.
   ----------------------------------------------------------------------------- */
ALTER USER &esquema QUOTA UNLIMITED ON ts_turismouq_hist;
GRANT CREATE MATERIALIZED VIEW TO &esquema;
GRANT CREATE JOB TO &esquema;

/* -----------------------------------------------------------------------------
   3. Verificación
   ----------------------------------------------------------------------------- */
SELECT t.tablespace_name, t.status, t.contents, t.extent_management,
       t.segment_space_management, f.file_name,
       ROUND(f.bytes / 1024 / 1024) AS mb, f.autoextensible,
       ROUND(f.maxbytes / 1024 / 1024) AS max_mb
  FROM dba_tablespaces t
  JOIN dba_data_files  f ON f.tablespace_name = t.tablespace_name
 WHERE t.tablespace_name = 'TS_TURISMOUQ_HIST';

SELECT username, tablespace_name,
       CASE max_bytes WHEN -1 THEN 'ILIMITADA' ELSE TO_CHAR(max_bytes) END AS cuota
  FROM dba_ts_quotas
 WHERE tablespace_name = 'TS_TURISMOUQ_HIST';

PROMPT === 06_tablespace_historico_SYSTEM.sql terminado. Siga con 07 en la conexión del esquema. ===
