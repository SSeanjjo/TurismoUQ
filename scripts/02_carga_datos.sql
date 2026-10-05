/* =============================================================================
   TurismoUQ · Script 02 · Carga de datos
   Requiere: 01_ddl.sql ejecutado. Ejecutar completo con F5 en SQL Developer
   (o @02_carga_datos.sql en SQL*Plus). El archivo está en UTF-8.

   Estrategia:
     - Catálogos reales o pequeños (municipios, tipos, ciudades, alojamientos,
       temporadas, usuarios) se insertan explícitamente.
     - El volumen (habitaciones, tarifas, clientes, reservas, pagos, servicios,
       reseñas) se genera con PL/SQL y DBMS_RANDOM, con semilla fija para que la
       carga sea reproducible: si se ejecuta dos veces da los mismos datos.
     - Los datos son ASIMÉTRICOS a propósito: municipios con 1 o 12
       alojamientos, alojamientos con 3 o 38 habitaciones, demanda que depende
       de la temporada, del día de la semana, del municipio y de cada alojamiento.
     - Fecha de corte del escenario: 2026-10-01. Antes de esa fecha las reservas
       están completadas o canceladas; después, pendientes o confirmadas.
     - Ninguna habitación tiene dos reservas activas que se solapen.
   Tiempo aproximado en un portátil: 1 a 3 minutos.
   ============================================================================= */

SET SERVEROUTPUT ON SIZE UNLIMITED
SET DEFINE OFF
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';

/* -----------------------------------------------------------------------------
   1. MUNICIPIO: los 12 municipios del Quindío
   ----------------------------------------------------------------------------- */
INSERT INTO municipio (id_municipio, codigo_dane, nombre) VALUES (1, '63001', 'Armenia');
INSERT INTO municipio (id_municipio, codigo_dane, nombre) VALUES (2, '63111', 'Buenavista');
INSERT INTO municipio (id_municipio, codigo_dane, nombre) VALUES (3, '63130', 'Calarcá');
INSERT INTO municipio (id_municipio, codigo_dane, nombre) VALUES (4, '63190', 'Circasia');
INSERT INTO municipio (id_municipio, codigo_dane, nombre) VALUES (5, '63212', 'Córdoba');
INSERT INTO municipio (id_municipio, codigo_dane, nombre) VALUES (6, '63272', 'Filandia');
INSERT INTO municipio (id_municipio, codigo_dane, nombre) VALUES (7, '63302', 'Génova');
INSERT INTO municipio (id_municipio, codigo_dane, nombre) VALUES (8, '63401', 'La Tebaida');
INSERT INTO municipio (id_municipio, codigo_dane, nombre) VALUES (9, '63470', 'Montenegro');
INSERT INTO municipio (id_municipio, codigo_dane, nombre) VALUES (10, '63548', 'Pijao');
INSERT INTO municipio (id_municipio, codigo_dane, nombre) VALUES (11, '63594', 'Quimbaya');
INSERT INTO municipio (id_municipio, codigo_dane, nombre) VALUES (12, '63690', 'Salento');

/* -----------------------------------------------------------------------------
   2. TIPO_ALOJAMIENTO (4 del enunciado + Ecohotel)
   ----------------------------------------------------------------------------- */
INSERT INTO tipo_alojamiento (id_tipo_alojamiento, nombre, descripcion) VALUES (1, 'Finca cafetera', 'Casa campestre en finca productora de café, con experiencias agroturísticas.');
INSERT INTO tipo_alojamiento (id_tipo_alojamiento, nombre, descripcion) VALUES (2, 'Hotel', 'Establecimiento urbano o de carretera con recepción 24 horas y servicios formales.');
INSERT INTO tipo_alojamiento (id_tipo_alojamiento, nombre, descripcion) VALUES (3, 'Glamping', 'Alojamiento en domos, carpas o cabañas de lujo en entorno natural.');
INSERT INTO tipo_alojamiento (id_tipo_alojamiento, nombre, descripcion) VALUES (4, 'Hostal', 'Alojamiento económico con habitaciones sencillas o compartidas, orientado a mochileros.');
INSERT INTO tipo_alojamiento (id_tipo_alojamiento, nombre, descripcion) VALUES (5, 'Ecohotel', 'Hotel campestre de bajo impacto ambiental, ligado a reservas naturales y avistamiento de aves.');

/* -----------------------------------------------------------------------------
   3. CIUDAD de origen de los clientes (nacionales y extranjeras)
   ----------------------------------------------------------------------------- */
INSERT INTO ciudad (id_ciudad, nombre, departamento, pais) VALUES (1, 'Bogotá', 'Cundinamarca', 'Colombia');
INSERT INTO ciudad (id_ciudad, nombre, departamento, pais) VALUES (2, 'Medellín', 'Antioquia', 'Colombia');
INSERT INTO ciudad (id_ciudad, nombre, departamento, pais) VALUES (3, 'Cali', 'Valle del Cauca', 'Colombia');
INSERT INTO ciudad (id_ciudad, nombre, departamento, pais) VALUES (4, 'Pereira', 'Risaralda', 'Colombia');
INSERT INTO ciudad (id_ciudad, nombre, departamento, pais) VALUES (5, 'Armenia', 'Quindío', 'Colombia');
INSERT INTO ciudad (id_ciudad, nombre, departamento, pais) VALUES (6, 'Manizales', 'Caldas', 'Colombia');
INSERT INTO ciudad (id_ciudad, nombre, departamento, pais) VALUES (7, 'Ibagué', 'Tolima', 'Colombia');
INSERT INTO ciudad (id_ciudad, nombre, departamento, pais) VALUES (8, 'Bucaramanga', 'Santander', 'Colombia');
INSERT INTO ciudad (id_ciudad, nombre, departamento, pais) VALUES (9, 'Barranquilla', 'Atlántico', 'Colombia');
INSERT INTO ciudad (id_ciudad, nombre, departamento, pais) VALUES (10, 'Cartagena', 'Bolívar', 'Colombia');
INSERT INTO ciudad (id_ciudad, nombre, departamento, pais) VALUES (11, 'Cúcuta', 'Norte de Santander', 'Colombia');
INSERT INTO ciudad (id_ciudad, nombre, departamento, pais) VALUES (12, 'Neiva', 'Huila', 'Colombia');
INSERT INTO ciudad (id_ciudad, nombre, departamento, pais) VALUES (13, 'Tuluá', 'Valle del Cauca', 'Colombia');
INSERT INTO ciudad (id_ciudad, nombre, departamento, pais) VALUES (14, 'Cartago', 'Valle del Cauca', 'Colombia');
INSERT INTO ciudad (id_ciudad, nombre, departamento, pais) VALUES (15, 'Palmira', 'Valle del Cauca', 'Colombia');
INSERT INTO ciudad (id_ciudad, nombre, departamento, pais) VALUES (16, 'Villavicencio', 'Meta', 'Colombia');
INSERT INTO ciudad (id_ciudad, nombre, departamento, pais) VALUES (17, 'Santa Marta', 'Magdalena', 'Colombia');
INSERT INTO ciudad (id_ciudad, nombre, departamento, pais) VALUES (18, 'Pasto', 'Nariño', 'Colombia');
INSERT INTO ciudad (id_ciudad, nombre, departamento, pais) VALUES (19, 'Popayán', 'Cauca', 'Colombia');
INSERT INTO ciudad (id_ciudad, nombre, departamento, pais) VALUES (20, 'Tunja', 'Boyacá', 'Colombia');
INSERT INTO ciudad (id_ciudad, nombre, departamento, pais) VALUES (21, 'Montería', 'Córdoba', 'Colombia');
INSERT INTO ciudad (id_ciudad, nombre, departamento, pais) VALUES (22, 'Calarcá', 'Quindío', 'Colombia');
INSERT INTO ciudad (id_ciudad, nombre, departamento, pais) VALUES (23, 'Dosquebradas', 'Risaralda', 'Colombia');
INSERT INTO ciudad (id_ciudad, nombre, departamento, pais) VALUES (24, 'Buenaventura', 'Valle del Cauca', 'Colombia');
INSERT INTO ciudad (id_ciudad, nombre, departamento, pais) VALUES (25, 'Madrid', 'Comunidad de Madrid', 'España');
INSERT INTO ciudad (id_ciudad, nombre, departamento, pais) VALUES (26, 'Barcelona', 'Cataluña', 'España');
INSERT INTO ciudad (id_ciudad, nombre, departamento, pais) VALUES (27, 'Ciudad de México', 'CDMX', 'México');
INSERT INTO ciudad (id_ciudad, nombre, departamento, pais) VALUES (28, 'Miami', 'Florida', 'Estados Unidos');
INSERT INTO ciudad (id_ciudad, nombre, departamento, pais) VALUES (29, 'Nueva York', 'Nueva York', 'Estados Unidos');
INSERT INTO ciudad (id_ciudad, nombre, departamento, pais) VALUES (30, 'Los Ángeles', 'California', 'Estados Unidos');
INSERT INTO ciudad (id_ciudad, nombre, departamento, pais) VALUES (31, 'Toronto', 'Ontario', 'Canadá');
INSERT INTO ciudad (id_ciudad, nombre, departamento, pais) VALUES (32, 'Buenos Aires', NULL, 'Argentina');
INSERT INTO ciudad (id_ciudad, nombre, departamento, pais) VALUES (33, 'Santiago', 'Región Metropolitana', 'Chile');
INSERT INTO ciudad (id_ciudad, nombre, departamento, pais) VALUES (34, 'Lima', NULL, 'Perú');
INSERT INTO ciudad (id_ciudad, nombre, departamento, pais) VALUES (35, 'Quito', 'Pichincha', 'Ecuador');
INSERT INTO ciudad (id_ciudad, nombre, departamento, pais) VALUES (36, 'Panamá', NULL, 'Panamá');
INSERT INTO ciudad (id_ciudad, nombre, departamento, pais) VALUES (37, 'París', 'Île-de-France', 'Francia');
INSERT INTO ciudad (id_ciudad, nombre, departamento, pais) VALUES (38, 'Berlín', NULL, 'Alemania');
INSERT INTO ciudad (id_ciudad, nombre, departamento, pais) VALUES (39, 'Ámsterdam', 'Holanda Septentrional', 'Países Bajos');
INSERT INTO ciudad (id_ciudad, nombre, departamento, pais) VALUES (40, 'Londres', NULL, 'Reino Unido');
INSERT INTO ciudad (id_ciudad, nombre, departamento, pais) VALUES (41, 'São Paulo', 'São Paulo', 'Brasil');

