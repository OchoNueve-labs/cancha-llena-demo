-- =============================================
-- Cancha Llena Demo - Schema & Seed Data
-- =============================================
-- Run this in Supabase SQL Editor after creating the project.
-- IMPORTANT: Create auth user first: demo@canchallena.cl / demo1234

-- =============================================
-- SCHEMA
-- =============================================

CREATE TABLE IF NOT EXISTS reservas (
  id SERIAL PRIMARY KEY,
  cliente_id UUID,
  centro TEXT NOT NULL,
  tipo_cancha TEXT NOT NULL,
  cancha TEXT NOT NULL,
  fecha DATE NOT NULL,
  hora TEXT NOT NULL,
  duracion INTEGER DEFAULT 60,
  estado TEXT DEFAULT 'pendiente',
  canal_origen TEXT DEFAULT 'bot',
  nombre_cliente TEXT,
  telefono_cliente TEXT,
  rut_cliente TEXT,
  email_cliente TEXT,
  notas TEXT,
  codigo_easycancha TEXT,
  origen TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS slots (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  centro TEXT NOT NULL,
  tipo_cancha TEXT NOT NULL,
  cancha TEXT NOT NULL,
  fecha DATE NOT NULL,
  hora TEXT NOT NULL,
  duracion INTEGER DEFAULT 60,
  estado TEXT DEFAULT 'disponible',
  reserva_id INTEGER REFERENCES reservas(id),
  origen TEXT,
  cliente_nombre TEXT,
  cliente_telefono TEXT,
  cliente_rut TEXT,
  cliente_email TEXT,
  notas TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS clientes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  sender_id TEXT UNIQUE,
  nombre TEXT,
  telefono TEXT,
  rut TEXT,
  email TEXT,
  canal TEXT DEFAULT 'whatsapp',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS mensajes (
  id SERIAL PRIMARY KEY,
  sender_id TEXT,
  canal TEXT DEFAULT 'whatsapp',
  direccion TEXT DEFAULT 'outbound',
  contenido TEXT,
  message_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS mensajes_raw (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  sender_id TEXT,
  canal TEXT DEFAULT 'whatsapp',
  mensaje TEXT,
  message_id TEXT,
  sender_name TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS alertas (
  id SERIAL PRIMARY KEY,
  tipo TEXT DEFAULT 'reserva',
  reserva_id INTEGER,
  mensaje TEXT,
  canal TEXT,
  sender_id TEXT,
  leida BOOLEAN DEFAULT FALSE,
  resuelta BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS sessions (
  id SERIAL PRIMARY KEY,
  sender_id TEXT,
  estado TEXT DEFAULT 'activo',
  last_activity TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE reservas;
ALTER PUBLICATION supabase_realtime ADD TABLE slots;
ALTER PUBLICATION supabase_realtime ADD TABLE alertas;

-- RLS (allow all for authenticated users)
ALTER TABLE reservas ENABLE ROW LEVEL SECURITY;
ALTER TABLE slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE mensajes ENABLE ROW LEVEL SECURITY;
ALTER TABLE mensajes_raw ENABLE ROW LEVEL SECURITY;
ALTER TABLE alertas ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "auth_all" ON reservas FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all" ON slots FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all" ON clientes FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all" ON mensajes FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all" ON mensajes_raw FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all" ON alertas FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all" ON sessions FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Also allow anon read for realtime to work
CREATE POLICY "anon_read" ON reservas FOR SELECT TO anon USING (true);
CREATE POLICY "anon_read" ON slots FOR SELECT TO anon USING (true);
CREATE POLICY "anon_read" ON alertas FOR SELECT TO anon USING (true);

-- =============================================
-- SEED DATA
-- =============================================

-- 8 Clientes (datos ficticios para demo YouTube)
INSERT INTO clientes (sender_id, nombre, telefono, rut, email, canal) VALUES
  ('56900000001', 'Juan Demo', '+56900000001', '11.111.111-1', 'juan@demo.cl', 'whatsapp'),
  ('56900000002', 'Maria Ejemplo', '+56900000002', '22.222.222-2', 'maria@ejemplo.cl', 'whatsapp'),
  ('56900000003', 'Pedro Prueba', '+56900000003', '33.333.333-3', 'pedro@prueba.cl', 'whatsapp'),
  ('56900000004', 'Ana Muestra', '+56900000004', '44.444.444-4', 'ana@muestra.cl', 'whatsapp'),
  ('56900000005', 'Luis Test', '+56900000005', '55.555.555-5', 'luis@test.cl', 'whatsapp'),
  ('56900000006', 'Sofia Sample', '+56900000006', '66.666.666-6', 'sofia@sample.cl', 'whatsapp'),
  ('56900000007', 'Carlos Ficticio', '+56900000007', '77.777.777-7', 'carlos@ficticio.cl', 'whatsapp'),
  ('56900000008', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', 'whatsapp');

-- ~40 Reservas (fechas relativas a CURRENT_DATE)
INSERT INTO reservas (centro, tipo_cancha, cancha, fecha, hora, duracion, estado, canal_origen, nombre_cliente, telefono_cliente, rut_cliente, email_cliente, notas, created_at) VALUES
  -- Hace 7 dias
  ('Sede Norte', 'Futbolito', 'Cancha 1', CURRENT_DATE - INTERVAL '7 days', '18:00', 60, 'completada', 'bot', 'Juan Demo', '+56900000001', '11.111.111-1', 'juan@demo.cl', NULL, NOW() - INTERVAL '7 days'),
  ('Sede Norte', 'Futbolito', 'Cancha 3', CURRENT_DATE - INTERVAL '7 days', '19:00', 60, 'completada', 'easycancha', 'Maria Ejemplo', '+56900000002', '22.222.222-2', 'maria@ejemplo.cl', NULL, NOW() - INTERVAL '7 days'),
  ('Sede Sur', 'Futbolito', 'Cancha 2', CURRENT_DATE - INTERVAL '7 days', '20:00', 60, 'completada', 'telefono', 'Pedro Prueba', '+56900000003', '33.333.333-3', 'pedro@prueba.cl', 'Torneo empresas', NOW() - INTERVAL '7 days'),
  -- Hace 6 dias
  ('Sede Norte', 'Futbolito', 'Cancha 2', CURRENT_DATE - INTERVAL '6 days', '17:00', 60, 'completada', 'bot', 'Ana Muestra', '+56900000004', '44.444.444-4', 'ana@muestra.cl', NULL, NOW() - INTERVAL '6 days'),
  ('Sede Sur', 'Padel', 'Cancha 1', CURRENT_DATE - INTERVAL '6 days', '18:30', 90, 'completada', 'easycancha', 'Luis Test', '+56900000005', '55.555.555-5', 'luis@test.cl', 'Clase padel', NOW() - INTERVAL '6 days'),
  ('Sede Norte', 'Futbolito', 'Cancha 5', CURRENT_DATE - INTERVAL '6 days', '21:00', 60, 'cancelada', 'bot', 'Sofia Sample', '+56900000006', '66.666.666-6', 'sofia@sample.cl', NULL, NOW() - INTERVAL '6 days'),
  -- Hace 5 dias
  ('Sede Norte', 'Futbolito', 'Cancha 4', CURRENT_DATE - INTERVAL '5 days', '18:00', 60, 'confirmada', 'dashboard', 'Carlos Ficticio', '+56900000007', '77.777.777-7', 'carlos@ficticio.cl', 'Reserva semanal', NOW() - INTERVAL '5 days'),
  ('Sede Sur', 'Futbolito', 'Cancha 1', CURRENT_DATE - INTERVAL '5 days', '19:00', 60, 'confirmada', 'bot', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', NULL, NOW() - INTERVAL '5 days'),
  ('Sede Sur', 'Padel', 'Cancha 2', CURRENT_DATE - INTERVAL '5 days', '20:00', 60, 'cancelada', 'easycancha', 'Juan Demo', '+56900000001', '11.111.111-1', 'juan@demo.cl', NULL, NOW() - INTERVAL '5 days'),
  ('Sede Norte', 'Futbolito', 'Cancha 6', CURRENT_DATE - INTERVAL '5 days', '20:00', 60, 'confirmada', 'telefono', 'Maria Ejemplo', '+56900000002', '22.222.222-2', 'maria@ejemplo.cl', NULL, NOW() - INTERVAL '5 days'),
  -- Hace 4 dias
  ('Sede Norte', 'Futbolito', 'Cancha 1', CURRENT_DATE - INTERVAL '4 days', '17:00', 60, 'confirmada', 'bot', 'Pedro Prueba', '+56900000003', '33.333.333-3', 'pedro@prueba.cl', NULL, NOW() - INTERVAL '4 days'),
  ('Sede Norte', 'Futbolito', 'Cancha 2', CURRENT_DATE - INTERVAL '4 days', '18:00', 60, 'confirmada', 'easycancha', 'Ana Muestra', '+56900000004', '44.444.444-4', 'ana@muestra.cl', NULL, NOW() - INTERVAL '4 days'),
  ('Sede Sur', 'Futbolito', 'Cancha 3', CURRENT_DATE - INTERVAL '4 days', '19:00', 60, 'confirmada', 'bot', 'Luis Test', '+56900000005', '55.555.555-5', 'luis@test.cl', NULL, NOW() - INTERVAL '4 days'),
  ('Sede Sur', 'Padel', 'Cancha 3', CURRENT_DATE - INTERVAL '4 days', '17:30', 90, 'confirmada', 'dashboard', 'Sofia Sample', '+56900000006', '66.666.666-6', 'sofia@sample.cl', NULL, NOW() - INTERVAL '4 days'),
  -- Hace 3 dias
  ('Sede Norte', 'Futbolito', 'Cancha 3', CURRENT_DATE - INTERVAL '3 days', '18:00', 60, 'confirmada', 'bot', 'Carlos Ficticio', '+56900000007', '77.777.777-7', 'carlos@ficticio.cl', NULL, NOW() - INTERVAL '3 days'),
  ('Sede Norte', 'Futbolito', 'Cancha 4', CURRENT_DATE - INTERVAL '3 days', '19:00', 60, 'confirmada', 'telefono', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', 'Cumpleanos', NOW() - INTERVAL '3 days'),
  ('Sede Sur', 'Futbolito', 'Cancha 1', CURRENT_DATE - INTERVAL '3 days', '20:00', 60, 'cancelada', 'bot', 'Juan Demo', '+56900000001', '11.111.111-1', 'juan@demo.cl', NULL, NOW() - INTERVAL '3 days'),
  ('Sede Sur', 'Padel', 'Cancha 1', CURRENT_DATE - INTERVAL '3 days', '19:00', 60, 'confirmada', 'easycancha', 'Maria Ejemplo', '+56900000002', '22.222.222-2', 'maria@ejemplo.cl', NULL, NOW() - INTERVAL '3 days'),
  -- Hace 2 dias
  ('Sede Norte', 'Futbolito', 'Cancha 5', CURRENT_DATE - INTERVAL '2 days', '17:00', 60, 'confirmada', 'bot', 'Pedro Prueba', '+56900000003', '33.333.333-3', 'pedro@prueba.cl', NULL, NOW() - INTERVAL '2 days'),
  ('Sede Norte', 'Futbolito', 'Cancha 6', CURRENT_DATE - INTERVAL '2 days', '18:00', 60, 'confirmada', 'easycancha', 'Ana Muestra', '+56900000004', '44.444.444-4', 'ana@muestra.cl', NULL, NOW() - INTERVAL '2 days'),
  ('Sede Sur', 'Futbolito', 'Cancha 2', CURRENT_DATE - INTERVAL '2 days', '21:00', 60, 'pendiente', 'bot', 'Luis Test', '+56900000005', '55.555.555-5', 'luis@test.cl', NULL, NOW() - INTERVAL '2 days'),
  ('Sede Sur', 'Padel', 'Cancha 2', CURRENT_DATE - INTERVAL '2 days', '18:00', 90, 'confirmada', 'bot', 'Sofia Sample', '+56900000006', '66.666.666-6', 'sofia@sample.cl', NULL, NOW() - INTERVAL '2 days'),
  -- Ayer
  ('Sede Norte', 'Futbolito', 'Cancha 1', CURRENT_DATE - INTERVAL '1 day', '18:00', 60, 'confirmada', 'bot', 'Carlos Ficticio', '+56900000007', '77.777.777-7', 'carlos@ficticio.cl', NULL, NOW() - INTERVAL '1 day'),
  ('Sede Norte', 'Futbolito', 'Cancha 2', CURRENT_DATE - INTERVAL '1 day', '19:00', 60, 'confirmada', 'easycancha', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', NULL, NOW() - INTERVAL '1 day'),
  ('Sede Norte', 'Futbolito', 'Cancha 3', CURRENT_DATE - INTERVAL '1 day', '20:00', 60, 'cancelada', 'telefono', 'Juan Demo', '+56900000001', '11.111.111-1', 'juan@demo.cl', NULL, NOW() - INTERVAL '1 day'),
  ('Sede Sur', 'Futbolito', 'Cancha 1', CURRENT_DATE - INTERVAL '1 day', '17:00', 60, 'confirmada', 'bot', 'Maria Ejemplo', '+56900000002', '22.222.222-2', 'maria@ejemplo.cl', NULL, NOW() - INTERVAL '1 day'),
  ('Sede Sur', 'Padel', 'Cancha 3', CURRENT_DATE - INTERVAL '1 day', '19:30', 60, 'pendiente', 'bot', 'Pedro Prueba', '+56900000003', '33.333.333-3', 'pedro@prueba.cl', NULL, NOW() - INTERVAL '1 day'),
  -- Hoy
  ('Sede Norte', 'Futbolito', 'Cancha 1', CURRENT_DATE, '18:00', 60, 'confirmada', 'bot', 'Ana Muestra', '+56900000004', '44.444.444-4', 'ana@muestra.cl', NULL, NOW() - INTERVAL '2 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 2', CURRENT_DATE, '19:00', 60, 'confirmada', 'easycancha', 'Luis Test', '+56900000005', '55.555.555-5', 'luis@test.cl', NULL, NOW() - INTERVAL '3 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 4', CURRENT_DATE, '20:00', 60, 'pendiente', 'bot', 'Sofia Sample', '+56900000006', '66.666.666-6', 'sofia@sample.cl', NULL, NOW() - INTERVAL '1 hour'),
  ('Sede Norte', 'Futbolito', 'Cancha 5', CURRENT_DATE, '21:00', 60, 'pre_reserva', 'bot', 'Carlos Ficticio', '+56900000007', '77.777.777-7', 'carlos@ficticio.cl', NULL, NOW() - INTERVAL '30 minutes'),
  ('Sede Sur', 'Futbolito', 'Cancha 1', CURRENT_DATE, '18:00', 60, 'confirmada', 'bot', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', NULL, NOW() - INTERVAL '4 hours'),
  ('Sede Sur', 'Futbolito', 'Cancha 2', CURRENT_DATE, '19:00', 60, 'confirmada', 'telefono', 'Juan Demo', '+56900000001', '11.111.111-1', 'juan@demo.cl', 'Reserva semanal', NOW() - INTERVAL '5 hours'),
  ('Sede Sur', 'Padel', 'Cancha 1', CURRENT_DATE, '18:30', 90, 'confirmada', 'easycancha', 'Maria Ejemplo', '+56900000002', '22.222.222-2', 'maria@ejemplo.cl', NULL, NOW() - INTERVAL '6 hours'),
  ('Sede Sur', 'Padel', 'Cancha 2', CURRENT_DATE, '20:00', 60, 'pendiente', 'bot', 'Pedro Prueba', '+56900000003', '33.333.333-3', 'pedro@prueba.cl', NULL, NOW() - INTERVAL '1 hour'),
  -- Manana
  ('Sede Norte', 'Futbolito', 'Cancha 1', CURRENT_DATE + INTERVAL '1 day', '18:00', 60, 'confirmada', 'bot', 'Ana Muestra', '+56900000004', '44.444.444-4', 'ana@muestra.cl', NULL, NOW() - INTERVAL '1 hour'),
  ('Sede Norte', 'Futbolito', 'Cancha 3', CURRENT_DATE + INTERVAL '1 day', '19:00', 60, 'pendiente', 'easycancha', 'Luis Test', '+56900000005', '55.555.555-5', 'luis@test.cl', NULL, NOW()),
  ('Sede Norte', 'Futbolito', 'Cancha 6', CURRENT_DATE + INTERVAL '1 day', '20:00', 60, 'pre_reserva', 'bot', 'Sofia Sample', '+56900000006', '66.666.666-6', 'sofia@sample.cl', NULL, NOW()),
  ('Sede Sur', 'Futbolito', 'Cancha 1', CURRENT_DATE + INTERVAL '1 day', '19:00', 60, 'confirmada', 'bot', 'Carlos Ficticio', '+56900000007', '77.777.777-7', 'carlos@ficticio.cl', NULL, NOW()),
  ('Sede Sur', 'Padel', 'Cancha 1', CURRENT_DATE + INTERVAL '1 day', '19:00', 60, 'confirmada', 'dashboard', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', 'Clase padel', NOW()),
  -- Pasado manana y despues
  ('Sede Norte', 'Futbolito', 'Cancha 2', CURRENT_DATE + INTERVAL '2 days', '18:00', 60, 'pendiente', 'bot', 'Juan Demo', '+56900000001', '11.111.111-1', 'juan@demo.cl', NULL, NOW()),
  ('Sede Sur', 'Futbolito', 'Cancha 3', CURRENT_DATE + INTERVAL '2 days', '20:00', 60, 'confirmada', 'easycancha', 'Maria Ejemplo', '+56900000002', '22.222.222-2', 'maria@ejemplo.cl', NULL, NOW()),
  ('Sede Sur', 'Padel', 'Cancha 2', CURRENT_DATE + INTERVAL '3 days', '18:00', 90, 'pendiente', 'bot', 'Pedro Prueba', '+56900000003', '33.333.333-3', 'pedro@prueba.cl', NULL, NOW());

-- =============================================
-- SLOTS (hoy y manana)
-- =============================================
-- Generamos slots usando generate_series

-- Sede Norte - Futbolito (Cancha 1-6, 09:00-23:00)
INSERT INTO slots (centro, tipo_cancha, cancha, fecha, hora, duracion, estado)
SELECT
  'Sede Norte',
  'Futbolito',
  'Cancha ' || c.n,
  d.fecha,
  LPAD(h.hora::TEXT, 2, '0') || ':00',
  60,
  'disponible'
FROM
  generate_series(1, 6) AS c(n),
  (SELECT CURRENT_DATE AS fecha UNION ALL SELECT CURRENT_DATE + 1) AS d,
  generate_series(9, 23) AS h(hora);

-- Sede Sur - Futbolito (Cancha 1-4, 08:00-23:00)
INSERT INTO slots (centro, tipo_cancha, cancha, fecha, hora, duracion, estado)
SELECT
  'Sede Sur',
  'Futbolito',
  'Cancha ' || c.n,
  d.fecha,
  LPAD(h.hora::TEXT, 2, '0') || ':00',
  60,
  'disponible'
FROM
  generate_series(1, 4) AS c(n),
  (SELECT CURRENT_DATE AS fecha UNION ALL SELECT CURRENT_DATE + 1) AS d,
  generate_series(8, 23) AS h(hora);

-- Sede Sur - Padel (Cancha 1-3, 08:30-23:30 cada 30 min)
INSERT INTO slots (centro, tipo_cancha, cancha, fecha, hora, duracion, estado)
SELECT
  'Sede Sur',
  'Padel',
  'Cancha ' || c.n,
  d.fecha,
  LPAD((8 + (h.slot * 30) / 60)::TEXT, 2, '0') || ':' || LPAD(((h.slot * 30) % 60)::TEXT, 2, '0'),
  60,
  'disponible'
FROM
  generate_series(1, 3) AS c(n),
  (SELECT CURRENT_DATE AS fecha UNION ALL SELECT CURRENT_DATE + 1) AS d,
  generate_series(1, 31) AS h(slot);

-- Mark slots as 'reservado' where reservas exist for today and tomorrow
UPDATE slots s
SET
  estado = 'reservado',
  reserva_id = r.id,
  cliente_nombre = r.nombre_cliente,
  cliente_telefono = r.telefono_cliente,
  cliente_rut = r.rut_cliente,
  cliente_email = r.email_cliente,
  updated_at = NOW()
FROM reservas r
WHERE s.centro = r.centro
  AND s.tipo_cancha = r.tipo_cancha
  AND s.cancha = r.cancha
  AND s.fecha = r.fecha
  AND s.hora = r.hora
  AND r.estado IN ('confirmada', 'pendiente', 'pre_reserva')
  AND r.fecha >= CURRENT_DATE
  AND r.fecha <= CURRENT_DATE + 1;

-- Block some slots for maintenance
UPDATE slots
SET estado = 'bloqueado', notas = 'Mantencion cancha'
WHERE centro = 'Sede Norte' AND cancha = 'Cancha 3' AND fecha = CURRENT_DATE AND hora IN ('09:00', '10:00', '11:00');

UPDATE slots
SET estado = 'bloqueado', notas = 'Mantencion cancha'
WHERE centro = 'Sede Sur' AND tipo_cancha = 'Padel' AND cancha = 'Cancha 3' AND fecha = CURRENT_DATE + 1 AND hora IN ('08:30', '09:00', '09:30');

-- =============================================
-- MENSAJES (conversaciones recientes)
-- =============================================

-- Conversacion 1: Juan Demo pregunta disponibilidad
INSERT INTO mensajes_raw (sender_id, canal, mensaje, sender_name, created_at) VALUES
  ('56900000001', 'whatsapp', 'Hola, tienen cancha disponible para hoy en la tarde?', 'Juan Demo', NOW() - INTERVAL '2 days 4 hours'),
  ('56900000001', 'whatsapp', 'Futbolito, somos 10', 'Juan Demo', NOW() - INTERVAL '2 days 3 hours 50 minutes'),
  ('56900000001', 'whatsapp', 'Dale, la de las 19:00 porfa', 'Juan Demo', NOW() - INTERVAL '2 days 3 hours 40 minutes');

INSERT INTO mensajes (sender_id, canal, direccion, contenido, created_at) VALUES
  ('56900000001', 'whatsapp', 'outbound', 'Hola Juan! Bienvenido a Cancha Llena. Tenemos las siguientes canchas disponibles para hoy: Cancha 1 a las 18:00, Cancha 2 a las 19:00, Cancha 4 a las 20:00. Cual prefieres?', NOW() - INTERVAL '2 days 3 hours 55 minutes'),
  ('56900000001', 'whatsapp', 'outbound', 'Listo! Tu reserva quedo confirmada: Sede Sur, Cancha 2 a las 19:00. Te esperamos!', NOW() - INTERVAL '2 days 3 hours 38 minutes');

-- Conversacion 2: Maria Ejemplo confirma reserva
INSERT INTO mensajes_raw (sender_id, canal, mensaje, sender_name, created_at) VALUES
  ('56900000002', 'whatsapp', 'Buenas! Quiero reservar padel para manana', 'Maria Ejemplo', NOW() - INTERVAL '1 day 6 hours'),
  ('56900000002', 'whatsapp', 'A las 19:00 esta bien', 'Maria Ejemplo', NOW() - INTERVAL '1 day 5 hours 50 minutes');

INSERT INTO mensajes (sender_id, canal, direccion, contenido, created_at) VALUES
  ('56900000002', 'whatsapp', 'outbound', 'Hola Maria! Para padel en Sede Sur manana tenemos disponible: Cancha 1 a las 18:30, 19:00 y 20:00. Cancha 2 a las 18:00 y 20:00.', NOW() - INTERVAL '1 day 5 hours 55 minutes'),
  ('56900000002', 'whatsapp', 'outbound', 'Perfecto! Reserva confirmada: Padel Cancha 1, manana a las 19:00. Duracion 60 min. Nos vemos!', NOW() - INTERVAL '1 day 5 hours 48 minutes');

-- Conversacion 3: Pedro pregunta precio
INSERT INTO mensajes_raw (sender_id, canal, mensaje, sender_name, created_at) VALUES
  ('56900000003', 'whatsapp', 'Cuanto sale la hora de futbolito?', 'Pedro Prueba', NOW() - INTERVAL '1 day 2 hours'),
  ('56900000003', 'whatsapp', 'Y padel?', 'Pedro Prueba', NOW() - INTERVAL '1 day 1 hour 50 minutes'),
  ('56900000003', 'whatsapp', 'Ok gracias, voy a reservar padel para el viernes', 'Pedro Prueba', NOW() - INTERVAL '1 day 1 hour 40 minutes');

INSERT INTO mensajes (sender_id, canal, direccion, contenido, created_at) VALUES
  ('56900000003', 'whatsapp', 'outbound', 'Hola Pedro! La hora de futbolito va desde $25.000 en horario dia y $35.000 en horario prime (18:00-23:00).', NOW() - INTERVAL '1 day 1 hour 55 minutes'),
  ('56900000003', 'whatsapp', 'outbound', 'El padel tiene un valor de $18.000 la hora y $24.000 la hora y media. Solo disponible en Sede Sur.', NOW() - INTERVAL '1 day 1 hour 48 minutes');

-- Conversacion 4: Ana solicita hablar con humano
INSERT INTO mensajes_raw (sender_id, canal, mensaje, sender_name, created_at) VALUES
  ('56900000004', 'whatsapp', 'Necesito hablar con alguien por un problema con mi reserva', 'Ana Muestra', NOW() - INTERVAL '5 hours'),
  ('56900000004', 'whatsapp', 'Es que me cobraron doble', 'Ana Muestra', NOW() - INTERVAL '4 hours 50 minutes');

INSERT INTO mensajes (sender_id, canal, direccion, contenido, created_at) VALUES
  ('56900000004', 'whatsapp', 'outbound', 'Entiendo Ana, voy a derivar tu caso a un ejecutivo. En breve te contactaran para resolver el tema del cobro. Disculpa las molestias!', NOW() - INTERVAL '4 hours 48 minutes');

-- Conversacion 5: Sofia consulta horarios
INSERT INTO mensajes_raw (sender_id, canal, mensaje, sender_name, created_at) VALUES
  ('56900000005', 'whatsapp', 'A que hora abren los sabados?', 'Luis Test', NOW() - INTERVAL '3 hours');

INSERT INTO mensajes (sender_id, canal, direccion, contenido, created_at) VALUES
  ('56900000005', 'whatsapp', 'outbound', 'Hola! Los sabados Sede Norte abre a las 09:00 y Sede Sur desde las 08:00. Cerramos a las 24:00 ambas sedes.', NOW() - INTERVAL '2 hours 55 minutes');

-- =============================================
-- ALERTAS
-- =============================================

INSERT INTO alertas (tipo, reserva_id, mensaje, canal, sender_id, leida, resuelta, created_at) VALUES
  -- Alertas de reserva
  ('reserva', 28, 'Nueva reserva creada por bot - Ana Muestra, Sede Norte Cancha 1 hoy 18:00', 'whatsapp', '56900000004', false, false, NOW() - INTERVAL '2 hours'),
  ('reserva', 29, 'Nueva reserva creada via EasyCancha - Luis Test, Sede Norte Cancha 2 hoy 19:00', 'easycancha', '56900000005', false, false, NOW() - INTERVAL '3 hours'),
  ('reserva', 32, 'Nueva reserva creada por bot - Valentina Mock, Sede Sur Cancha 1 hoy 18:00', 'whatsapp', '56900000008', true, true, NOW() - INTERVAL '4 hours'),
  ('reserva', 36, 'Nueva reserva creada por bot - Ana Muestra, Sede Norte Cancha 1 manana 18:00', 'whatsapp', '56900000004', false, false, NOW() - INTERVAL '1 hour'),
  ('reserva', 31, 'Pre-reserva pendiente de confirmacion - Carlos Ficticio, Sede Norte Cancha 5 hoy 21:00', 'whatsapp', '56900000007', false, false, NOW() - INTERVAL '30 minutes'),

  -- Alertas EasyCancha sync
  ('easycancha_sync', NULL, 'Sincronizacion EasyCancha completada - 3 reservas importadas', NULL, NULL, true, true, NOW() - INTERVAL '3 days'),
  ('easycancha_sync', NULL, 'Sincronizacion EasyCancha completada - 5 reservas importadas', NULL, NULL, false, false, NOW() - INTERVAL '1 day'),
  ('easycancha_sync', NULL, 'Sincronizacion EasyCancha completada - 2 reservas importadas', NULL, NULL, false, false, NOW() - INTERVAL '6 hours'),

  -- Alertas de escalamiento
  ('escalamiento', NULL, 'Cliente solicita hablar con humano - Ana Muestra (+56900000004)', 'whatsapp', '56900000004', false, false, NOW() - INTERVAL '5 hours'),
  ('escalamiento', NULL, 'Cliente reporta problema de cobro - Ana Muestra', 'whatsapp', '56900000004', false, false, NOW() - INTERVAL '4 hours 48 minutes'),
  ('escalamiento', NULL, 'Cliente insatisfecho con horarios disponibles - Pedro Prueba', 'whatsapp', '56900000003', true, true, NOW() - INTERVAL '2 days'),
  ('escalamiento', NULL, 'Multiples intentos de reserva fallidos - Sofia Sample', 'whatsapp', '56900000006', true, false, NOW() - INTERVAL '4 days'),

  -- Alertas de error
  ('error', NULL, 'Error al procesar pago via EasyCancha - Timeout de conexion', NULL, NULL, false, false, NOW() - INTERVAL '1 day 3 hours'),
  ('error', NULL, 'Error al enviar confirmacion WhatsApp - API no disponible temporalmente', NULL, NULL, true, true, NOW() - INTERVAL '3 days 2 hours'),

  -- Alerta pago pendiente
  ('pago_pendiente', 30, 'Pago pendiente - Sofia Sample, Sede Norte Cancha 4 hoy 20:00 ($35.000)', 'bot', '56900000006', false, false, NOW() - INTERVAL '1 hour');

-- =============================================
-- SESSIONS
-- =============================================

INSERT INTO sessions (sender_id, estado, last_activity) VALUES
  ('56900000001', 'activo', NOW() - INTERVAL '2 hours'),
  ('56900000002', 'activo', NOW() - INTERVAL '5 hours'),
  ('56900000003', 'activo', NOW() - INTERVAL '1 hour'),
  ('56900000004', 'finalizado', NOW() - INTERVAL '1 day'),
  ('56900000006', 'finalizado', NOW() - INTERVAL '3 days');
