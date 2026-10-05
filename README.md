# TurismoUQ - Bases de Datos II - Universidad del Quindío

Base de datos de una plataforma de reservas turísticas del Quindío.

## Entrega 1 - Modelo y consultas de análisis

| Orden | Script | Qué hace |
|---|---|---|
| 1 | `scripts/01_ddl.sql` | 16 tablas (14 del enunciado + CIUDAD y CALENDARIO) con PK, FK, CHECK, NOT NULL, UNIQUE y comentarios; vista `vw_valor_reserva`. Re-ejecutable. |
| 2 | `scripts/02_carga_datos.sql` | Catálogos + generación con PL/SQL y `DBMS_RANDOM` (semilla fija): 60 alojamientos, 634 habitaciones, 72 temporadas, 45.648 tarifas, 3.000 clientes, 30.000 reservas, pagos, servicios y reseñas. Termina verificando volúmenes y reglas. |
| 3 | `scripts/03_consultas_analisis.sql` | 7 consultas: PIVOT, ROLLUP + GROUPING, RANK/PARTITION BY, LAG, variables de enlace, UNPIVOT y una consulta libre. |

Documento del modelo (MER, reglas de negocio, decisiones de diseño): `docs/TurismoUQ_Entrega1_Modelo.docx`. 

## Ejecución

1. Conectarse con el usuario dueño del esquema (no SYS).
2. En SQL Developer, abrir cada script y ejecutarlo completo con **F5** (Ejecutar script), en orden 01 → 02 → 03.
3. Los archivos están en UTF-8. Si las tildes se ven mal: Herramientas → Preferencias → Entorno → Codificación = UTF-8.
4. `02_carga_datos.sql` tarda de 1 a 3 minutos e imprime `OK ...` por cada verificación.