/* -----------------------------------------------------------------------------
   4. ALOJAMIENTO: 60, repartidos de forma desigual
      Salento 12 · Armenia 11 · Montenegro 8 · Quimbaya 7 · Filandia 7 ·
      Calarcá 5 · Circasia 4 · La Tebaida 2 · Córdoba, Buenavista, Pijao y
      Génova 1 cada uno. (Nombres ficticios.)
   ----------------------------------------------------------------------------- */
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (1, 12, 1, 'Finca El Ocobo', 'Km 3 vía Salento - Valle de Cocora, vereda Palestina', 4, '6067301379', 'reservas@fincaelocobo.co', DATE '2021-03-15');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (2, 12, 1, 'Finca Cafetera La Serrana', 'Km 1,5 vía Salento - Palestina', 4, '6067302758', 'reservas@fincacafeteralaserrana.co', DATE '2020-08-02');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (3, 12, 1, 'Finca Don Eduardo Café', 'Vereda Llano Grande, Salento', 3, '6067304137', 'reservas@fincadoneduardocafe.co', DATE '2022-01-20');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (4, 12, 2, 'Hotel Palma de Cera', 'Carrera 6 # 2-34, Salento', 4, '6067305516', 'reservas@hotelpalmadecera.co', DATE '2019-05-10');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (5, 12, 3, 'Glamping Bosque de Niebla', 'Vereda Cocora, km 9 vía Salento', 5, '6067306895', 'reservas@glampingbosquedeniebla.co', DATE '2022-06-11');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (6, 12, 3, 'Domos del Cocora', 'Valle de Cocora, sector La Truchera', 4, '6067308274', 'reservas@domosdelcocora.co', DATE '2023-02-01');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (7, 12, 3, 'Glamping Mirador Quindío', 'Vereda Boquía, Salento', 4, '6067309653', 'reservas@glampingmiradorquindio.co', DATE '2023-09-14');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (8, 12, 4, 'Hostal La Floresta Real', 'Calle 7 # 4-21, Salento', 3, '6067311032', 'reservas@hostallaflorestareal.co', DATE '2018-11-30');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (9, 12, 4, 'Hostal Camino Real', 'Carrera 4 # 6-15, Salento', 2, '6067312411', 'reservas@hostalcaminoreal.co', DATE '2019-02-18');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (10, 12, 4, 'Hostal Bahareque', 'Calle 3 # 5-40, Salento', 3, '6067313790', 'reservas@hostalbahareque.co', DATE '2020-10-05');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (11, 12, 4, 'Hostal Plaza Bolívar Salento', 'Carrera 6 # 5-12, Salento', 2, '6067315169', 'reservas@hostalplazabolivarsalento.co', DATE '2017-07-21');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (12, 12, 5, 'Ecohotel Senderos de Cocora', 'Vereda Cocora, sector Los Nevados', 4, '6067316548', 'reservas@ecohotelsenderosdecocora.co', DATE '2021-09-09');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (13, 1, 2, 'Hotel Gran Armenia Plaza', 'Calle 21 # 14-35, Armenia', 5, '6067317927', 'reservas@hotelgranarmeniaplaza.co', DATE '2015-04-22');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (14, 1, 2, 'Hotel Bolívar Centro', 'Carrera 14 # 19-60, Armenia', 4, '6067319306', 'reservas@hotelbolivarcentro.co', DATE '2016-09-12');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (15, 1, 2, 'Hotel Avenida Bolívar', 'Avenida Bolívar # 3N-21, Armenia', 4, '6067320685', 'reservas@hotelavenidabolivar.co', DATE '2017-01-17');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (16, 1, 2, 'Hotel Ciudad Milagro', 'Carrera 16 # 21-04, Armenia', 3, '6067322064', 'reservas@hotelciudadmilagro.co', DATE '2018-03-03');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (17, 1, 2, 'Hotel Parque Sucre', 'Carrera 13 # 13-30, Armenia', 3, '6067323443', 'reservas@hotelparquesucre.co', DATE '2019-06-28');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (18, 1, 2, 'Hotel Boutique Los Fundadores', 'Calle 2N # 13-50, Armenia', 4, '6067324822', 'reservas@hotelboutiquelosfundadores.co', DATE '2021-11-15');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (19, 1, 4, 'Hostal Café Armenia', 'Calle 9 # 13-12, Armenia', 2, '6067326201', 'reservas@hostalcafearmenia.co', DATE '2020-02-14');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (20, 1, 4, 'Hostal El Viajero Cafetero', 'Carrera 18 # 23-41, Armenia', 2, '6067327580', 'reservas@hostalelviajerocafetero.co', DATE '2021-05-07');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (21, 1, 4, 'Hostal Norte Verde', 'Avenida 19 Norte # 9-35, Armenia', 3, '6067328959', 'reservas@hostalnorteverde.co', DATE '2022-08-19');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (22, 1, 1, 'Finca Hotel El Jardín Armenia', 'Km 2 vía Armenia - Pueblo Tapao, vereda El Caimo', 4, '6067330338', 'reservas@fincahoteleljardinarmenia.co', DATE '2018-12-01');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (23, 1, 5, 'Ecohotel Bosques del Edén', 'Km 5 vía Armenia - Aeropuerto El Edén', 4, '6067331717', 'reservas@ecohotelbosquesdeleden.co', DATE '2020-04-30');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (24, 9, 1, 'Finca La Morelia', 'Km 6 vía Montenegro - Parque del Café', 4, '6067333096', 'reservas@fincalamorelia.co', DATE '2019-08-08');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (25, 9, 1, 'Finca Hotel Los Guaduales', 'Vereda Pueblo Tapao, Montenegro', 3, '6067334475', 'reservas@fincahotellosguaduales.co', DATE '2020-01-11');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (26, 9, 1, 'Finca Villa Café Montenegro', 'Km 2 vía Montenegro - Quimbaya', 3, '6067335854', 'reservas@fincavillacafemontenegro.co', DATE '2021-07-25');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (27, 9, 1, 'Finca El Cafetal de Pueblo Tapao', 'Vereda Pueblo Tapao, sector La Julia', 4, '6067337233', 'reservas@fincaelcafetaldepueblotapao.co', DATE '2022-03-19');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (28, 9, 2, 'Hotel Campestre Pueblo Tapao', 'Km 6 vía Montenegro - Pueblo Tapao', 4, '6067338612', 'reservas@hotelcampestrepueblotapao.co', DATE '2016-12-10');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (29, 9, 2, 'Hotel Montenegro Real', 'Carrera 6 # 16-20, Montenegro', 3, '6067339991', 'reservas@hotelmontenegroreal.co', DATE '2019-10-02');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (30, 9, 3, 'Glamping Las Heliconias', 'Vereda Calle Larga, Montenegro', 4, '6067341370', 'reservas@glampinglasheliconias.co', DATE '2023-04-05');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (31, 9, 5, 'Ecohotel Guadual del Café', 'Km 4 vía Montenegro - Parque del Café', 4, '6067342749', 'reservas@ecohotelguadualdelcafe.co', DATE '2021-02-27');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (32, 11, 1, 'Finca Hotel La Esperanza', 'Vereda El Laurel, Quimbaya', 4, '6067344128', 'reservas@fincahotellaesperanza.co', DATE '2018-06-16');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (33, 11, 1, 'Finca Cafetera Las Acacias', 'Km 3 vía Quimbaya - Panaca', 3, '6067345507', 'reservas@fincacafeteralasacacias.co', DATE '2020-09-21');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (34, 11, 1, 'Finca El Balso', 'Vereda Kerman, Quimbaya', 3, '6067346886', 'reservas@fincaelbalso.co', DATE '2022-11-04');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (35, 11, 2, 'Hotel Campestre Los Arrieros', 'Km 7 vía Quimbaya - Panaca', 5, '6067348265', 'reservas@hotelcampestrelosarrieros.co', DATE '2015-10-09');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (36, 11, 2, 'Hotel Quimbaya Plaza', 'Calle 15 # 7-25, Quimbaya', 3, '6067349644', 'reservas@hotelquimbayaplaza.co', DATE '2019-04-13');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (37, 11, 3, 'Glamping Río La Vieja', 'Vereda Puerto Alejandría, Quimbaya', 4, '6067351023', 'reservas@glampingriolavieja.co', DATE '2023-07-01');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (38, 11, 4, 'Hostal Alumbrados Quimbaya', 'Carrera 4 # 14-08, Quimbaya', 2, '6067352402', 'reservas@hostalalumbradosquimbaya.co', DATE '2021-12-12');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (39, 6, 1, 'Finca La Cristalina', 'Vereda Cruces, Filandia', 4, '6067353781', 'reservas@fincalacristalina.co', DATE '2020-05-26');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (40, 6, 1, 'Finca Bambusa Filandia', 'Km 2 vía Filandia - Quimbaya', 3, '6067355160', 'reservas@fincabambusafilandia.co', DATE '2021-08-31');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (41, 6, 2, 'Hotel Colina Iluminada', 'Calle 6 # 5-30, Filandia', 4, '6067356539', 'reservas@hotelcolinailuminada.co', DATE '2018-01-08');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (42, 6, 3, 'Glamping Mirador Colina Iluminada', 'Vereda La Palmera, Filandia', 5, '6067357918', 'reservas@glampingmiradorcolinailumina.co', DATE '2022-10-17');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (43, 6, 3, 'Glamping Cielo Abierto Filandia', 'Vereda Bambuco Alto, Filandia', 4, '6067359297', 'reservas@glampingcieloabiertofilandia.co', DATE '2023-05-23');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (44, 6, 4, 'Hostal Bahareque Filandia', 'Carrera 5 # 7-19, Filandia', 3, '6067360676', 'reservas@hostalbaharequefilandia.co', DATE '2019-09-03');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (45, 6, 4, 'Hostal Mirador del Quindío', 'Calle 8 # 6-44, Filandia', 2, '6067362055', 'reservas@hostalmiradordelquindio.co', DATE '2020-12-20');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (46, 3, 1, 'Finca Alto de la Cruz', 'Km 4 vía Calarcá - Quebrada Negra', 5, '6067363434', 'reservas@fincaaltodelacruz.co', DATE '2017-03-29');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (47, 3, 1, 'Finca El Recreo Calarcá', 'Vereda La Bella, Calarcá', 3, '6067364813', 'reservas@fincaelrecreocalarca.co', DATE '2021-01-15');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (48, 3, 2, 'Hotel Campestre Las Orquídeas', 'Km 3 vía Calarcá - Armenia', 4, '6067366192', 'reservas@hotelcampestrelasorquideas.co', DATE '2017-11-11');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (49, 3, 2, 'Hotel Villa Calarcá', 'Calle 39 # 25-10, Calarcá', 3, '6067367571', 'reservas@hotelvillacalarca.co', DATE '2020-06-06');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (50, 3, 5, 'Ecohotel Alas del Quindío', 'Km 3 vía Calarcá, junto al Jardín Botánico', 4, '6067368950', 'reservas@ecohotelalasdelquindio.co', DATE '2019-07-19');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (51, 4, 1, 'Finca Hotel Villa Nora', 'Vereda La Pradera, Circasia', 4, '6067370329', 'reservas@fincahotelvillanora.co', DATE '2019-03-14');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (52, 4, 1, 'Finca El Mirador de Circasia', 'Km 1 vía Circasia - Filandia', 3, '6067371708', 'reservas@fincaelmiradordecircasia.co', DATE '2022-02-08');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (53, 4, 2, 'Hotel Plaza de Circasia', 'Carrera 14 # 7-15, Circasia', 3, '6067373087', 'reservas@hotelplazadecircasia.co', DATE '2021-04-21');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (54, 4, 3, 'Glamping Lagos de Circasia', 'Vereda Barcelona Alta, Circasia', 4, '6067374466', 'reservas@glampinglagosdecircasia.co', DATE '2023-01-30');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (55, 8, 2, 'Hotel Aeropuerto El Edén', 'Km 1 vía La Tebaida - Aeropuerto El Edén', 4, '6067375845', 'reservas@hotelaeropuertoeleden.co', DATE '2016-05-18');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (56, 8, 1, 'Finca El Paraíso Tebaida', 'Vereda La Silvia, La Tebaida', 3, '6067377224', 'reservas@fincaelparaisotebaida.co', DATE '2020-11-27');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (57, 5, 1, 'Finca La Guadua de Córdoba', 'Vereda Río Verde, Córdoba', 3, '6067378603', 'reservas@fincalaguaduadecordoba.co', DATE '2022-04-14');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (58, 2, 3, 'Glamping Mirador de Buenavista', 'Vía Buenavista - Pijao, sector El Mirador', 4, '6067379982', 'reservas@glampingmiradordebuenavista.co', DATE '2023-03-10');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (59, 10, 4, 'Hostal Pijao Ciudad Lenta', 'Calle 5 # 3-22, Pijao', 3, '6067381361', 'reservas@hostalpijaociudadlenta.co', DATE '2021-10-01');
INSERT INTO alojamiento (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono, correo, fecha_registro)
  VALUES (60, 7, 1, 'Finca El Cedral de Génova', 'Vereda El Cedral, Génova', 3, '6067382740', 'reservas@fincaelcedraldegenova.co', DATE '2022-12-05');
COMMIT;

