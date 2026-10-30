# TurismoUQ · Bases de Datos II · Universidad del Quindío

Base de datos de una plataforma de reservas turísticas del Quindío sobre Oracle (probada en Oracle Database 26ai Free, base conectable FREEPDB1).

**Autores:** Manuela Aristizábal Zapata (1094892680) · Sebastián José Lesmes Muñoz (100677504)
**Docente:** Carolina Londoño Idárraga

## Orden de ejecución

| Orden | Script | Conexión | Qué hace |
|---|---|---|---|
| 1 | `scripts/01_ddl.sql` | TURISMOUQ | 16 tablas (14 del enunciado + CIUDAD y CALENDARIO) con PK, FK, CHECK, NOT NULL, UNIQUE y comentarios; vista `vw_valor_reserva`. |
| 2 | `scripts/02_carga_datos.sql` | TURISMOUQ | Catálogos + generación con PL/SQL y `DBMS_RANDOM` (semilla fija): 60 alojamientos, 634 habitaciones, 72 temporadas, 45.648 tarifas, 3.000 clientes, 30.000 reservas, pagos, servicios y reseñas. |
| 3 | `scripts/03_consultas_analisis.sql` | TURISMOUQ | 7 consultas: PIVOT, ROLLUP + GROUPING, RANK/PARTITION BY, LAG, variables de enlace, UNPIVOT y una consulta libre. |
| 4 | `scripts/04_paquete_reservas.sql` | TURISMOUQ | Paquete `PKG_RESERVAS`: `fn_valor_estadia`, `sp_crear_reserva`, `sp_agregar_habitacion` y `sp_liquidacion_mensual` (cursor explícito con parámetros); tabla `LIQUIDACION_MENSUAL`. |
| 5 | `scripts/05_disparadores.sql` | TURISMOUQ | `trg_auditoria_tarifa` (sentencia), `trg_rh_sin_solape` (fila) y `trg_resena_completada` (fila, adicional); tabla `AUDITORIA_TARIFA`. |
| 6 | `scripts/06_tablespace_historico_SYSTEM.sql` | **SYSTEM** | Tablespace `TS_TURISMOUQ_HIST`, cuota y privilegios (CREATE MATERIALIZED VIEW, CREATE JOB) para el esquema. |
| 7 | `scripts/07_historico_y_vista_materializada.sql` | TURISMOUQ | `HIST_RESERVA` en el tablespace propio + `sp_archivar_reservas`; vista materializada `MV_OCUPACION_MENSUAL` con refresco nocturno programado. |
| 8 | `scripts/08_pruebas_entrega2.sql` | TURISMOUQ | Pruebas de la Entrega 2: cada caso imprime PASA o FALLA. |

Cada script se ejecuta completo con **F5** (Ejecutar script) en SQL Developer. Los archivos están en UTF-8.

Para crear el usuario del proyecto (como SYSTEM):

```sql
CREATE USER turismouq IDENTIFIED BY "<clave>"
  DEFAULT TABLESPACE users QUOTA UNLIMITED ON users;
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE SEQUENCE,
      CREATE PROCEDURE, CREATE TRIGGER, CREATE MATERIALIZED VIEW, CREATE JOB
  TO turismouq;
```

## Documentos

| Archivo | Contenido |
|---|---|
| `docs/TurismoUQ_Entrega1_Modelo.docx` | Entrega 1: MER, reglas de negocio y decisiones de diseño. |
| `docs/mer.png` | Diagrama entidad-relación en alta resolución. |
| `docs/TurismoUQ_Entrega2_Evidencias.pdf` | Entrega 2: evidencia de pruebas por componente, con capturas y justificaciones. |
| `docs/evidencia_entrega2.txt` | Salida completa del script 08 (39 casos PASA, 0 FALLA). |

## Entrega 1 · Modelo y consultas de análisis

- **Reserva con varias habitaciones:** encabezado `RESERVA` + detalle `RESERVA_HABITACION` con fechas propias por línea. Las FK compuestas `(id_reserva, id_alojamiento)` y `(id_habitacion, id_alojamiento)` obligan a que todas las habitaciones sean del alojamiento de la reserva.
- **Estadía que cruza temporadas:** `CALENDARIO` asigna cada día a una `TEMPORADA`; el valor de una estadía es la suma, noche por noche, de la `TARIFA` de la temporada de cada día.

## Entrega 2 · Capa PL/SQL

- **`fn_valor_estadia`:** suma `TARIFA` × `CALENDARIO` noche por noche (entrada incluida, salida excluida). Si alguna noche no tiene tarifa lanza -20106 en lugar de devolver un valor incompleto.
- **`sp_crear_reserva`:** excepciones propias con `RAISE_APPLICATION_ERROR`: no disponible (-20101), check-out anterior o igual al check-in (-20102), capacidad excedida (-20103), además de habitación, cliente, fechas pasadas y huéspedes. Bloquea la habitación con `SELECT ... FOR UPDATE` y ante un error deshace solo su trabajo con `ROLLBACK TO SAVEPOINT`.
- **Liquidación mensual:** el cursor `c_liquidacion(p_ini, p_fin, p_id_aloj)` liquida a cada alojamiento las estadías completadas con check-out en el mes (valores congelados al reservar), más lo retenido por cancelaciones, menos la comisión de la plataforma (12 %).
- **Auditoría de TARIFA:** un disparador de sentencia no puede leer `:OLD`/`:NEW`, por eso es un disparador compuesto. La sección de fila guarda los valores en memoria y la sección `AFTER STATEMENT` escribe la auditoría: usuario, equipo, hora, valor anterior, valor nuevo y número de filas de la sentencia.
- **Solape de reservas:** disparador de fila `BEFORE INSERT` sobre `RESERVA_HABITACION`; rechaza (-20120) una línea que comparta una noche con otra reserva no cancelada de la misma habitación.
- **Tablespace `TS_TURISMOUQ_HIST`:** el histórico solo crece y casi no se lee. Separarlo permite `PCTFREE 0`, un tope de tamaño propio que no llena `USERS`, respaldos menos frecuentes (o `READ ONLY` al cerrar un año) y ubicarlo en otro disco.
- **`MV_OCUPACION_MENSUAL`:** `REFRESH COMPLETE ON DEMAND` + job nocturno a las 2 a. m. No es FAST porque la consulta une las reservas con el calendario por rango de fechas, ni ON COMMIT para no frenar cada reserva; la ocupación mensual tolera un día de retraso. Costo del optimizador: 1.294 en vivo frente a 9 desde la vista.