/* -----------------------------------------------------------------------------
   5. TEMPORADA: 2024, 2025 y 2026 (72 periodos)
      Reglas usadas para construirlas:
        ALTA : vacaciones de inicio de año (hasta el lunes festivo de Reyes),
               Semana Santa (sábado antes de Ramos a domingo de Pascua),
               cada puente festivo (sábado-domingo-lunes festivo, Ley Emiliani),
               vacaciones de mitad de año (15 jun - 15 jul) y fin de año (15-31 dic).
        MEDIA: abril - mitad de junio, mitad de julio - agosto, semana de receso
               escolar de octubre y 1-14 de diciembre.
        BAJA : resto de enero a marzo y septiembre a noviembre.
      Cuando un puente parte un periodo, este queda en "tramos". Ningún periodo
      cruza el 31 de diciembre: diciembre-enero son dos temporadas, una por año.
   ----------------------------------------------------------------------------- */
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (1, 'Vacaciones de inicio de año 2024', 'ALTA', 2024, DATE '2024-01-01', DATE '2024-01-08');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (2, 'Baja de enero a marzo 2024', 'BAJA', 2024, DATE '2024-01-09', DATE '2024-03-22');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (3, 'Semana Santa 2024', 'ALTA', 2024, DATE '2024-03-23', DATE '2024-03-31');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (4, 'Media de abril a junio 2024 (tramo 1)', 'MEDIA', 2024, DATE '2024-04-01', DATE '2024-05-10');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (5, 'Puente festivo de Ascensión 2024', 'ALTA', 2024, DATE '2024-05-11', DATE '2024-05-13');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (6, 'Media de abril a junio 2024 (tramo 2)', 'MEDIA', 2024, DATE '2024-05-14', DATE '2024-05-31');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (7, 'Puente festivo de Corpus Christi 2024', 'ALTA', 2024, DATE '2024-06-01', DATE '2024-06-03');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (8, 'Media de abril a junio 2024 (tramo 3)', 'MEDIA', 2024, DATE '2024-06-04', DATE '2024-06-07');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (9, 'Puente festivo de Sagrado Corazón 2024', 'ALTA', 2024, DATE '2024-06-08', DATE '2024-06-10');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (10, 'Media de abril a junio 2024 (tramo 4)', 'MEDIA', 2024, DATE '2024-06-11', DATE '2024-06-14');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (11, 'Vacaciones de mitad de año 2024', 'ALTA', 2024, DATE '2024-06-15', DATE '2024-07-15');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (12, 'Media de julio y agosto 2024 (tramo 1)', 'MEDIA', 2024, DATE '2024-07-16', DATE '2024-08-16');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (13, 'Puente festivo de Asunción 2024', 'ALTA', 2024, DATE '2024-08-17', DATE '2024-08-19');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (14, 'Media de julio y agosto 2024 (tramo 2)', 'MEDIA', 2024, DATE '2024-08-20', DATE '2024-08-31');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (15, 'Baja de septiembre a noviembre 2024 (tramo 1)', 'BAJA', 2024, DATE '2024-09-01', DATE '2024-10-11');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (16, 'Puente festivo de Día de la Raza 2024', 'ALTA', 2024, DATE '2024-10-12', DATE '2024-10-14');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (17, 'Semana de receso escolar 2024', 'MEDIA', 2024, DATE '2024-10-15', DATE '2024-10-20');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (18, 'Baja de septiembre a noviembre 2024 (tramo 2)', 'BAJA', 2024, DATE '2024-10-21', DATE '2024-11-01');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (19, 'Puente festivo de Todos los Santos 2024', 'ALTA', 2024, DATE '2024-11-02', DATE '2024-11-04');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (20, 'Baja de septiembre a noviembre 2024 (tramo 3)', 'BAJA', 2024, DATE '2024-11-05', DATE '2024-11-08');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (21, 'Puente festivo de Independencia de Cartagena 2024', 'ALTA', 2024, DATE '2024-11-09', DATE '2024-11-11');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (22, 'Baja de septiembre a noviembre 2024 (tramo 4)', 'BAJA', 2024, DATE '2024-11-12', DATE '2024-11-30');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (23, 'Media de comienzos de diciembre 2024', 'MEDIA', 2024, DATE '2024-12-01', DATE '2024-12-14');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (24, 'Vacaciones de fin de año 2024', 'ALTA', 2024, DATE '2024-12-15', DATE '2024-12-31');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (25, 'Vacaciones de inicio de año 2025', 'ALTA', 2025, DATE '2025-01-01', DATE '2025-01-06');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (26, 'Baja de enero a marzo 2025 (tramo 1)', 'BAJA', 2025, DATE '2025-01-07', DATE '2025-03-21');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (27, 'Puente festivo de San José 2025', 'ALTA', 2025, DATE '2025-03-22', DATE '2025-03-24');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (28, 'Baja de enero a marzo 2025 (tramo 2)', 'BAJA', 2025, DATE '2025-03-25', DATE '2025-03-31');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (29, 'Media de abril a junio 2025 (tramo 1)', 'MEDIA', 2025, DATE '2025-04-01', DATE '2025-04-11');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (30, 'Semana Santa 2025', 'ALTA', 2025, DATE '2025-04-12', DATE '2025-04-20');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (31, 'Media de abril a junio 2025 (tramo 2)', 'MEDIA', 2025, DATE '2025-04-21', DATE '2025-05-30');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (32, 'Puente festivo de Ascensión 2025', 'ALTA', 2025, DATE '2025-05-31', DATE '2025-06-02');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (33, 'Media de abril a junio 2025 (tramo 3)', 'MEDIA', 2025, DATE '2025-06-03', DATE '2025-06-14');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (34, 'Vacaciones de mitad de año 2025', 'ALTA', 2025, DATE '2025-06-15', DATE '2025-07-15');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (35, 'Media de julio y agosto 2025 (tramo 1)', 'MEDIA', 2025, DATE '2025-07-16', DATE '2025-08-15');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (36, 'Puente festivo de Asunción 2025', 'ALTA', 2025, DATE '2025-08-16', DATE '2025-08-18');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (37, 'Media de julio y agosto 2025 (tramo 2)', 'MEDIA', 2025, DATE '2025-08-19', DATE '2025-08-31');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (38, 'Baja de septiembre a noviembre 2025 (tramo 1)', 'BAJA', 2025, DATE '2025-09-01', DATE '2025-10-10');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (39, 'Puente festivo de Día de la Raza 2025', 'ALTA', 2025, DATE '2025-10-11', DATE '2025-10-13');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (40, 'Semana de receso escolar 2025', 'MEDIA', 2025, DATE '2025-10-14', DATE '2025-10-19');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (41, 'Baja de septiembre a noviembre 2025 (tramo 2)', 'BAJA', 2025, DATE '2025-10-20', DATE '2025-10-31');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (42, 'Puente festivo de Todos los Santos 2025', 'ALTA', 2025, DATE '2025-11-01', DATE '2025-11-03');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (43, 'Baja de septiembre a noviembre 2025 (tramo 3)', 'BAJA', 2025, DATE '2025-11-04', DATE '2025-11-14');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (44, 'Puente festivo de Independencia de Cartagena 2025', 'ALTA', 2025, DATE '2025-11-15', DATE '2025-11-17');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (45, 'Baja de septiembre a noviembre 2025 (tramo 4)', 'BAJA', 2025, DATE '2025-11-18', DATE '2025-11-30');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (46, 'Media de comienzos de diciembre 2025', 'MEDIA', 2025, DATE '2025-12-01', DATE '2025-12-14');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (47, 'Vacaciones de fin de año 2025', 'ALTA', 2025, DATE '2025-12-15', DATE '2025-12-31');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (48, 'Vacaciones de inicio de año 2026', 'ALTA', 2026, DATE '2026-01-01', DATE '2026-01-12');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (49, 'Baja de enero a marzo 2026 (tramo 1)', 'BAJA', 2026, DATE '2026-01-13', DATE '2026-03-20');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (50, 'Puente festivo de San José 2026', 'ALTA', 2026, DATE '2026-03-21', DATE '2026-03-23');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (51, 'Baja de enero a marzo 2026 (tramo 2)', 'BAJA', 2026, DATE '2026-03-24', DATE '2026-03-27');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (52, 'Semana Santa 2026', 'ALTA', 2026, DATE '2026-03-28', DATE '2026-04-05');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (53, 'Media de abril a junio 2026 (tramo 1)', 'MEDIA', 2026, DATE '2026-04-06', DATE '2026-05-15');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (54, 'Puente festivo de Ascensión 2026', 'ALTA', 2026, DATE '2026-05-16', DATE '2026-05-18');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (55, 'Media de abril a junio 2026 (tramo 2)', 'MEDIA', 2026, DATE '2026-05-19', DATE '2026-06-05');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (56, 'Puente festivo de Corpus Christi 2026', 'ALTA', 2026, DATE '2026-06-06', DATE '2026-06-08');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (57, 'Media de abril a junio 2026 (tramo 3)', 'MEDIA', 2026, DATE '2026-06-09', DATE '2026-06-12');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (58, 'Puente festivo de Sagrado Corazón 2026', 'ALTA', 2026, DATE '2026-06-13', DATE '2026-06-15');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (59, 'Vacaciones de mitad de año 2026', 'ALTA', 2026, DATE '2026-06-16', DATE '2026-07-15');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (60, 'Media de julio y agosto 2026 (tramo 1)', 'MEDIA', 2026, DATE '2026-07-16', DATE '2026-08-14');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (61, 'Puente festivo de Asunción 2026', 'ALTA', 2026, DATE '2026-08-15', DATE '2026-08-17');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (62, 'Media de julio y agosto 2026 (tramo 2)', 'MEDIA', 2026, DATE '2026-08-18', DATE '2026-08-31');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (63, 'Baja de septiembre a noviembre 2026 (tramo 1)', 'BAJA', 2026, DATE '2026-09-01', DATE '2026-10-09');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (64, 'Puente festivo de Día de la Raza 2026', 'ALTA', 2026, DATE '2026-10-10', DATE '2026-10-12');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (65, 'Semana de receso escolar 2026', 'MEDIA', 2026, DATE '2026-10-13', DATE '2026-10-18');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (66, 'Baja de septiembre a noviembre 2026 (tramo 2)', 'BAJA', 2026, DATE '2026-10-19', DATE '2026-10-30');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (67, 'Puente festivo de Todos los Santos 2026', 'ALTA', 2026, DATE '2026-10-31', DATE '2026-11-02');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (68, 'Baja de septiembre a noviembre 2026 (tramo 3)', 'BAJA', 2026, DATE '2026-11-03', DATE '2026-11-13');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (69, 'Puente festivo de Independencia de Cartagena 2026', 'ALTA', 2026, DATE '2026-11-14', DATE '2026-11-16');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (70, 'Baja de septiembre a noviembre 2026 (tramo 4)', 'BAJA', 2026, DATE '2026-11-17', DATE '2026-11-30');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (71, 'Media de comienzos de diciembre 2026', 'MEDIA', 2026, DATE '2026-12-01', DATE '2026-12-14');
INSERT INTO temporada (id_temporada, nombre, categoria, anio, fecha_inicio, fecha_fin) VALUES (72, 'Vacaciones de fin de año 2026', 'ALTA', 2026, DATE '2026-12-15', DATE '2026-12-31');
COMMIT;

/* -----------------------------------------------------------------------------
   6. CALENDARIO: un día por fila, derivado de los rangos de TEMPORADA.
      Si dos temporadas se solaparan, la PK (fecha) haría fallar este INSERT;
      si quedara un hueco, la verificación siguiente lo detecta.
   ----------------------------------------------------------------------------- */
INSERT INTO calendario (fecha, id_temporada, anio, mes, dia_semana, es_fin_de_semana)
SELECT d.fecha,
       t.id_temporada,
       EXTRACT(YEAR  FROM d.fecha),
       EXTRACT(MONTH FROM d.fecha),
       TRUNC(d.fecha) - TRUNC(d.fecha, 'IW') + 1,                 -- 1 = lunes (ISO)
       CASE WHEN TRUNC(d.fecha) - TRUNC(d.fecha, 'IW') >= 5 THEN 'S' ELSE 'N' END
  FROM (SELECT DATE '2024-01-01' + LEVEL - 1 AS fecha
          FROM dual
       CONNECT BY LEVEL <= DATE '2026-12-31' - DATE '2024-01-01' + 1) d
  JOIN temporada t
    ON d.fecha BETWEEN t.fecha_inicio AND t.fecha_fin;
COMMIT;

DECLARE
  v_dias NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_dias FROM calendario;
  IF v_dias <> DATE '2026-12-31' - DATE '2024-01-01' + 1 THEN
    RAISE_APPLICATION_ERROR(-20001, 'El calendario tiene huecos: ' || v_dias || ' días');
  END IF;
  DBMS_OUTPUT.PUT_LINE('Calendario completo: ' || v_dias || ' días sin huecos ni solapes.');
END;
/

/* -----------------------------------------------------------------------------
   7. HABITACION: entre 3 y 38 por alojamiento (634 en total).
      La mezcla de tipos y capacidades depende del tipo de alojamiento.
   ----------------------------------------------------------------------------- */
DECLARE
  TYPE t_num IS TABLE OF PLS_INTEGER;
  -- número de habitaciones de cada alojamiento, en orden de id_alojamiento
  v_num_hab t_num := t_num(
      6, 7, 4, 14, 6, 5, 4, 10,
      8, 7, 12, 12, 38, 34, 30, 24,
      16, 12, 9, 8, 6, 8, 14, 7,
      5, 4, 6, 28, 14, 6, 10, 8,
      5, 3, 32, 12, 5, 7, 6, 4,
      16, 7, 4, 9, 6, 6, 5, 20,
      12, 12, 7, 4, 12, 5, 30, 5,
      4, 5, 6, 3);
  v_tipo   VARCHAR2(10);
  v_cap    PLS_INTEGER;
  v_numero VARCHAR2(10);
  v_desc   VARCHAR2(300);
  r        NUMBER;
BEGIN
  DBMS_RANDOM.SEED(2026);   -- semilla fija: carga reproducible
  FOR a IN (SELECT id_alojamiento, id_tipo_alojamiento
              FROM alojamiento ORDER BY id_alojamiento) LOOP
    FOR i IN 1 .. v_num_hab(a.id_alojamiento) LOOP
      r := DBMS_RANDOM.VALUE;
      CASE a.id_tipo_alojamiento
        WHEN 2 THEN   -- Hotel: numeración por piso (101, 102 ... 201 ...)
          IF    r < 0.35 THEN v_tipo := 'SENCILLA'; v_cap := TRUNC(DBMS_RANDOM.VALUE(1, 3));
          ELSIF r < 0.82 THEN v_tipo := 'DOBLE';    v_cap := TRUNC(DBMS_RANDOM.VALUE(2, 4));
          ELSE                v_tipo := 'SUITE';    v_cap := TRUNC(DBMS_RANDOM.VALUE(2, 5));
          END IF;
          v_numero := TO_CHAR((TRUNC((i - 1) / 10) + 1) * 100 + MOD(i - 1, 10) + 1);
        WHEN 1 THEN   -- Finca cafetera
          IF    r < 0.50 THEN v_tipo := 'DOBLE';  v_cap := TRUNC(DBMS_RANDOM.VALUE(2, 4));
          ELSIF r < 0.70 THEN v_tipo := 'SUITE';  v_cap := TRUNC(DBMS_RANDOM.VALUE(2, 5));
          ELSE                v_tipo := 'CABANA'; v_cap := TRUNC(DBMS_RANDOM.VALUE(4, 8));
          END IF;
          v_numero := 'H' || i;
        WHEN 3 THEN   -- Glamping: domos y cabañas
          IF r < 0.55 THEN v_tipo := 'SUITE';  v_cap := 2;
          ELSE             v_tipo := 'CABANA'; v_cap := TRUNC(DBMS_RANDOM.VALUE(2, 6));
          END IF;
          v_numero := 'D' || LPAD(i, 2, '0');
        WHEN 4 THEN   -- Hostal
          IF r < 0.40 THEN v_tipo := 'SENCILLA'; v_cap := 1;
          ELSE             v_tipo := 'DOBLE';    v_cap := TRUNC(DBMS_RANDOM.VALUE(2, 5));
          END IF;
          v_numero := TO_CHAR(i);
        ELSE          -- Ecohotel
          IF    r < 0.50 THEN v_tipo := 'DOBLE';  v_cap := TRUNC(DBMS_RANDOM.VALUE(2, 4));
          ELSIF r < 0.75 THEN v_tipo := 'SUITE';  v_cap := TRUNC(DBMS_RANDOM.VALUE(2, 5));
          ELSE                v_tipo := 'CABANA'; v_cap := TRUNC(DBMS_RANDOM.VALUE(3, 7));
          END IF;
          v_numero := 'E' || LPAD(i, 2, '0');
      END CASE;

      v_desc := CASE v_tipo
                  WHEN 'SENCILLA' THEN 'Habitación sencilla con cama semidoble y baño privado'
                  WHEN 'DOBLE'    THEN 'Habitación doble con cama queen o dos camas sencillas'
                  WHEN 'SUITE'    THEN 'Suite con cama king, sala y baño amplio'
                  ELSE                 'Cabaña independiente para grupos o familias'
                END
             || CASE TRUNC(DBMS_RANDOM.VALUE(1, 5))
                  WHEN 1 THEN ', con vista a las montañas'
                  WHEN 2 THEN ', con vista al cafetal'
                  WHEN 3 THEN ', con balcón'
                  ELSE ''
                END || '.';

      INSERT INTO habitacion (id_alojamiento, numero, tipo_habitacion, capacidad_maxima, descripcion)
      VALUES (a.id_alojamiento, v_numero, v_tipo, v_cap, v_desc);
    END LOOP;
  END LOOP;
  COMMIT;
END;
/

/* -----------------------------------------------------------------------------
   8. TARIFA: una por cada habitación × temporada (se deriva del cruce).
      valor = precio base del tipo de habitación
              × factor del tipo de alojamiento × factor de estrellas
              × variación propia de la habitación (ORA_HASH, fija)
              × factor de la categoría de temporada PROPIO DE CADA ALOJAMIENTO
                (unos suben 65 % en alta, otros solo 8 % para competir por volumen)
              × incremento anual (2025 +8,5 %, 2026 +16 %)
      redondeado a miles de pesos.
   ----------------------------------------------------------------------------- */
DECLARE
  f_tipo  NUMBER;
  f_est   NUMBER;
  f_alta  NUMBER;
  f_media NUMBER;
  f_baja  NUMBER;
BEGIN
  FOR a IN (SELECT id_alojamiento, id_tipo_alojamiento, estrellas
              FROM alojamiento ORDER BY id_alojamiento) LOOP
    f_tipo  := CASE a.id_tipo_alojamiento
                 WHEN 1 THEN 1.00 WHEN 2 THEN 1.05 WHEN 3 THEN 1.40
                 WHEN 4 THEN 0.42 ELSE 1.20 END;
    f_est   := 0.64 + 0.12 * a.estrellas;
    f_alta  := ROUND(DBMS_RANDOM.VALUE(1.08, 1.65), 3);
    f_media := ROUND(DBMS_RANDOM.VALUE(0.97, 1.05), 3);
    f_baja  := ROUND(DBMS_RANDOM.VALUE(0.75, 0.96), 3);

    INSERT INTO tarifa (id_habitacion, id_temporada, valor_noche, fecha_actualizacion)
    SELECT h.id_habitacion,
           t.id_temporada,
           ROUND(  CASE h.tipo_habitacion
                     WHEN 'SENCILLA' THEN 110000
                     WHEN 'DOBLE'    THEN 170000
                     WHEN 'SUITE'    THEN 290000
                     ELSE 240000 + 35000 * h.capacidad_maxima
                   END
                 * f_tipo * f_est
                 * (0.92 + MOD(ORA_HASH(h.id_habitacion), 17) / 100)
                 * CASE t.categoria
                     WHEN 'ALTA'  THEN f_alta * CASE WHEN t.nombre LIKE 'Puente%' THEN 0.93 ELSE 1 END
                     WHEN 'MEDIA' THEN f_media
                     ELSE f_baja
                   END
                 * CASE t.anio WHEN 2024 THEN 1 WHEN 2025 THEN 1.085 ELSE 1.16 END
                 , -3),
           t.fecha_inicio - 60
      FROM habitacion h
     CROSS JOIN temporada t
     WHERE h.id_alojamiento = a.id_alojamiento;
  END LOOP;
  COMMIT;
END;
/

/* -----------------------------------------------------------------------------
   9. CLIENTE: 3.000, con ciudad de origen ponderada (Bogotá, Medellín y Cali
      dominan; ~10 % extranjeros con pasaporte).
   ----------------------------------------------------------------------------- */
DECLARE
  TYPE t_txt IS TABLE OF VARCHAR2(40);
  TYPE t_num IS TABLE OF NUMBER;
  v_nf  t_txt := t_txt(
      'María', 'Laura', 'Valentina', 'Daniela', 'Camila', 'Paula', 'Natalia', 'Carolina',
      'Andrea', 'Juliana', 'Sofía', 'Manuela', 'Isabella', 'Sara', 'Diana', 'Alejandra',
      'Ana', 'Luisa', 'Mariana', 'Catalina', 'Gloria', 'Patricia', 'Claudia', 'Lina',
      'Ximena', 'Viviana', 'Adriana', 'Tatiana', 'Marcela', 'Angélica');
  v_nm  t_txt := t_txt(
      'Juan', 'Carlos', 'Andrés', 'Santiago', 'Sebastián', 'Daniel', 'Felipe', 'Alejandro',
      'David', 'Jorge', 'Luis', 'Miguel', 'Mateo', 'Nicolás', 'Camilo', 'Julián',
      'Diego', 'Óscar', 'Ricardo', 'Fernando', 'Esteban', 'Mauricio', 'Hernán', 'Jaime',
      'Gustavo', 'Alberto', 'Cristian', 'Samuel', 'Tomás', 'Gabriel');
  v_ap  t_txt := t_txt(
      'García', 'Rodríguez', 'Martínez', 'López', 'González', 'Hernández', 'Gómez', 'Díaz',
      'Ramírez', 'Sánchez', 'Torres', 'Rojas', 'Vargas', 'Moreno', 'Castro', 'Jiménez',
      'Muñoz', 'Ortiz', 'Restrepo', 'Giraldo', 'Ospina', 'Londoño', 'Cardona', 'Arango',
      'Marín', 'Quintero', 'Valencia', 'Henao', 'Osorio', 'Zuluaga', 'Agudelo', 'Castaño',
      'Ocampo', 'Montoya', 'Salazar', 'Echeverri', 'Patiño', 'Ríos', 'Duque', 'Mejía',
      'Álvarez', 'Ruiz', 'Correa', 'Escobar', 'Villegas', 'Bedoya', 'Betancur', 'Gutiérrez',
      'Pineda', 'Cárdenas');
  v_nx  t_txt := t_txt(
      'John', 'Emily', 'Michael', 'Sarah', 'Lucas', 'Emma', 'Thomas', 'Anna',
      'Pierre', 'Camille', 'Hans', 'Julia', 'Carlos', 'Lucía', 'Diego', 'Valeria',
      'James', 'Olivia', 'Daniel', 'Sophie');
  v_ax  t_txt := t_txt(
      'Smith', 'Johnson', 'Brown', 'Miller', 'Wilson', 'Martin', 'Dubois', 'Müller',
      'Schmidt', 'Fernández', 'Pérez', 'González', 'Silva', 'Santos', 'Taylor', 'Anderson',
      'Bernard', 'Rossi', 'López', 'Herrera');
  v_dom t_txt := t_txt('gmail.com','gmail.com','gmail.com','hotmail.com','outlook.com','yahoo.com','une.net.co');
  -- peso de cada ciudad (mismo orden que id_ciudad)
  v_peso t_num := t_num(
      240, 140, 120, 70, 45, 45, 35, 30,
      28, 20, 15, 15, 18, 16, 14, 14,
      10, 10, 10, 8, 7, 8, 9, 6,
      14, 8, 10, 12, 10, 5, 5, 7,
      6, 6, 6, 5, 6, 5, 4, 4,
      4);
  v_acum      t_num := t_num();
  v_total     NUMBER := 0;
  v_ciudad    PLS_INTEGER;
  v_pais      ciudad.pais%TYPE;
  v_n1        VARCHAR2(40);
  v_nombres   VARCHAR2(60);
  v_apellidos VARCHAR2(60);
  v_tipo_doc  VARCHAR2(3);
  v_doc       VARCHAR2(20);
  v_tel       VARCHAR2(20);
  v_correo    VARCHAR2(120);
  v_fregistro DATE;
  u           NUMBER;

  FUNCTION elegir(p t_txt) RETURN VARCHAR2 IS
  BEGIN
    RETURN p(TRUNC(DBMS_RANDOM.VALUE(1, p.COUNT + 1)));
  END;
BEGIN
  v_acum.EXTEND(v_peso.COUNT);
  FOR i IN 1 .. v_peso.COUNT LOOP
    v_total := v_total + v_peso(i);
    v_acum(i) := v_total;
  END LOOP;

  FOR i IN 1 .. 3000 LOOP
    -- ciudad ponderada
    u := DBMS_RANDOM.VALUE * v_total;
    v_ciudad := 1;
    WHILE v_acum(v_ciudad) < u LOOP v_ciudad := v_ciudad + 1; END LOOP;
    SELECT pais INTO v_pais FROM ciudad WHERE id_ciudad = v_ciudad;

    IF v_pais = 'Colombia' THEN
      IF DBMS_RANDOM.VALUE < 0.5 THEN v_n1 := elegir(v_nf); v_nombres := v_n1;
        IF DBMS_RANDOM.VALUE < 0.35 THEN v_nombres := v_nombres || ' ' || elegir(v_nf); END IF;
      ELSE v_n1 := elegir(v_nm); v_nombres := v_n1;
        IF DBMS_RANDOM.VALUE < 0.35 THEN v_nombres := v_nombres || ' ' || elegir(v_nm); END IF;
      END IF;
      v_apellidos := elegir(v_ap) || ' ' || elegir(v_ap);
      v_tipo_doc  := 'CC';
      -- intervalos disjuntos por cliente => documento único
      v_doc := TO_CHAR(10000000 + i * 330000 + TRUNC(DBMS_RANDOM.VALUE(0, 330000)));
      v_tel := '3' || TO_CHAR(TRUNC(DBMS_RANDOM.VALUE(100000000, 999999999)));
    ELSE
      v_n1 := elegir(v_nx); v_nombres := v_n1;
      v_apellidos := elegir(v_ax);
      IF DBMS_RANDOM.VALUE < 0.8 THEN
        v_tipo_doc := 'PAS'; v_doc := 'PA' || TO_CHAR(1000000 + i * 97 + TRUNC(DBMS_RANDOM.VALUE(0, 97)));
      ELSE
        v_tipo_doc := 'CE';  v_doc := TO_CHAR(100000 + i * 53 + TRUNC(DBMS_RANDOM.VALUE(0, 53)));
      END IF;
      v_tel := '+' || TO_CHAR(TRUNC(DBMS_RANDOM.VALUE(1000000000, 9999999999)));
    END IF;

    -- Los valores se calculan en PL/SQL ANTES del INSERT: dentro de una
    -- sentencia SQL no se pueden llamar funciones locales del bloque.
    v_correo := LOWER(TRANSLATE(v_n1 || '.' || REPLACE(v_apellidos, ' ', ''),
                                'ÁÉÍÓÚáéíóúÑñÜüÖöÄä', 'AEIOUaeiouNnUuOoAa'))
                || i || '@' || elegir(v_dom);
    v_fregistro := DATE '2023-01-01' + TRUNC(DBMS_RANDOM.VALUE(0, 1369));  -- se ajusta en la sección 16

    INSERT INTO cliente (tipo_documento, numero_documento, nombres, apellidos, correo,
                         telefono, id_ciudad_origen, fecha_registro)
    VALUES (v_tipo_doc, v_doc, v_nombres, v_apellidos, v_correo,
            v_tel, v_ciudad, v_fregistro);
  END LOOP;
  COMMIT;
END;
/

/* -----------------------------------------------------------------------------
   10. USUARIO_SISTEMA: administradores de plataforma, gerente, auditor,
       encargados (ADMIN_ALOJAMIENTO) de al menos un alojamiento de cada tipo
       y recepcionistas. Los usernames serán los usuarios Oracle de la Entrega 3.
   ----------------------------------------------------------------------------- */
INSERT INTO usuario_sistema (username, nombre_completo, correo, rol, id_alojamiento, fecha_creacion) VALUES ('ADMIN_TURISMOUQ', 'Laura Marcela Giraldo', 'admin_turismouq@turismouq.co', 'ADMIN_PLATAFORMA', NULL, DATE '2023-12-01');
INSERT INTO usuario_sistema (username, nombre_completo, correo, rol, id_alojamiento, fecha_creacion) VALUES ('ADMIN_SOPORTE', 'Andrés Felipe Ocampo', 'admin_soporte@turismouq.co', 'ADMIN_PLATAFORMA', NULL, DATE '2023-12-01');
INSERT INTO usuario_sistema (username, nombre_completo, correo, rol, id_alojamiento, fecha_creacion) VALUES ('GERENTE_GENERAL', 'Carolina Restrepo Arango', 'gerente_general@turismouq.co', 'GERENTE', NULL, DATE '2023-12-01');
INSERT INTO usuario_sistema (username, nombre_completo, correo, rol, id_alojamiento, fecha_creacion) VALUES ('AUDITOR_INTERNO', 'Jorge Iván Castaño', 'auditor_interno@turismouq.co', 'AUDITOR', NULL, DATE '2023-12-01');
INSERT INTO usuario_sistema (username, nombre_completo, correo, rol, id_alojamiento, fecha_creacion) VALUES ('ENC_OCOBO', 'María Fernanda Londoño', 'enc_ocobo@turismouq.co', 'ADMIN_ALOJAMIENTO', 1, DATE '2023-12-01');
INSERT INTO usuario_sistema (username, nombre_completo, correo, rol, id_alojamiento, fecha_creacion) VALUES ('ENC_GRAN_ARMENIA', 'Juan Pablo Henao', 'enc_gran_armenia@turismouq.co', 'ADMIN_ALOJAMIENTO', 13, DATE '2023-12-01');
INSERT INTO usuario_sistema (username, nombre_completo, correo, rol, id_alojamiento, fecha_creacion) VALUES ('ENC_BOSQUE_NIEBLA', 'Valentina Cardona', 'enc_bosque_niebla@turismouq.co', 'ADMIN_ALOJAMIENTO', 5, DATE '2023-12-01');
INSERT INTO usuario_sistema (username, nombre_completo, correo, rol, id_alojamiento, fecha_creacion) VALUES ('ENC_FLORESTA', 'Santiago Valencia', 'enc_floresta@turismouq.co', 'ADMIN_ALOJAMIENTO', 8, DATE '2023-12-01');
INSERT INTO usuario_sistema (username, nombre_completo, correo, rol, id_alojamiento, fecha_creacion) VALUES ('ENC_SENDEROS', 'Natalia Quintero', 'enc_senderos@turismouq.co', 'ADMIN_ALOJAMIENTO', 12, DATE '2023-12-01');
INSERT INTO usuario_sistema (username, nombre_completo, correo, rol, id_alojamiento, fecha_creacion) VALUES ('ENC_PUEBLO_TAPAO', 'Daniel Esteban Marín', 'enc_pueblo_tapao@turismouq.co', 'ADMIN_ALOJAMIENTO', 28, DATE '2023-12-01');
INSERT INTO usuario_sistema (username, nombre_completo, correo, rol, id_alojamiento, fecha_creacion) VALUES ('RECEP_GRAN_ARMENIA', 'Paula Andrea Gómez', 'recep_gran_armenia@turismouq.co', 'RECEPCION', 13, DATE '2023-12-01');
INSERT INTO usuario_sistema (username, nombre_completo, correo, rol, id_alojamiento, fecha_creacion) VALUES ('RECEP_PUEBLO_TAPAO', 'Camilo Andrés Ríos', 'recep_pueblo_tapao@turismouq.co', 'RECEPCION', 28, DATE '2023-12-01');
INSERT INTO usuario_sistema (username, nombre_completo, correo, rol, id_alojamiento, fecha_creacion) VALUES ('RECEP_OCOBO', 'Luisa Fernanda Arias', 'recep_ocobo@turismouq.co', 'RECEPCION', 1, DATE '2023-12-01');
INSERT INTO usuario_sistema (username, nombre_completo, correo, rol, id_alojamiento, fecha_creacion) VALUES ('RECEP_ARRIEROS', 'Sebastián Morales', 'recep_arrieros@turismouq.co', 'RECEPCION', 35, DATE '2023-12-01');
COMMIT;

/* -----------------------------------------------------------------------------
   11. SERVICIO: catálogo propio de cada alojamiento.
       Hoteles 3-6, fincas 2-5, glampings 2-4, ecohoteles 3-5, hostales 0-2
       (solo básicos); además ~15 % de los alojamientos no ofrece servicios.
       Mismo nombre en dos alojamientos = dos servicios distintos con su precio.
   ----------------------------------------------------------------------------- */
DECLARE
  TYPE t_txt  IS TABLE OF VARCHAR2(300);
  TYPE t_num  IS TABLE OF NUMBER;
  TYPE t_bool IS TABLE OF BOOLEAN INDEX BY PLS_INTEGER;
  v_nom    t_txt := t_txt(
      'Desayuno típico', 'Alquiler de bicicleta', 'Tour del café', 'Lavandería', 'Transporte al aeropuerto El Edén', 'Caminata guiada por el Valle de Cocora', 'Cabalgata por el cafetal', 'Avistamiento de aves',
      'Masaje relajante', 'Cena campestre', 'Fogata y noche de estrellas', 'Clase de barismo', 'Yoga al amanecer', 'Pasadía a parque temático');
  v_precio t_num := t_num(
      22000, 40000, 65000, 25000, 90000, 85000, 80000, 75000,
      140000, 95000, 35000, 70000, 38000, 160000);
  v_desc   t_txt := t_txt(
      'Desayuno paisa con arepa, huevos, fruta y café de la región (por persona y noche).', 'Bicicleta por día con casco y mapa de rutas.', 'Recorrido por el cafetal: siembra, cosecha, beneficio y catación.', 'Lavado y secado de una carga de ropa.', 'Traslado privado ida o regreso al aeropuerto de Armenia.', 'Caminata de medio día con guía local y transporte.', 'Paseo a caballo de dos horas por senderos de la finca.', 'Salida al amanecer con guía especializado y binoculares.',
      'Masaje de 60 minutos con aceites de café.', 'Cena de tres tiempos con productos locales.', 'Fogata con bebidas calientes y observación del cielo.', 'Taller de métodos de preparación de café de origen.', 'Sesión de yoga de 60 minutos al aire libre.', 'Entrada a un parque temático de la región con transporte ida y regreso.');
  v_usado  t_bool;
  v_n      PLS_INTEGER;
  v_max    PLS_INTEGER;   -- hasta qué posición del catálogo puede elegir
  v_k      PLS_INTEGER;
  v_puestos PLS_INTEGER;
  f_tipo   NUMBER;
  v_nombre_srv servicio.nombre%TYPE;
  v_desc_srv   servicio.descripcion%TYPE;
  v_precio_srv servicio.precio%TYPE;
BEGIN
  FOR a IN (SELECT id_alojamiento, id_tipo_alojamiento
              FROM alojamiento ORDER BY id_alojamiento) LOOP
    CASE a.id_tipo_alojamiento
      WHEN 2 THEN v_n := TRUNC(DBMS_RANDOM.VALUE(3, 7)); v_max := 14; f_tipo := 1.10;
      WHEN 1 THEN v_n := TRUNC(DBMS_RANDOM.VALUE(2, 6)); v_max := 14; f_tipo := 1.00;
      WHEN 3 THEN v_n := TRUNC(DBMS_RANDOM.VALUE(2, 5)); v_max := 14; f_tipo := 1.25;
      WHEN 4 THEN v_n := TRUNC(DBMS_RANDOM.VALUE(0, 3)); v_max := 6;  f_tipo := 0.80;
      ELSE        v_n := TRUNC(DBMS_RANDOM.VALUE(3, 6)); v_max := 14; f_tipo := 1.15;
    END CASE;
    IF DBMS_RANDOM.VALUE < 0.15 THEN v_n := 0; END IF;

    v_usado.DELETE;
    v_puestos := 0;
    WHILE v_puestos < v_n LOOP
      v_k := TRUNC(DBMS_RANDOM.VALUE(1, v_max + 1));
      IF NOT v_usado.EXISTS(v_k) THEN
        v_usado(v_k) := TRUE;
        v_puestos := v_puestos + 1;
        v_nombre_srv := v_nom(v_k);
        v_desc_srv   := v_desc(v_k);
        v_precio_srv := ROUND(v_precio(v_k) * f_tipo * DBMS_RANDOM.VALUE(0.85, 1.25), -3);
        INSERT INTO servicio (id_alojamiento, nombre, descripcion, precio)
        VALUES (a.id_alojamiento, v_nombre_srv, v_desc_srv, v_precio_srv);
      END IF;
    END LOOP;
  END LOOP;
  COMMIT;
END;
/

/* -----------------------------------------------------------------------------
   12. RESERVA + RESERVA_HABITACION: 30.000 reservas entre 2024-01-01 y
       2026-12-31.
       - Fecha de llegada: muestreo por aceptación-rechazo con un peso por día:
           ALTA 1,0 · MEDIA 0,5 · BAJA 0,27
           × 1,35 si llega viernes o sábado
           × crecimiento anual (2024 0,82 · 2025 1,0 · 2026 1,12)
           × 0,5 después de la fecha de corte (aún no se ha reservado todo).
       - Alojamiento: ponderado por número de habitaciones, atractivo del
         municipio, tipo y un factor propio de cada alojamiento.
       - Noches: distribución exponencial, más largas en temporada alta.
       - 83 % reserva 1 habitación, el resto 2 a 6 (grupos); desde la segunda
         línea, 25 % llega un día después (fechas distintas por línea).
       - Disponibilidad: un arreglo asociativo (habitación-día) impide que dos
         reservas no canceladas ocupen la misma habitación la misma noche.
       - valor_estadia se calcula al final, noche por noche, cruzando
         CALENDARIO con TARIFA (la misma lógica de fn_valor_estadia).
   ----------------------------------------------------------------------------- */
DECLARE
  c_corte   CONSTANT DATE := DATE '2026-10-01';
  c_ini     CONSTANT DATE := DATE '2024-01-01';
  c_max_out CONSTANT PLS_INTEGER := DATE '2026-12-31' - DATE '2024-01-01';  -- checkout máximo (desfase)
  c_meta    CONSTANT PLS_INTEGER := 30000;

  TYPE t_num IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
  TYPE t_occ IS TABLE OF BOOLEAN INDEX BY VARCHAR2(24);

  v_peso_dia t_num;  v_es_alta t_num;  v_wmax NUMBER := 0;
  v_aloj_id  t_num;  v_aloj_acum t_num; v_aloj_ini t_num; v_aloj_cnt t_num;
  v_naloj    PLS_INTEGER := 0; v_total_peso NUMBER := 0;
  v_hab_id   t_num;  v_hab_cap t_num;  v_nhab PLS_INTEGER := 0;
  v_cli      t_num;
  v_occ      t_occ;
  v_sel      t_num;  v_lin_ini t_num;

  v_desde PLS_INTEGER; v_hasta PLS_INTEGER;
  k PLS_INTEGER; ia PLS_INTEGER; p PLS_INTEGER; n PLS_INTEGER; li PLS_INTEGER; j0 PLS_INTEGER;
  w NUMBER; u NUMBER; r NUMBER;
  v_noches PLS_INTEGER; v_nlin PLS_INTEGER; v_ant PLS_INTEGER; v_hues PLS_INTEGER;
  v_checkin DATE; v_checkout DATE; v_freserva DATE; v_fcancel DATE;
  v_estado VARCHAR2(12);
  v_cancel BOOLEAN; v_libre BOOLEAN;
  v_id_reserva reserva.id_reserva%TYPE;
  v_id_cliente reserva.id_cliente%TYPE;
  v_id_aloj    reserva.id_alojamiento%TYPE;
  v_id_hab     habitacion.id_habitacion%TYPE;
  v_lin_in     DATE;
  v_creadas PLS_INTEGER := 0; v_intentos PLS_INTEGER := 0; v_sin_cupo PLS_INTEGER := 0;
BEGIN
  -- 12.1 Peso de cada día como fecha de llegada
  FOR d IN (SELECT c.fecha, c.anio, c.dia_semana, t.categoria
              FROM calendario c JOIN temporada t ON t.id_temporada = c.id_temporada) LOOP
    k := d.fecha - c_ini;
    w := CASE d.categoria WHEN 'ALTA' THEN 1 WHEN 'MEDIA' THEN 0.5 ELSE 0.27 END
       * CASE WHEN d.dia_semana IN (5, 6) THEN 1.35 ELSE 1 END
       * CASE d.anio WHEN 2024 THEN 0.82 WHEN 2025 THEN 1 ELSE 1.12 END
       * CASE WHEN d.fecha > c_corte THEN 0.5 ELSE 1 END;
    v_peso_dia(k) := w;
    v_es_alta(k)  := CASE WHEN d.categoria = 'ALTA' THEN 1 ELSE 0 END;
    IF w > v_wmax THEN v_wmax := w; END IF;
  END LOOP;

  -- 12.2 Peso de cada alojamiento y lista de sus habitaciones
  FOR al IN (SELECT a.id_alojamiento, a.id_municipio, a.id_tipo_alojamiento,
                    (SELECT COUNT(*) FROM habitacion h
                      WHERE h.id_alojamiento = a.id_alojamiento) AS nhab
               FROM alojamiento a ORDER BY a.id_alojamiento) LOOP
    v_naloj := v_naloj + 1;
    v_aloj_id(v_naloj) := al.id_alojamiento;
    w := POWER(al.nhab, 0.8)
       * CASE al.id_municipio         -- atractivo turístico del municipio
           WHEN 12 THEN 1.60  -- Salento
           WHEN 6  THEN 1.35  -- Filandia
           WHEN 9  THEN 1.35  -- Montenegro
           WHEN 11 THEN 1.20  -- Quimbaya
           WHEN 4  THEN 1.00  -- Circasia
           WHEN 2  THEN 0.90  -- Buenavista
           WHEN 3  THEN 0.90  -- Calarcá
           WHEN 1  THEN 0.85  -- Armenia
           WHEN 8  THEN 0.80  -- La Tebaida
           WHEN 10 THEN 0.65  -- Pijao
           WHEN 5  THEN 0.60  -- Córdoba
           ELSE         0.55  -- Génova
         END
       * CASE al.id_tipo_alojamiento WHEN 3 THEN 1.3 WHEN 4 THEN 1.1 ELSE 1 END
       * DBMS_RANDOM.VALUE(0.5, 1.6);  -- reputación propia del alojamiento
    v_total_peso := v_total_peso + w;
    v_aloj_acum(v_naloj) := v_total_peso;
    v_aloj_ini(v_naloj)  := v_nhab + 1;
    v_aloj_cnt(v_naloj)  := al.nhab;
    FOR h IN (SELECT id_habitacion, capacidad_maxima FROM habitacion
               WHERE id_alojamiento = al.id_alojamiento ORDER BY id_habitacion) LOOP
      v_nhab := v_nhab + 1;
      v_hab_id(v_nhab)  := h.id_habitacion;
      v_hab_cap(v_nhab) := h.capacidad_maxima;
    END LOOP;
  END LOOP;

  SELECT id_cliente BULK COLLECT INTO v_cli FROM cliente ORDER BY id_cliente;

  -- 12.3 Generación
  WHILE v_creadas < c_meta AND v_intentos < 3000000 LOOP
    v_intentos := v_intentos + 1;

    -- día de llegada (aceptación-rechazo según el peso del día)
    k := TRUNC(DBMS_RANDOM.VALUE(0, c_max_out));
    CONTINUE WHEN DBMS_RANDOM.VALUE * v_wmax > v_peso_dia(k);

    -- noches
    v_noches := 1 + TRUNC(-LN(1 - DBMS_RANDOM.VALUE)
                          * CASE WHEN v_es_alta(k) = 1 THEN 2.4 ELSE 1.3 END);
    IF v_noches > 14 THEN v_noches := 14; END IF;
    IF k + v_noches > c_max_out THEN v_noches := c_max_out - k; END IF;
    v_checkin  := c_ini + k;
    v_checkout := v_checkin + v_noches;

    -- alojamiento ponderado
    u := DBMS_RANDOM.VALUE * v_total_peso;
    ia := 1;
    WHILE ia < v_naloj AND v_aloj_acum(ia) < u LOOP ia := ia + 1; END LOOP;

    -- cuántas habitaciones
    r := DBMS_RANDOM.VALUE;
    v_nlin := CASE WHEN r < 0.83 THEN 1 WHEN r < 0.95 THEN 2 WHEN r < 0.99 THEN 3
                   ELSE 4 + TRUNC(DBMS_RANDOM.VALUE(0, 3)) END;
    v_nlin := LEAST(v_nlin, v_aloj_cnt(ia));
    v_cancel := DBMS_RANDOM.VALUE < 0.085;

    -- elegir habitaciones libres, empezando en una posición al azar
    v_sel.DELETE; v_lin_ini.DELETE; n := 0;
    j0 := TRUNC(DBMS_RANDOM.VALUE(0, v_aloj_cnt(ia)));
    v_hasta := v_aloj_cnt(ia) - 1;
    FOR j IN 0 .. v_hasta LOOP
      EXIT WHEN n = v_nlin;
      p  := v_aloj_ini(ia) + MOD(j0 + j, v_aloj_cnt(ia));
      li := k;
      IF n >= 1 AND v_noches > 1 AND DBMS_RANDOM.VALUE < 0.25 THEN
        li := k + 1;                       -- este integrante llega un día después
      END IF;
      v_libre := TRUE;
      IF NOT v_cancel THEN                 -- una cancelada no ocupa la habitación
        FOR d IN li .. k + v_noches - 1 LOOP
          IF v_occ.EXISTS(v_hab_id(p) || '-' || d) THEN
            v_libre := FALSE; EXIT;
          END IF;
        END LOOP;
      END IF;
      IF v_libre THEN
        n := n + 1; v_sel(n) := p; v_lin_ini(n) := li;
      END IF;
    END LOOP;
    IF n = 0 THEN
      v_sin_cupo := v_sin_cupo + 1;        -- alojamiento lleno esas fechas
      CONTINUE;
    END IF;

    -- fecha en que se hizo la reserva (anticipación mayor en temporada alta)
    v_ant := TRUNC(-LN(1 - DBMS_RANDOM.VALUE)
                   * CASE WHEN v_es_alta(k) = 1 THEN 30 ELSE 12 END);
    IF v_ant > 150 THEN v_ant := 150; END IF;
    v_freserva := v_checkin - v_ant;
    IF v_freserva > c_corte THEN
      v_freserva := c_corte - TRUNC(DBMS_RANDOM.VALUE(0, 25));
    END IF;

    -- estado según la fecha de corte
    v_fcancel := NULL;
    IF v_cancel THEN
      v_estado  := 'CANCELADA';
      v_fcancel := v_freserva
                 + TRUNC(DBMS_RANDOM.VALUE(0, LEAST(v_checkin, c_corte) - v_freserva + 1));
    ELSIF v_checkout <= c_corte THEN
      v_estado := 'COMPLETADA';
    ELSIF v_checkin <= c_corte THEN
      v_estado := 'CONFIRMADA';            -- huéspedes alojados el día de corte
    ELSIF DBMS_RANDOM.VALUE < 0.65 THEN
      v_estado := 'CONFIRMADA';
    ELSE
      v_estado := 'PENDIENTE';
    END IF;

    -- Elementos de colecciones PL/SQL se pasan a variables escalares antes del
    -- INSERT (en SQL solo pueden usarse tipos SQL).
    v_id_cliente := v_cli(1 + TRUNC(v_cli.COUNT * POWER(DBMS_RANDOM.VALUE, 1.6)));  -- clientes frecuentes
    v_id_aloj    := v_aloj_id(ia);

    INSERT INTO reserva (id_cliente, id_alojamiento, fecha_reserva, fecha_checkin,
                         fecha_checkout, estado, fecha_cancelacion)
    VALUES (v_id_cliente, v_id_aloj, v_freserva, v_checkin, v_checkout, v_estado, v_fcancel)
    RETURNING id_reserva INTO v_id_reserva;

    FOR x IN 1 .. n LOOP
      p := v_sel(x);
      v_hues   := 1 + TRUNC(POWER(DBMS_RANDOM.VALUE, 0.6) * v_hab_cap(p));
      v_id_hab := v_hab_id(p);
      v_lin_in := c_ini + v_lin_ini(x);
      INSERT INTO reserva_habitacion (id_reserva, id_alojamiento, id_habitacion,
                                      fecha_checkin, fecha_checkout, num_huespedes, valor_estadia)
      VALUES (v_id_reserva, v_id_aloj, v_id_hab, v_lin_in, v_checkout, v_hues, 0);
      IF NOT v_cancel THEN
        v_desde := v_lin_ini(x);
        FOR d IN v_desde .. k + v_noches - 1 LOOP
          v_occ(v_hab_id(p) || '-' || d) := TRUE;
        END LOOP;
      END IF;
    END LOOP;

    v_creadas := v_creadas + 1;
    IF MOD(v_creadas, 5000) = 0 THEN COMMIT; END IF;
  END LOOP;
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Reservas creadas: ' || v_creadas || ' (intentos: ' || v_intentos
                       || ', rechazadas por falta de cupo: ' || v_sin_cupo || ')');
END;
/

-- 12.4 Valor de cada línea: suma noche a noche de la tarifa vigente cada día.
UPDATE reserva_habitacion rh
   SET valor_estadia = (SELECT SUM(t.valor_noche)
                          FROM calendario c
                          JOIN tarifa t
                            ON t.id_temporada  = c.id_temporada
                           AND t.id_habitacion = rh.id_habitacion
                         WHERE c.fecha >= rh.fecha_checkin
                           AND c.fecha <  rh.fecha_checkout);
COMMIT;

/* -----------------------------------------------------------------------------
   13. RESERVA_SERVICIO: al menos 40.000 líneas.
       Solo reservas no canceladas de alojamientos que ofrecen servicios.
       Desayuno: cantidad = huéspedes × noches; otros: 1..huéspedes unidades.
       precio_unitario copia el precio vigente del servicio.
   ----------------------------------------------------------------------------- */
DECLARE
  c_meta CONSTANT PLS_INTEGER := 42000;
  TYPE t_num IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
  v_srv_id t_num; v_srv_precio t_num; v_srv_desayuno t_num;
  v_ini t_num; v_cnt t_num;            -- indexados por id_alojamiento
  v_i PLS_INTEGER := 0;
  v_n PLS_INTEGER; p PLS_INTEGER; v_cant PLS_INTEGER;
  v_total PLS_INTEGER := 0;
  v_id_srv   servicio.id_servicio%TYPE;
  v_precio_u servicio.precio%TYPE;
BEGIN
  FOR s IN (SELECT id_servicio, id_alojamiento, precio, nombre
              FROM servicio ORDER BY id_alojamiento, id_servicio) LOOP
    v_i := v_i + 1;
    v_srv_id(v_i) := s.id_servicio;
    v_srv_precio(v_i) := s.precio;
    v_srv_desayuno(v_i) := CASE WHEN s.nombre LIKE 'Desayuno%' THEN 1 ELSE 0 END;
    IF NOT v_cnt.EXISTS(s.id_alojamiento) THEN
      v_ini(s.id_alojamiento) := v_i; v_cnt(s.id_alojamiento) := 0;
    END IF;
    v_cnt(s.id_alojamiento) := v_cnt(s.id_alojamiento) + 1;
  END LOOP;

  FOR pasada IN 1 .. 8 LOOP
    EXIT WHEN v_total >= c_meta;
    FOR r IN (SELECT r.id_reserva, r.id_alojamiento,
                     r.fecha_checkout - r.fecha_checkin AS noches,
                     (SELECT SUM(x.num_huespedes) FROM reserva_habitacion x
                       WHERE x.id_reserva = r.id_reserva) AS huespedes
                FROM reserva r
               WHERE r.estado <> 'CANCELADA'
               ORDER BY DBMS_RANDOM.VALUE) LOOP
      EXIT WHEN v_total >= c_meta;
      IF v_cnt.EXISTS(r.id_alojamiento) THEN
        -- primera pasada: 0..n servicios; siguientes: completar la meta
        v_n := CASE WHEN pasada = 1
                    THEN TRUNC(DBMS_RANDOM.VALUE(0, v_cnt(r.id_alojamiento) + 1))
                    ELSE CASE WHEN DBMS_RANDOM.VALUE < 0.3 THEN 1 ELSE 0 END
               END;
        FOR x IN 1 .. v_n LOOP
          p := v_ini(r.id_alojamiento) + TRUNC(DBMS_RANDOM.VALUE(0, v_cnt(r.id_alojamiento)));
          v_cant := CASE WHEN v_srv_desayuno(p) = 1
                         THEN LEAST(99, r.huespedes * r.noches)
                         ELSE 1 + TRUNC(DBMS_RANDOM.VALUE(0, r.huespedes)) END;
          v_id_srv   := v_srv_id(p);
          v_precio_u := v_srv_precio(p);
          BEGIN
            INSERT INTO reserva_servicio (id_reserva, id_alojamiento, id_servicio,
                                          cantidad, precio_unitario)
            VALUES (r.id_reserva, r.id_alojamiento, v_id_srv, v_cant, v_precio_u);
            v_total := v_total + 1;
          EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN NULL;   -- ese servicio ya estaba en la reserva
          END;
        END LOOP;
      END IF;
    END LOOP;
    COMMIT;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('Líneas de servicio: ' || v_total);
END;
/

/* -----------------------------------------------------------------------------
   14. PAGO
       COMPLETADA y CONFIRMADA ya alojada: 55 % pago total al reservar;
         45 % anticipo (30-50 %) al reservar + saldo el día del check-in.
       CONFIRMADA futura: 30 % pago total, 70 % solo anticipo.
       PENDIENTE: pago PENDIENTE (PSE en proceso), un intento FALLIDO o nada.
       CANCELADA: 60 % había pagado anticipo. Si canceló con MÁS de 5 días de
         anticipación => REEMBOLSADO con 80 %; si no, el pago queda EXITOSO
         (el alojamiento retiene el dinero).
       6 % de los pagos electrónicos exitosos va precedido de un intento FALLIDO.
   ----------------------------------------------------------------------------- */
DECLARE
  c_corte CONSTANT DATE := DATE '2026-10-01';
  v_anticipo NUMBER;
  v_n PLS_INTEGER := 0;
  u NUMBER;

  FUNCTION metodo(p_presencial BOOLEAN) RETURN VARCHAR2 IS
    x NUMBER := DBMS_RANDOM.VALUE;
  BEGIN
    IF p_presencial AND x < 0.25 THEN RETURN 'EFECTIVO'; END IF;
    x := DBMS_RANDOM.VALUE;
    RETURN CASE WHEN x < 0.36 THEN 'TARJETA_CREDITO'
                WHEN x < 0.58 THEN 'TARJETA_DEBITO'
                WHEN x < 0.86 THEN 'PSE'
                ELSE 'TRANSFERENCIA' END;
  END;

  PROCEDURE pagar(p_reserva NUMBER, p_fecha DATE, p_concepto VARCHAR2, p_monto NUMBER,
                  p_metodo VARCHAR2, p_estado VARCHAR2,
                  p_reemb NUMBER DEFAULT NULL, p_freemb DATE DEFAULT NULL) IS
  BEGIN
    IF p_estado IN ('EXITOSO', 'REEMBOLSADO') AND p_metodo <> 'EFECTIVO'
       AND DBMS_RANDOM.VALUE < 0.06 THEN
      INSERT INTO pago (id_reserva, fecha_pago, concepto, monto, metodo, estado)
      VALUES (p_reserva, p_fecha, p_concepto, p_monto, p_metodo, 'FALLIDO');
    END IF;
    INSERT INTO pago (id_reserva, fecha_pago, concepto, monto, metodo, estado,
                      monto_reembolsado, fecha_reembolso)
    VALUES (p_reserva, p_fecha, p_concepto, p_monto, p_metodo, p_estado, p_reemb, p_freemb);
  END;
BEGIN
  FOR r IN (SELECT v.id_reserva, v.valor_total, x.estado, x.fecha_reserva,
                   x.fecha_checkin, x.fecha_cancelacion
              FROM vw_valor_reserva v
              JOIN reserva x ON x.id_reserva = v.id_reserva
             ORDER BY v.id_reserva) LOOP
    v_anticipo := ROUND(r.valor_total * DBMS_RANDOM.VALUE(0.3, 0.5), -3);
    IF v_anticipo <= 0 OR v_anticipo >= r.valor_total THEN v_anticipo := r.valor_total; END IF;
    u := DBMS_RANDOM.VALUE;

    IF r.estado = 'COMPLETADA' OR (r.estado = 'CONFIRMADA' AND r.fecha_checkin <= c_corte) THEN
      IF u < 0.55 OR v_anticipo = r.valor_total THEN
        pagar(r.id_reserva, r.fecha_reserva, 'TOTAL', r.valor_total, metodo(FALSE), 'EXITOSO');
      ELSE
        pagar(r.id_reserva, r.fecha_reserva, 'ANTICIPO', v_anticipo, metodo(FALSE), 'EXITOSO');
        pagar(r.id_reserva, r.fecha_checkin, 'SALDO', r.valor_total - v_anticipo, metodo(TRUE), 'EXITOSO');
      END IF;

    ELSIF r.estado = 'CONFIRMADA' THEN
      IF u < 0.30 THEN
        pagar(r.id_reserva, r.fecha_reserva, 'TOTAL', r.valor_total, metodo(FALSE), 'EXITOSO');
      ELSE
        pagar(r.id_reserva, r.fecha_reserva, 'ANTICIPO', v_anticipo, metodo(FALSE), 'EXITOSO');
      END IF;

    ELSIF r.estado = 'PENDIENTE' THEN
      IF u < 0.45 THEN
        pagar(r.id_reserva, r.fecha_reserva, 'ANTICIPO', v_anticipo, 'PSE', 'PENDIENTE');
      ELSIF u < 0.65 THEN
        pagar(r.id_reserva, r.fecha_reserva, 'ANTICIPO', v_anticipo, metodo(FALSE), 'FALLIDO');
      END IF;

    ELSE  -- CANCELADA
      IF u < 0.60 THEN
        IF r.fecha_checkin - r.fecha_cancelacion > 5 THEN
          pagar(r.id_reserva, r.fecha_reserva, 'ANTICIPO', v_anticipo, metodo(FALSE),
                'REEMBOLSADO', ROUND(v_anticipo * 0.8, 2), r.fecha_cancelacion);
        ELSE
          pagar(r.id_reserva, r.fecha_reserva, 'ANTICIPO', v_anticipo, metodo(FALSE), 'EXITOSO');
        END IF;
      END IF;
    END IF;

    v_n := v_n + 1;
    IF MOD(v_n, 5000) = 0 THEN COMMIT; END IF;
  END LOOP;
  COMMIT;
END;
/

/* -----------------------------------------------------------------------------
   15. RESENA: ~46 % de las reservas COMPLETADAS. Cada alojamiento tiene una
       "calidad real" propia (no siempre coincide con sus estrellas
       autoasignadas); la calificación = calidad + ruido normal, entre 1 y 5.
       72 % trae comentario; el resto lo deja vacío (es opcional).
   ----------------------------------------------------------------------------- */
DECLARE
  c_corte CONSTANT DATE := DATE '2026-10-01';
  TYPE t_txt IS TABLE OF VARCHAR2(200);
  TYPE t_num IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
  v_malo  t_txt := t_txt(
      'La habitación no correspondía a las fotos y el servicio fue lento.', 'Mucho ruido en la noche y el agua caliente fallaba.', 'No volvería: la limpieza dejó mucho que desear.', 'Cobraron servicios que no pedimos; la atención fue regular.', 'El acceso es muy difícil y no nos avisaron con anticipación.');
  v_medio t_txt := t_txt(
      'Buena ubicación, aunque las instalaciones necesitan mantenimiento.', 'Cumplió lo básico. El desayuno podría mejorar.', 'Bonito lugar, pero el wifi casi no funcionaba.', 'Atención amable, habitación algo pequeña para el precio.', 'Estuvo bien para una noche de paso.');
  v_bueno t_txt := t_txt(
      'Excelente atención y una vista increíble de las montañas.', 'El tour del café fue lo mejor del viaje. Totalmente recomendado.', 'Muy limpio, tranquilo y el personal siempre dispuesto a ayudar.', 'El desayuno típico delicioso y la habitación muy cómoda.', 'Volveremos con la familia, el paisaje cafetero es espectacular.', 'Perfecto para descansar, se escuchan los pájaros al amanecer.');
  v_calidad t_num;
  v_cal  PLS_INTEGER;
  v_com  VARCHAR2(500);
BEGIN
  FOR a IN (SELECT id_alojamiento FROM alojamiento ORDER BY id_alojamiento) LOOP
    v_calidad(a.id_alojamiento) := DBMS_RANDOM.VALUE(2.9, 4.8);
  END LOOP;

  FOR r IN (SELECT id_reserva, id_alojamiento, fecha_checkout
              FROM reserva WHERE estado = 'COMPLETADA' ORDER BY id_reserva) LOOP
    IF DBMS_RANDOM.VALUE < 0.46 THEN
      v_cal := ROUND(v_calidad(r.id_alojamiento) + DBMS_RANDOM.NORMAL * 0.85);
      v_cal := GREATEST(1, LEAST(5, v_cal));
      v_com := NULL;
      IF DBMS_RANDOM.VALUE < 0.72 THEN
        v_com := CASE
                   WHEN v_cal <= 2 THEN v_malo(TRUNC(DBMS_RANDOM.VALUE(1, v_malo.COUNT + 1)))
                   WHEN v_cal = 3  THEN v_medio(TRUNC(DBMS_RANDOM.VALUE(1, v_medio.COUNT + 1)))
                   ELSE                 v_bueno(TRUNC(DBMS_RANDOM.VALUE(1, v_bueno.COUNT + 1)))
                 END;
      END IF;
      INSERT INTO resena (id_reserva, calificacion, comentario, fecha_resena)
      VALUES (r.id_reserva, v_cal, v_com,
              LEAST(r.fecha_checkout + TRUNC(DBMS_RANDOM.VALUE(0, 21)), c_corte));
    END IF;
  END LOOP;
  COMMIT;
END;
/

/* -----------------------------------------------------------------------------
   16. Ajustes finales
   ----------------------------------------------------------------------------- */
-- 16.1 Un cliente se registra antes de su primera reserva.
UPDATE cliente c
   SET fecha_registro = NVL((SELECT MIN(TRUNC(r.fecha_reserva))
                               FROM reserva r WHERE r.id_cliente = c.id_cliente)
                            - MOD(ORA_HASH(c.id_cliente), 90),
                            fecha_registro);
COMMIT;

-- 16.2 Las tablas con id explícito continúan su IDENTITY después del máximo
--      cargado (si no, el próximo INSERT sin id chocaría con la PK).
ALTER TABLE municipio        MODIFY (id_municipio        GENERATED BY DEFAULT ON NULL AS IDENTITY (START WITH LIMIT VALUE));
ALTER TABLE tipo_alojamiento MODIFY (id_tipo_alojamiento GENERATED BY DEFAULT ON NULL AS IDENTITY (START WITH LIMIT VALUE));
ALTER TABLE ciudad           MODIFY (id_ciudad           GENERATED BY DEFAULT ON NULL AS IDENTITY (START WITH LIMIT VALUE));
ALTER TABLE alojamiento      MODIFY (id_alojamiento      GENERATED BY DEFAULT ON NULL AS IDENTITY (START WITH LIMIT VALUE));
ALTER TABLE temporada        MODIFY (id_temporada        GENERATED BY DEFAULT ON NULL AS IDENTITY (START WITH LIMIT VALUE));

-- 16.3 Estadísticas para el optimizador (planes de ejecución realistas).
BEGIN
  DBMS_STATS.GATHER_SCHEMA_STATS(ownname => USER);
END;
/

/* -----------------------------------------------------------------------------
   17. Verificación: volumen mínimo y reglas que la carga debe cumplir.
       Si algo falla, el bloque lanza un error con el detalle.
   ----------------------------------------------------------------------------- */
SELECT 'MUNICIPIO' AS tabla, COUNT(*) AS filas, 12 AS minimo FROM municipio
UNION ALL SELECT 'TIPO_ALOJAMIENTO', COUNT(*), 4     FROM tipo_alojamiento
UNION ALL SELECT 'CIUDAD',           COUNT(*), NULL  FROM ciudad
UNION ALL SELECT 'ALOJAMIENTO',      COUNT(*), 60    FROM alojamiento
UNION ALL SELECT 'HABITACION',       COUNT(*), 400   FROM habitacion
UNION ALL SELECT 'TEMPORADA',        COUNT(*), 6     FROM temporada
UNION ALL SELECT 'CALENDARIO',       COUNT(*), NULL  FROM calendario
UNION ALL SELECT 'TARIFA',           COUNT(*), NULL  FROM tarifa
UNION ALL SELECT 'CLIENTE',          COUNT(*), 3000  FROM cliente
UNION ALL SELECT 'RESERVA',          COUNT(*), 25000 FROM reserva
UNION ALL SELECT 'RESERVA_HABITACION', COUNT(*), 25000 FROM reserva_habitacion
UNION ALL SELECT 'PAGO',             COUNT(*), 25000 FROM pago
UNION ALL SELECT 'SERVICIO',         COUNT(*), 30    FROM servicio
UNION ALL SELECT 'RESERVA_SERVICIO', COUNT(*), 40000 FROM reserva_servicio
UNION ALL SELECT 'RESENA',           COUNT(*), NULL  FROM resena
UNION ALL SELECT 'USUARIO_SISTEMA',  COUNT(*), 10    FROM usuario_sistema;

DECLARE
  v NUMBER; v2 NUMBER;
  PROCEDURE validar(p_cond BOOLEAN, p_msg VARCHAR2) IS
  BEGIN
    IF NOT p_cond THEN RAISE_APPLICATION_ERROR(-20002, 'Verificación fallida: ' || p_msg); END IF;
    DBMS_OUTPUT.PUT_LINE('OK  ' || p_msg);
  END;
BEGIN
  SELECT COUNT(*) INTO v FROM reserva;            validar(v >= 25000, 'RESERVA >= 25.000 (' || v || ')');
  SELECT COUNT(*) INTO v FROM reserva_habitacion; validar(v >= 25000, 'RESERVA_HABITACION >= 25.000 (' || v || ')');
  SELECT COUNT(*) INTO v FROM pago;               validar(v >= 25000, 'PAGO >= 25.000 (' || v || ')');
  SELECT COUNT(*) INTO v FROM reserva_servicio;   validar(v >= 40000, 'RESERVA_SERVICIO >= 40.000 (' || v || ')');
  SELECT COUNT(*) INTO v FROM habitacion;         validar(v >= 400,   'HABITACION >= 400 (' || v || ')');
  SELECT COUNT(*) INTO v FROM servicio;           validar(v >= 30,    'SERVICIO >= 30 (' || v || ')');

  SELECT COUNT(*) INTO v FROM habitacion h CROSS JOIN temporada t;
  SELECT COUNT(*) INTO v2 FROM tarifa;
  validar(v = v2, 'TARIFA = habitaciones × temporadas (' || v2 || ')');

  SELECT COUNT(*) INTO v  FROM reserva WHERE estado = 'COMPLETADA';
  SELECT COUNT(*) INTO v2 FROM resena;
  validar(v2 >= 0.4 * v, 'RESENA >= 40 % de las completadas (' || ROUND(100 * v2 / v, 1) || ' %)');

  SELECT COUNT(*) INTO v FROM reserva r
   WHERE (SELECT COUNT(*) FROM reserva_habitacion x WHERE x.id_reserva = r.id_reserva) > 1;
  validar(v > 0, 'Hay reservas con varias habitaciones (' || v || ')');

  SELECT COUNT(*) INTO v FROM (SELECT id_reserva FROM pago GROUP BY id_reserva HAVING COUNT(*) > 1);
  validar(v > 0, 'Hay reservas con varios pagos (' || v || ')');

  -- Ninguna habitación con dos reservas activas que se solapen
  SELECT COUNT(*) INTO v
    FROM reserva_habitacion a
    JOIN reserva ra ON ra.id_reserva = a.id_reserva AND ra.estado <> 'CANCELADA'
    JOIN reserva_habitacion b
      ON b.id_habitacion = a.id_habitacion
     AND b.id_reserva_habitacion > a.id_reserva_habitacion
     AND a.fecha_checkin  < b.fecha_checkout
     AND b.fecha_checkin  < a.fecha_checkout
    JOIN reserva rb ON rb.id_reserva = b.id_reserva AND rb.estado <> 'CANCELADA';
  validar(v = 0, 'Sin solapes de reservas activas en una misma habitación');

  -- Las líneas quedan dentro del rango general de su reserva
  SELECT COUNT(*) INTO v FROM reserva_habitacion x JOIN reserva r ON r.id_reserva = x.id_reserva
   WHERE x.fecha_checkin < r.fecha_checkin OR x.fecha_checkout > r.fecha_checkout;
  validar(v = 0, 'Líneas dentro del rango de la reserva');

  -- Toda reserva completada está pagada
  SELECT COUNT(*) INTO v FROM vw_valor_reserva WHERE estado = 'COMPLETADA' AND pagada = 'N';
  validar(v = 0, 'Reservas completadas totalmente pagadas');

  -- Reseñas solo de reservas completadas
  SELECT COUNT(*) INTO v FROM resena s JOIN reserva r ON r.id_reserva = s.id_reserva
   WHERE r.estado <> 'COMPLETADA';
  validar(v = 0, 'Reseñas solo de reservas completadas');
END;
/

PROMPT === 02_carga_datos.sql terminado ===

