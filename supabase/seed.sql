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

-- Enable Realtime (skip if already added)
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE reservas;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE slots;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE alertas;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- RLS (allow all for authenticated users)
ALTER TABLE reservas ENABLE ROW LEVEL SECURITY;
ALTER TABLE slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE mensajes ENABLE ROW LEVEL SECURITY;
ALTER TABLE mensajes_raw ENABLE ROW LEVEL SECURITY;
ALTER TABLE alertas ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='reservas' AND policyname='auth_all') THEN
    CREATE POLICY "auth_all" ON reservas FOR ALL TO authenticated USING (true) WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='slots' AND policyname='auth_all') THEN
    CREATE POLICY "auth_all" ON slots FOR ALL TO authenticated USING (true) WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='clientes' AND policyname='auth_all') THEN
    CREATE POLICY "auth_all" ON clientes FOR ALL TO authenticated USING (true) WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='mensajes' AND policyname='auth_all') THEN
    CREATE POLICY "auth_all" ON mensajes FOR ALL TO authenticated USING (true) WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='mensajes_raw' AND policyname='auth_all') THEN
    CREATE POLICY "auth_all" ON mensajes_raw FOR ALL TO authenticated USING (true) WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='alertas' AND policyname='auth_all') THEN
    CREATE POLICY "auth_all" ON alertas FOR ALL TO authenticated USING (true) WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='sessions' AND policyname='auth_all') THEN
    CREATE POLICY "auth_all" ON sessions FOR ALL TO authenticated USING (true) WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='reservas' AND policyname='anon_read') THEN
    CREATE POLICY "anon_read" ON reservas FOR SELECT TO anon USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='slots' AND policyname='anon_read') THEN
    CREATE POLICY "anon_read" ON slots FOR SELECT TO anon USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='alertas' AND policyname='anon_read') THEN
    CREATE POLICY "anon_read" ON alertas FOR SELECT TO anon USING (true);
  END IF;
END $$;

-- =============================================
-- CLEAR EXISTING DATA (for re-runs)
-- =============================================
TRUNCATE sessions, alertas, mensajes, mensajes_raw, slots, reservas, clientes RESTART IDENTITY CASCADE;

-- =============================================
-- SEED DATA - MATCH SCREENSHOT METRICS
-- =============================================
-- Reservas periodo 7d: 282 | Cancelaciones: 14 (5%)
-- Ocupacion LP 17+: 48% (140/294) | Ocupacion Q 17+: 22% (108/490)
-- Bot: 11 | EC: 112 | Automatizadas: 123
-- Mensajes periodo: 446 | Alertas: 7

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

-- =============================================
-- RESERVAS PASADAS (offsets 1-6 = 6 dias dentro del rango 7d)
-- Solo canales: easycancha (2/3) y bot (1/3)
-- SN Fut 17-21: 4c × 6d × 5h = 120 (80 EC + 40 Bot)
-- SS Fut 17-21: 2c × 6d × 5h = 60  (40 EC + 20 Bot)
-- SN Fut 10-12: 2c × 6d × 3h = 36  (24 EC + 12 Bot)
-- Total pasadas: 216
-- =============================================

-- Sede Norte Futbolito 17-21 (120 reservas, 2/3 EC + 1/3 Bot)
INSERT INTO reservas (centro, tipo_cancha, cancha, fecha, hora, duracion, estado, canal_origen, nombre_cliente, telefono_cliente, rut_cliente, email_cliente, created_at)
SELECT 'Sede Norte', 'Futbolito', 'Cancha ' || c.n,
  CURRENT_DATE - d.day_offset,
  LPAD(h.hora::TEXT, 2, '0') || ':00', 60, 'completada',
  CASE WHEN (c.n + h.hora + d.day_offset) % 3 = 0 THEN 'bot' ELSE 'easycancha' END,
  (ARRAY['Juan Demo','Maria Ejemplo','Pedro Prueba','Ana Muestra','Luis Test','Sofia Sample','Carlos Ficticio','Valentina Mock'])[((c.n + h.hora + d.day_offset) % 8) + 1],
  (ARRAY['+56900000001','+56900000002','+56900000003','+56900000004','+56900000005','+56900000006','+56900000007','+56900000008'])[((c.n + h.hora + d.day_offset) % 8) + 1],
  (ARRAY['11.111.111-1','22.222.222-2','33.333.333-3','44.444.444-4','55.555.555-5','66.666.666-6','77.777.777-7','88.888.888-8'])[((c.n + h.hora + d.day_offset) % 8) + 1],
  (ARRAY['juan@demo.cl','maria@ejemplo.cl','pedro@prueba.cl','ana@muestra.cl','luis@test.cl','sofia@sample.cl','carlos@ficticio.cl','valentina@mock.cl'])[((c.n + h.hora + d.day_offset) % 8) + 1],
  NOW() - (d.day_offset || ' days')::INTERVAL
FROM generate_series(1, 4) AS c(n),
  generate_series(1, 6) AS d(day_offset),
  generate_series(17, 21) AS h(hora);

-- Sede Sur Futbolito 17-21 (60 reservas, 2/3 EC + 1/3 Bot)
INSERT INTO reservas (centro, tipo_cancha, cancha, fecha, hora, duracion, estado, canal_origen, nombre_cliente, telefono_cliente, rut_cliente, email_cliente, created_at)
SELECT 'Sede Sur', 'Futbolito', 'Cancha ' || c.n,
  CURRENT_DATE - d.day_offset,
  LPAD(h.hora::TEXT, 2, '0') || ':00', 60, 'completada',
  CASE WHEN (c.n + h.hora + d.day_offset) % 3 = 0 THEN 'bot' ELSE 'easycancha' END,
  (ARRAY['Juan Demo','Maria Ejemplo','Pedro Prueba','Ana Muestra','Luis Test','Sofia Sample','Carlos Ficticio','Valentina Mock'])[((c.n + h.hora + d.day_offset + 3) % 8) + 1],
  (ARRAY['+56900000001','+56900000002','+56900000003','+56900000004','+56900000005','+56900000006','+56900000007','+56900000008'])[((c.n + h.hora + d.day_offset + 3) % 8) + 1],
  (ARRAY['11.111.111-1','22.222.222-2','33.333.333-3','44.444.444-4','55.555.555-5','66.666.666-6','77.777.777-7','88.888.888-8'])[((c.n + h.hora + d.day_offset + 3) % 8) + 1],
  (ARRAY['juan@demo.cl','maria@ejemplo.cl','pedro@prueba.cl','ana@muestra.cl','luis@test.cl','sofia@sample.cl','carlos@ficticio.cl','valentina@mock.cl'])[((c.n + h.hora + d.day_offset + 3) % 8) + 1],
  NOW() - (d.day_offset || ' days')::INTERVAL
FROM generate_series(1, 2) AS c(n),
  generate_series(1, 6) AS d(day_offset),
  generate_series(17, 21) AS h(hora);

-- Sede Norte Futbolito hora<17 (36 reservas, 2/3 EC + 1/3 Bot)
INSERT INTO reservas (centro, tipo_cancha, cancha, fecha, hora, duracion, estado, canal_origen, nombre_cliente, telefono_cliente, rut_cliente, email_cliente, created_at)
SELECT 'Sede Norte', 'Futbolito', 'Cancha ' || c.n,
  CURRENT_DATE - d.day_offset,
  LPAD(h.hora::TEXT, 2, '0') || ':00', 60, 'completada',
  CASE WHEN (c.n + h.hora + d.day_offset) % 3 = 0 THEN 'bot' ELSE 'easycancha' END,
  (ARRAY['Juan Demo','Maria Ejemplo','Pedro Prueba','Ana Muestra','Luis Test','Sofia Sample','Carlos Ficticio','Valentina Mock'])[((c.n + h.hora + d.day_offset + 2) % 8) + 1],
  (ARRAY['+56900000001','+56900000002','+56900000003','+56900000004','+56900000005','+56900000006','+56900000007','+56900000008'])[((c.n + h.hora + d.day_offset + 2) % 8) + 1],
  (ARRAY['11.111.111-1','22.222.222-2','33.333.333-3','44.444.444-4','55.555.555-5','66.666.666-6','77.777.777-7','88.888.888-8'])[((c.n + h.hora + d.day_offset + 2) % 8) + 1],
  (ARRAY['juan@demo.cl','maria@ejemplo.cl','pedro@prueba.cl','ana@muestra.cl','luis@test.cl','sofia@sample.cl','carlos@ficticio.cl','valentina@mock.cl'])[((c.n + h.hora + d.day_offset + 2) % 8) + 1],
  NOW() - (d.day_offset || ' days')::INTERVAL
FROM generate_series(1, 2) AS c(n),
  generate_series(1, 6) AS d(day_offset),
  generate_series(10, 12) AS h(hora);

-- =============================================
-- CANCELACIONES: 14 exactas (5% de 282)
-- 8 SN hora>=17, 4 SS hora>=17, 2 SN hora<17
-- =============================================
UPDATE reservas SET estado = 'cancelada' WHERE estado = 'completada'
  AND centro = 'Sede Norte' AND cancha = 'Cancha 1' AND hora = '17:00' AND fecha = CURRENT_DATE - 1;
UPDATE reservas SET estado = 'cancelada' WHERE estado = 'completada'
  AND centro = 'Sede Norte' AND cancha = 'Cancha 2' AND hora = '18:00' AND fecha = CURRENT_DATE - 2;
UPDATE reservas SET estado = 'cancelada' WHERE estado = 'completada'
  AND centro = 'Sede Norte' AND cancha = 'Cancha 3' AND hora = '19:00' AND fecha = CURRENT_DATE - 3;
UPDATE reservas SET estado = 'cancelada' WHERE estado = 'completada'
  AND centro = 'Sede Norte' AND cancha = 'Cancha 4' AND hora = '20:00' AND fecha = CURRENT_DATE - 4;
UPDATE reservas SET estado = 'cancelada' WHERE estado = 'completada'
  AND centro = 'Sede Norte' AND cancha = 'Cancha 1' AND hora = '21:00' AND fecha = CURRENT_DATE - 5;
UPDATE reservas SET estado = 'cancelada' WHERE estado = 'completada'
  AND centro = 'Sede Norte' AND cancha = 'Cancha 2' AND hora = '17:00' AND fecha = CURRENT_DATE - 6;
UPDATE reservas SET estado = 'cancelada' WHERE estado = 'completada'
  AND centro = 'Sede Norte' AND cancha = 'Cancha 3' AND hora = '18:00' AND fecha = CURRENT_DATE - 3;
UPDATE reservas SET estado = 'cancelada' WHERE estado = 'completada'
  AND centro = 'Sede Norte' AND cancha = 'Cancha 4' AND hora = '19:00' AND fecha = CURRENT_DATE - 5;
UPDATE reservas SET estado = 'cancelada' WHERE estado = 'completada'
  AND centro = 'Sede Sur' AND cancha = 'Cancha 1' AND hora = '17:00' AND fecha = CURRENT_DATE - 1;
UPDATE reservas SET estado = 'cancelada' WHERE estado = 'completada'
  AND centro = 'Sede Sur' AND cancha = 'Cancha 2' AND hora = '18:00' AND fecha = CURRENT_DATE - 2;
UPDATE reservas SET estado = 'cancelada' WHERE estado = 'completada'
  AND centro = 'Sede Sur' AND cancha = 'Cancha 1' AND hora = '19:00' AND fecha = CURRENT_DATE - 4;
UPDATE reservas SET estado = 'cancelada' WHERE estado = 'completada'
  AND centro = 'Sede Sur' AND cancha = 'Cancha 2' AND hora = '20:00' AND fecha = CURRENT_DATE - 5;
UPDATE reservas SET estado = 'cancelada' WHERE estado = 'completada'
  AND centro = 'Sede Norte' AND cancha = 'Cancha 1' AND hora = '10:00' AND fecha = CURRENT_DATE - 2;
UPDATE reservas SET estado = 'cancelada' WHERE estado = 'completada'
  AND centro = 'Sede Norte' AND cancha = 'Cancha 2' AND hora = '11:00' AND fecha = CURRENT_DATE - 4;

-- =============================================
-- RESERVAS HOY (64 reservas manuales)
-- SN hora>=17: 28 | SS Fut hora>=17: 12 | SS Padel hora>=17: 19 | SS hora<17: 5
-- Canal today: ec=48, bot=16
-- Total 7d: 216 pasadas + 64 hoy = 280 (192 EC + 88 Bot)
-- =============================================
INSERT INTO reservas (centro, tipo_cancha, cancha, fecha, hora, duracion, estado, canal_origen, nombre_cliente, telefono_cliente, rut_cliente, email_cliente, notas, created_at) VALUES
  -- ============ HOY - Sede Norte hora>=17 (28 reservas: 19 EC + 9 Bot) ============
  -- 17:00 (5/6)
  ('Sede Norte', 'Futbolito', 'Cancha 1', CURRENT_DATE, '17:00', 60, 'confirmada', 'easycancha', 'Sofia Sample', '+56900000006', '66.666.666-6', 'sofia@sample.cl', NULL, NOW() - INTERVAL '8 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 2', CURRENT_DATE, '17:00', 60, 'confirmada', 'easycancha', 'Carlos Ficticio', '+56900000007', '77.777.777-7', 'carlos@ficticio.cl', NULL, NOW() - INTERVAL '8 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 3', CURRENT_DATE, '17:00', 60, 'confirmada', 'easycancha', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', NULL, NOW() - INTERVAL '7 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 4', CURRENT_DATE, '17:00', 60, 'confirmada', 'bot', 'Juan Demo', '+56900000001', '11.111.111-1', 'juan@demo.cl', NULL, NOW() - INTERVAL '7 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 5', CURRENT_DATE, '17:00', 60, 'confirmada', 'easycancha', 'Maria Ejemplo', '+56900000002', '22.222.222-2', 'maria@ejemplo.cl', NULL, NOW() - INTERVAL '7 hours'),
  -- 18:00 (5/6)
  ('Sede Norte', 'Futbolito', 'Cancha 1', CURRENT_DATE, '18:00', 60, 'confirmada', 'easycancha', 'Carlos Ficticio', '+56900000007', '77.777.777-7', 'carlos@ficticio.cl', NULL, NOW() - INTERVAL '6 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 2', CURRENT_DATE, '18:00', 60, 'confirmada', 'easycancha', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', NULL, NOW() - INTERVAL '6 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 3', CURRENT_DATE, '18:00', 60, 'confirmada', 'bot', 'Pedro Prueba', '+56900000003', '33.333.333-3', 'pedro@prueba.cl', NULL, NOW() - INTERVAL '6 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 4', CURRENT_DATE, '18:00', 60, 'confirmada', 'easycancha', 'Ana Muestra', '+56900000004', '44.444.444-4', 'ana@muestra.cl', NULL, NOW() - INTERVAL '5 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 5', CURRENT_DATE, '18:00', 60, 'confirmada', 'bot', 'Luis Test', '+56900000005', '55.555.555-5', 'luis@test.cl', NULL, NOW() - INTERVAL '5 hours'),
  -- 19:00 (5/6)
  ('Sede Norte', 'Futbolito', 'Cancha 1', CURRENT_DATE, '19:00', 60, 'confirmada', 'easycancha', 'Juan Demo', '+56900000001', '11.111.111-1', 'juan@demo.cl', NULL, NOW() - INTERVAL '4 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 2', CURRENT_DATE, '19:00', 60, 'confirmada', 'easycancha', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', NULL, NOW() - INTERVAL '4 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 3', CURRENT_DATE, '19:00', 60, 'confirmada', 'bot', 'Pedro Prueba', '+56900000003', '33.333.333-3', 'pedro@prueba.cl', NULL, NOW() - INTERVAL '4 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 4', CURRENT_DATE, '19:00', 60, 'confirmada', 'easycancha', 'Maria Ejemplo', '+56900000002', '22.222.222-2', 'maria@ejemplo.cl', NULL, NOW() - INTERVAL '3 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 5', CURRENT_DATE, '19:00', 60, 'confirmada', 'easycancha', 'Ana Muestra', '+56900000004', '44.444.444-4', 'ana@muestra.cl', NULL, NOW() - INTERVAL '3 hours'),
  -- 20:00 (5/6)
  ('Sede Norte', 'Futbolito', 'Cancha 1', CURRENT_DATE, '20:00', 60, 'confirmada', 'easycancha', 'Sofia Sample', '+56900000006', '66.666.666-6', 'sofia@sample.cl', NULL, NOW() - INTERVAL '3 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 2', CURRENT_DATE, '20:00', 60, 'confirmada', 'easycancha', 'Carlos Ficticio', '+56900000007', '77.777.777-7', 'carlos@ficticio.cl', NULL, NOW() - INTERVAL '2 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 3', CURRENT_DATE, '20:00', 60, 'confirmada', 'bot', 'Juan Demo', '+56900000001', '11.111.111-1', 'juan@demo.cl', NULL, NOW() - INTERVAL '2 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 4', CURRENT_DATE, '20:00', 60, 'confirmada', 'easycancha', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', NULL, NOW() - INTERVAL '2 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 5', CURRENT_DATE, '20:00', 60, 'pendiente', 'bot', 'Ana Muestra', '+56900000004', '44.444.444-4', 'ana@muestra.cl', NULL, NOW() - INTERVAL '1 hour'),
  -- 21:00 (5/6)
  ('Sede Norte', 'Futbolito', 'Cancha 1', CURRENT_DATE, '21:00', 60, 'confirmada', 'easycancha', 'Maria Ejemplo', '+56900000002', '22.222.222-2', 'maria@ejemplo.cl', NULL, NOW() - INTERVAL '2 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 2', CURRENT_DATE, '21:00', 60, 'confirmada', 'easycancha', 'Luis Test', '+56900000005', '55.555.555-5', 'luis@test.cl', 'Liga nocturna', NOW() - INTERVAL '2 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 3', CURRENT_DATE, '21:00', 60, 'pre_reserva', 'bot', 'Sofia Sample', '+56900000006', '66.666.666-6', 'sofia@sample.cl', NULL, NOW() - INTERVAL '30 minutes'),
  ('Sede Norte', 'Futbolito', 'Cancha 4', CURRENT_DATE, '21:00', 60, 'confirmada', 'easycancha', 'Carlos Ficticio', '+56900000007', '77.777.777-7', 'carlos@ficticio.cl', NULL, NOW() - INTERVAL '1 hour'),
  ('Sede Norte', 'Futbolito', 'Cancha 5', CURRENT_DATE, '21:00', 60, 'confirmada', 'bot', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', NULL, NOW() - INTERVAL '1 hour'),
  -- 22:00 (3/6)
  ('Sede Norte', 'Futbolito', 'Cancha 1', CURRENT_DATE, '22:00', 60, 'confirmada', 'easycancha', 'Juan Demo', '+56900000001', '11.111.111-1', 'juan@demo.cl', NULL, NOW() - INTERVAL '1 hour'),
  ('Sede Norte', 'Futbolito', 'Cancha 2', CURRENT_DATE, '22:00', 60, 'pendiente', 'bot', 'Pedro Prueba', '+56900000003', '33.333.333-3', 'pedro@prueba.cl', NULL, NOW() - INTERVAL '30 minutes'),
  ('Sede Norte', 'Futbolito', 'Cancha 3', CURRENT_DATE, '22:00', 60, 'confirmada', 'easycancha', 'Ana Muestra', '+56900000004', '44.444.444-4', 'ana@muestra.cl', NULL, NOW() - INTERVAL '30 minutes'),

  -- ============ HOY - Sede Sur Futbolito hora>=17 (12 reservas: 9 EC + 3 Bot) ============
  -- 17:00 (3/4)
  ('Sede Sur', 'Futbolito', 'Cancha 1', CURRENT_DATE, '17:00', 60, 'confirmada', 'easycancha', 'Carlos Ficticio', '+56900000007', '77.777.777-7', 'carlos@ficticio.cl', NULL, NOW() - INTERVAL '7 hours'),
  ('Sede Sur', 'Futbolito', 'Cancha 2', CURRENT_DATE, '17:00', 60, 'confirmada', 'easycancha', 'Sofia Sample', '+56900000006', '66.666.666-6', 'sofia@sample.cl', NULL, NOW() - INTERVAL '7 hours'),
  ('Sede Sur', 'Futbolito', 'Cancha 3', CURRENT_DATE, '17:00', 60, 'confirmada', 'bot', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', NULL, NOW() - INTERVAL '6 hours'),
  -- 18:00 (3/4)
  ('Sede Sur', 'Futbolito', 'Cancha 1', CURRENT_DATE, '18:00', 60, 'confirmada', 'easycancha', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', NULL, NOW() - INTERVAL '6 hours'),
  ('Sede Sur', 'Futbolito', 'Cancha 2', CURRENT_DATE, '18:00', 60, 'confirmada', 'easycancha', 'Juan Demo', '+56900000001', '11.111.111-1', 'juan@demo.cl', NULL, NOW() - INTERVAL '5 hours'),
  ('Sede Sur', 'Futbolito', 'Cancha 3', CURRENT_DATE, '18:00', 60, 'confirmada', 'bot', 'Maria Ejemplo', '+56900000002', '22.222.222-2', 'maria@ejemplo.cl', NULL, NOW() - INTERVAL '5 hours'),
  -- 19:00 (3/4)
  ('Sede Sur', 'Futbolito', 'Cancha 1', CURRENT_DATE, '19:00', 60, 'confirmada', 'easycancha', 'Ana Muestra', '+56900000004', '44.444.444-4', 'ana@muestra.cl', NULL, NOW() - INTERVAL '4 hours'),
  ('Sede Sur', 'Futbolito', 'Cancha 2', CURRENT_DATE, '19:00', 60, 'confirmada', 'easycancha', 'Luis Test', '+56900000005', '55.555.555-5', 'luis@test.cl', 'Reserva semanal', NOW() - INTERVAL '4 hours'),
  ('Sede Sur', 'Futbolito', 'Cancha 3', CURRENT_DATE, '19:00', 60, 'confirmada', 'easycancha', 'Carlos Ficticio', '+56900000007', '77.777.777-7', 'carlos@ficticio.cl', NULL, NOW() - INTERVAL '3 hours'),
  -- 20:00 (3/4)
  ('Sede Sur', 'Futbolito', 'Cancha 1', CURRENT_DATE, '20:00', 60, 'confirmada', 'easycancha', 'Pedro Prueba', '+56900000003', '33.333.333-3', 'pedro@prueba.cl', NULL, NOW() - INTERVAL '3 hours'),
  ('Sede Sur', 'Futbolito', 'Cancha 2', CURRENT_DATE, '20:00', 60, 'confirmada', 'easycancha', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', NULL, NOW() - INTERVAL '2 hours'),
  ('Sede Sur', 'Futbolito', 'Cancha 3', CURRENT_DATE, '20:00', 60, 'confirmada', 'bot', 'Juan Demo', '+56900000001', '11.111.111-1', 'juan@demo.cl', NULL, NOW() - INTERVAL '1 hour'),

  -- ============ HOY - Sede Sur Padel hora>=17 (19 reservas: 16 EC + 3 Bot) ============
  ('Sede Sur', 'Padel', 'Cancha 1', CURRENT_DATE, '17:00', 60, 'confirmada', 'easycancha', 'Pedro Prueba', '+56900000003', '33.333.333-3', 'pedro@prueba.cl', NULL, NOW() - INTERVAL '7 hours'),
  ('Sede Sur', 'Padel', 'Cancha 2', CURRENT_DATE, '17:00', 60, 'confirmada', 'easycancha', 'Ana Muestra', '+56900000004', '44.444.444-4', 'ana@muestra.cl', NULL, NOW() - INTERVAL '7 hours'),
  ('Sede Sur', 'Padel', 'Cancha 3', CURRENT_DATE, '17:00', 60, 'confirmada', 'easycancha', 'Luis Test', '+56900000005', '55.555.555-5', 'luis@test.cl', NULL, NOW() - INTERVAL '6 hours'),
  ('Sede Sur', 'Padel', 'Cancha 1', CURRENT_DATE, '17:30', 60, 'confirmada', 'easycancha', 'Sofia Sample', '+56900000006', '66.666.666-6', 'sofia@sample.cl', NULL, NOW() - INTERVAL '6 hours'),
  ('Sede Sur', 'Padel', 'Cancha 2', CURRENT_DATE, '17:30', 60, 'confirmada', 'bot', 'Carlos Ficticio', '+56900000007', '77.777.777-7', 'carlos@ficticio.cl', NULL, NOW() - INTERVAL '6 hours'),
  ('Sede Sur', 'Padel', 'Cancha 1', CURRENT_DATE, '18:00', 60, 'confirmada', 'easycancha', 'Ana Muestra', '+56900000004', '44.444.444-4', 'ana@muestra.cl', NULL, NOW() - INTERVAL '6 hours'),
  ('Sede Sur', 'Padel', 'Cancha 2', CURRENT_DATE, '18:00', 60, 'confirmada', 'easycancha', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', NULL, NOW() - INTERVAL '5 hours'),
  ('Sede Sur', 'Padel', 'Cancha 1', CURRENT_DATE, '18:30', 60, 'confirmada', 'easycancha', 'Juan Demo', '+56900000001', '11.111.111-1', 'juan@demo.cl', NULL, NOW() - INTERVAL '5 hours'),
  ('Sede Sur', 'Padel', 'Cancha 2', CURRENT_DATE, '18:30', 60, 'confirmada', 'easycancha', 'Pedro Prueba', '+56900000003', '33.333.333-3', 'pedro@prueba.cl', NULL, NOW() - INTERVAL '5 hours'),
  ('Sede Sur', 'Padel', 'Cancha 1', CURRENT_DATE, '19:00', 60, 'confirmada', 'easycancha', 'Luis Test', '+56900000005', '55.555.555-5', 'luis@test.cl', NULL, NOW() - INTERVAL '4 hours'),
  ('Sede Sur', 'Padel', 'Cancha 2', CURRENT_DATE, '19:00', 60, 'confirmada', 'bot', 'Carlos Ficticio', '+56900000007', '77.777.777-7', 'carlos@ficticio.cl', NULL, NOW() - INTERVAL '3 hours'),
  ('Sede Sur', 'Padel', 'Cancha 3', CURRENT_DATE, '19:00', 60, 'confirmada', 'easycancha', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', NULL, NOW() - INTERVAL '3 hours'),
  ('Sede Sur', 'Padel', 'Cancha 1', CURRENT_DATE, '19:30', 60, 'confirmada', 'easycancha', 'Maria Ejemplo', '+56900000002', '22.222.222-2', 'maria@ejemplo.cl', NULL, NOW() - INTERVAL '3 hours'),
  ('Sede Sur', 'Padel', 'Cancha 1', CURRENT_DATE, '20:00', 60, 'confirmada', 'easycancha', 'Sofia Sample', '+56900000006', '66.666.666-6', 'sofia@sample.cl', NULL, NOW() - INTERVAL '2 hours'),
  ('Sede Sur', 'Padel', 'Cancha 2', CURRENT_DATE, '20:00', 60, 'confirmada', 'easycancha', 'Juan Demo', '+56900000001', '11.111.111-1', 'juan@demo.cl', NULL, NOW() - INTERVAL '2 hours'),
  ('Sede Sur', 'Padel', 'Cancha 1', CURRENT_DATE, '20:30', 60, 'confirmada', 'bot', 'Carlos Ficticio', '+56900000007', '77.777.777-7', 'carlos@ficticio.cl', NULL, NOW() - INTERVAL '2 hours'),
  ('Sede Sur', 'Padel', 'Cancha 2', CURRENT_DATE, '20:30', 60, 'confirmada', 'easycancha', 'Luis Test', '+56900000005', '55.555.555-5', 'luis@test.cl', NULL, NOW() - INTERVAL '1 hour'),
  ('Sede Sur', 'Padel', 'Cancha 1', CURRENT_DATE, '21:00', 60, 'confirmada', 'easycancha', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', NULL, NOW() - INTERVAL '1 hour'),
  ('Sede Sur', 'Padel', 'Cancha 2', CURRENT_DATE, '21:00', 60, 'confirmada', 'easycancha', 'Maria Ejemplo', '+56900000002', '22.222.222-2', 'maria@ejemplo.cl', NULL, NOW() - INTERVAL '1 hour'),

  -- ============ HOY - Sede Sur hora<17 (5 reservas: 4 EC + 1 Bot) ============
  ('Sede Sur', 'Padel', 'Cancha 1', CURRENT_DATE, '09:00', 60, 'completada', 'easycancha', 'Pedro Prueba', '+56900000003', '33.333.333-3', 'pedro@prueba.cl', NULL, NOW() - INTERVAL '10 hours'),
  ('Sede Sur', 'Padel', 'Cancha 2', CURRENT_DATE, '09:00', 60, 'completada', 'easycancha', 'Ana Muestra', '+56900000004', '44.444.444-4', 'ana@muestra.cl', NULL, NOW() - INTERVAL '10 hours'),
  ('Sede Sur', 'Padel', 'Cancha 1', CURRENT_DATE, '10:00', 60, 'completada', 'bot', 'Luis Test', '+56900000005', '55.555.555-5', 'luis@test.cl', NULL, NOW() - INTERVAL '9 hours'),
  ('Sede Sur', 'Futbolito', 'Cancha 1', CURRENT_DATE, '10:00', 60, 'completada', 'easycancha', 'Sofia Sample', '+56900000006', '66.666.666-6', 'sofia@sample.cl', NULL, NOW() - INTERVAL '9 hours'),
  ('Sede Sur', 'Futbolito', 'Cancha 2', CURRENT_DATE, '11:00', 60, 'completada', 'easycancha', 'Carlos Ficticio', '+56900000007', '77.777.777-7', 'carlos@ficticio.cl', NULL, NOW() - INTERVAL '8 hours');

-- =============================================
-- RESERVAS FUTURO (fuera del rango 7d, no afectan metricas)
-- =============================================
INSERT INTO reservas (centro, tipo_cancha, cancha, fecha, hora, duracion, estado, canal_origen, nombre_cliente, telefono_cliente, rut_cliente, email_cliente, notas, created_at) VALUES
  ('Sede Norte', 'Futbolito', 'Cancha 1', CURRENT_DATE + 1, '18:00', 60, 'confirmada', 'easycancha', 'Carlos Ficticio', '+56900000007', '77.777.777-7', 'carlos@ficticio.cl', NULL, NOW() - INTERVAL '2 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 2', CURRENT_DATE + 1, '19:00', 60, 'confirmada', 'easycancha', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', NULL, NOW() - INTERVAL '1 hour'),
  ('Sede Norte', 'Futbolito', 'Cancha 3', CURRENT_DATE + 1, '19:00', 60, 'pendiente', 'bot', 'Juan Demo', '+56900000001', '11.111.111-1', 'juan@demo.cl', NULL, NOW()),
  ('Sede Norte', 'Futbolito', 'Cancha 4', CURRENT_DATE + 1, '20:00', 60, 'confirmada', 'easycancha', 'Maria Ejemplo', '+56900000002', '22.222.222-2', 'maria@ejemplo.cl', NULL, NOW()),
  ('Sede Sur', 'Futbolito', 'Cancha 1', CURRENT_DATE + 1, '18:00', 60, 'confirmada', 'easycancha', 'Ana Muestra', '+56900000004', '44.444.444-4', 'ana@muestra.cl', NULL, NOW()),
  ('Sede Sur', 'Padel', 'Cancha 1', CURRENT_DATE + 1, '19:00', 60, 'confirmada', 'bot', 'Sofia Sample', '+56900000006', '66.666.666-6', 'sofia@sample.cl', 'Clase padel', NOW()),
  ('Sede Norte', 'Futbolito', 'Cancha 1', CURRENT_DATE + 2, '18:00', 60, 'confirmada', 'easycancha', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', NULL, NOW()),
  ('Sede Sur', 'Padel', 'Cancha 1', CURRENT_DATE + 3, '18:00', 60, 'pendiente', 'easycancha', 'Pedro Prueba', '+56900000003', '33.333.333-3', 'pedro@prueba.cl', NULL, NOW());

-- =============================================
-- SLOTS (hoy y manana)
-- =============================================

-- Sede Norte - Futbolito (Cancha 1-6, 09:00-23:00)
INSERT INTO slots (centro, tipo_cancha, cancha, fecha, hora, duracion, estado)
SELECT 'Sede Norte', 'Futbolito', 'Cancha ' || c.n, d.fecha,
  LPAD(h.hora::TEXT, 2, '0') || ':00', 60, 'disponible'
FROM generate_series(1, 6) AS c(n),
  (SELECT CURRENT_DATE AS fecha UNION ALL SELECT CURRENT_DATE + 1) AS d,
  generate_series(9, 23) AS h(hora);

-- Sede Sur - Futbolito (Cancha 1-4, 08:00-23:00)
INSERT INTO slots (centro, tipo_cancha, cancha, fecha, hora, duracion, estado)
SELECT 'Sede Sur', 'Futbolito', 'Cancha ' || c.n, d.fecha,
  LPAD(h.hora::TEXT, 2, '0') || ':00', 60, 'disponible'
FROM generate_series(1, 4) AS c(n),
  (SELECT CURRENT_DATE AS fecha UNION ALL SELECT CURRENT_DATE + 1) AS d,
  generate_series(8, 23) AS h(hora);

-- Sede Sur - Padel (Cancha 1-3, 08:30-23:30 cada 30 min)
INSERT INTO slots (centro, tipo_cancha, cancha, fecha, hora, duracion, estado)
SELECT 'Sede Sur', 'Padel', 'Cancha ' || c.n, d.fecha,
  LPAD((8 + (h.slot * 30) / 60)::TEXT, 2, '0') || ':' || LPAD(((h.slot * 30) % 60)::TEXT, 2, '0'),
  60, 'disponible'
FROM generate_series(1, 3) AS c(n),
  (SELECT CURRENT_DATE AS fecha UNION ALL SELECT CURRENT_DATE + 1) AS d,
  generate_series(1, 31) AS h(slot);

-- Mark slots as 'reservado' where reservas exist for today and tomorrow
UPDATE slots s SET
  estado = 'reservado', reserva_id = r.id,
  cliente_nombre = r.nombre_cliente, cliente_telefono = r.telefono_cliente,
  cliente_rut = r.rut_cliente, cliente_email = r.email_cliente, updated_at = NOW()
FROM reservas r
WHERE s.centro = r.centro AND s.tipo_cancha = r.tipo_cancha AND s.cancha = r.cancha
  AND s.fecha = r.fecha AND s.hora = r.hora
  AND r.estado IN ('confirmada', 'pendiente', 'pre_reserva')
  AND r.fecha >= CURRENT_DATE AND r.fecha <= CURRENT_DATE + 1;

-- Block some slots for maintenance
UPDATE slots SET estado = 'bloqueado', notas = 'Mantencion cancha'
WHERE centro = 'Sede Norte' AND cancha = 'Cancha 3' AND fecha = CURRENT_DATE AND hora IN ('09:00', '10:00');

UPDATE slots SET estado = 'bloqueado', notas = 'Mantencion cancha'
WHERE centro = 'Sede Sur' AND tipo_cancha = 'Padel' AND cancha = 'Cancha 3'
  AND fecha = CURRENT_DATE + 1 AND hora IN ('08:30', '09:00');

-- =============================================
-- MENSAJES BULK (130 bulk + 34 conversaciones = 164 total)
-- 6 dias × 19 + 1 dia × 16 = 130
-- =============================================
INSERT INTO mensajes (sender_id, canal, direccion, contenido, created_at)
SELECT
  '5690000000' || ((m.msg_n % 8) + 1),
  'whatsapp',
  CASE WHEN m.msg_n % 3 = 0 THEN 'inbound' ELSE 'outbound' END,
  CASE m.msg_n % 6
    WHEN 0 THEN 'Hola, quiero reservar una cancha'
    WHEN 1 THEN '¡Hola! 😊 ¿En qué puedo ayudarte hoy?'
    WHEN 2 THEN 'Futbolito para mañana 21 horas tendrá cancha?'
    WHEN 3 THEN 'Para mañana hay disponibilidad de canchas de futbolito a las 21:00 en ambas sedes:\n\n**Sede Norte:**\n- Cancha 4: 21:00\n- Cancha 5: 21:00\n\n**Sede Sur:**\n- Cancha 2: 21:00\n- Cancha 3: 21:00'
    WHEN 4 THEN 'La cancha 4 porfavor'
    ELSE '¡Tu reserva ha sido creada con éxito! 🎉 Tienes 30 minutos para realizar el abono del 50%.'
  END,
  NOW() - (d.day_offset || ' days')::INTERVAL + ((m.msg_n * 12) || ' minutes')::INTERVAL
FROM generate_series(0, 6) AS d(day_offset),
  generate_series(1, 19) AS m(msg_n)
WHERE NOT (d.day_offset = 0 AND m.msg_n > 16);

-- =============================================
-- CONVERSACIONES REALISTAS (flujo completo del bot con pago)
-- Replican el flujo real: saludo → disponibilidad ambas sedes →
-- selección → datos personales → resumen + instrucciones de pago
-- =============================================

-- CONV 1: Juan Demo - Flujo completo tipo screenshot (hace 2 dias)
-- Futbolito Sede Norte, Cancha 4, 21:00
INSERT INTO mensajes_raw (sender_id, canal, mensaje, sender_name, created_at) VALUES
  ('56900000001', 'whatsapp', 'Hola buenas', 'Juan Demo', NOW() - INTERVAL '2 days 5 hours'),
  ('56900000001', 'whatsapp', 'Para día martes mañana 21 horas tendrá cancha?', 'Juan Demo', NOW() - INTERVAL '2 days 4 hours 57 minutes'),
  ('56900000001', 'whatsapp', 'La cancha 4 porfavor', 'Juan Demo', NOW() - INTERVAL '2 days 4 hours 52 minutes'),
  ('56900000001', 'whatsapp', 'A nombre de Juan Demo\n11.111.111-1\njuandemo@gmail.com\n900000001', 'Juan Demo', NOW() - INTERVAL '2 days 4 hours 47 minutes'),
  ('56900000001', 'whatsapp', 'Cuánto sería el monto?', 'Juan Demo', NOW() - INTERVAL '2 days 4 hours 38 minutes'),
  ('56900000001', 'whatsapp', 'Ya genial, altiro transfiero', 'Juan Demo', NOW() - INTERVAL '2 days 4 hours 33 minutes'),
  ('56900000001', 'whatsapp', 'Sería para sede norte', 'Juan Demo', NOW() - INTERVAL '2 days 4 hours 28 minutes');

INSERT INTO mensajes (sender_id, canal, direccion, contenido, created_at) VALUES
  ('56900000001', 'whatsapp', 'outbound', '¡Hola! 😊 ¿En qué puedo ayudarte hoy?', NOW() - INTERVAL '2 days 4 hours 59 minutes'),
  ('56900000001', 'whatsapp', 'outbound', 'Para mañana, martes 10 de marzo, hay disponibilidad de canchas de futbolito a las 21:00 en ambas sedes:\n\n**Sede Norte:**\n- Cancha 4: 21:00\n- Cancha 5: 21:00\n\n**Sede Sur:**\n- Cancha 2: 21:00\n- Cancha 3: 21:00\n- Cancha 4: 21:00\n\n¿Te gustaría reservar alguna de estas canchas? 😊', NOW() - INTERVAL '2 days 4 hours 55 minutes'),
  ('56900000001', 'whatsapp', 'outbound', 'Perfecto, has elegido la cancha 4.\n\nAntes de proceder, necesito confirmar algunos datos:\n\n1. ¿A nombre de quién reservo?\n2. Por favor, indícame tu RUT y email.\n3. ¿Cuál es tu número de teléfono?\n\nCon esta información, puedo completar la reserva para mañana a las 21:00. 😊', NOW() - INTERVAL '2 days 4 hours 50 minutes'),
  ('56900000001', 'whatsapp', 'outbound', '¡Tu reserva ha sido creada con éxito! 🎉\n\n**Detalles de la reserva:**\n- **Centro:** Sede Norte\n- **Tipo de cancha:** Futbolito\n- **Cancha:** 4\n- **Fecha:** 10 de marzo de 2026\n- **Hora:** 21:00\n- **Cliente:** Juan Demo (RUT: 11.111.111-1)\n\n⚠️ Para confirmar tu reserva debes abonar el 50% del valor total, envía el comprobante de transferencia al WhatsApp de Secretaría: +56 9 1234 5678\n\n💳 **Datos de transferencia:**\n- Cancha Llena SpA\n- RUT: 76.123.456-7\n- Banco Santander\n- Cuenta Corriente: 0-000-1234567-8\n- Email: pagos@canchallena.demo\n\nTienes 30 minutos para realizar el abono del 50%. Tu reserva queda en estado *Pendiente* hasta recibir el comprobante. Si no se confirma el pago, la cancha será liberada.\n\nSi necesitas algo más, ¡no dudes en decírmelo! 😊', NOW() - INTERVAL '2 days 4 hours 44 minutes'),
  ('56900000001', 'whatsapp', 'outbound', 'El precio para reservar la cancha 4 en Sede Norte a las 21:00 es de **$41.500** por hora.\n\nPor lo tanto, el 50% del valor total sería **$20.750**.\n\nSi tienes alguna otra pregunta o necesitas más ayuda, ¡aquí estoy! 😊', NOW() - INTERVAL '2 days 4 hours 36 minutes'),
  ('56900000001', 'whatsapp', 'outbound', '¡Perfecto! 😊 Una vez que realices la transferencia, por favor envía el comprobante de transferencia al WhatsApp de Secretaría al +56 9 1234 5678 para confirmar tu reserva.\n\nRecuerda que tienes 30 minutos para realizar el abono. Si necesitas ayuda con algo más, no dudes en decírmelo. ¡Gracias! ⚽', NOW() - INTERVAL '2 days 4 hours 31 minutes'),
  ('56900000001', 'whatsapp', 'outbound', 'Correcto, tu reserva es para la cancha 4 en **Sede Norte**.\n\nUna vez que envíes el comprobante de transferencia al WhatsApp de Secretaría, tu reserva quedará confirmada.\n\nSi necesitas información o ayuda, ¡aquí estoy! 😊⚽', NOW() - INTERVAL '2 days 4 hours 26 minutes');

-- CONV 2: Maria Ejemplo - Padel con consulta de precios y pago (hace 1 dia)
INSERT INTO mensajes_raw (sender_id, canal, mensaje, sender_name, created_at) VALUES
  ('56900000002', 'whatsapp', 'Buenas! Cuanto sale la hora de padel?', 'Maria Ejemplo', NOW() - INTERVAL '1 day 6 hours'),
  ('56900000002', 'whatsapp', 'Y la hora y media?', 'Maria Ejemplo', NOW() - INTERVAL '1 day 5 hours 55 minutes'),
  ('56900000002', 'whatsapp', 'Ok quiero reservar para mañana una hora', 'Maria Ejemplo', NOW() - INTERVAL '1 day 5 hours 50 minutes'),
  ('56900000002', 'whatsapp', 'A las 19:00', 'Maria Ejemplo', NOW() - INTERVAL '1 day 5 hours 45 minutes'),
  ('56900000002', 'whatsapp', 'A nombre de Maria Ejemplo\n22.222.222-2\nmaria@gmail.com\n900000002', 'Maria Ejemplo', NOW() - INTERVAL '1 day 5 hours 40 minutes'),
  ('56900000002', 'whatsapp', 'Perfecto, ahora transfiero', 'Maria Ejemplo', NOW() - INTERVAL '1 day 5 hours 32 minutes'),
  ('56900000002', 'whatsapp', 'Gracias! Nos vemos mañana', 'Maria Ejemplo', NOW() - INTERVAL '1 day 5 hours 28 minutes');

INSERT INTO mensajes (sender_id, canal, direccion, contenido, created_at) VALUES
  ('56900000002', 'whatsapp', 'outbound', '¡Hola! 😊 ¿En qué puedo ayudarte hoy?', NOW() - INTERVAL '1 day 5 hours 59 minutes'),
  ('56900000002', 'whatsapp', 'outbound', '¡Hola Maria! La hora de padel tiene los siguientes valores:\n\n- **60 min:** $18.000\n- **90 min:** $24.000\n\nEl padel está disponible solo en **Sede Sur**. ¿Te gustaría reservar? 😊', NOW() - INTERVAL '1 day 5 hours 57 minutes'),
  ('56900000002', 'whatsapp', 'outbound', 'La hora y media (90 min) sale **$24.000**. Es ideal para partidos más largos! 🎾', NOW() - INTERVAL '1 day 5 hours 53 minutes'),
  ('56900000002', 'whatsapp', 'outbound', 'Para mañana tenemos disponible en Padel (Sede Sur):\n\n- Cancha 1: 18:00, 19:00, 20:00\n- Cancha 2: 19:00, 20:00\n- Cancha 3: 18:30, 20:00\n\n¿Qué horario prefieres? 😊', NOW() - INTERVAL '1 day 5 hours 48 minutes'),
  ('56900000002', 'whatsapp', 'outbound', 'Perfecto, necesito confirmar algunos datos:\n\n1. Nombre completo\n2. RUT y email\n3. Teléfono de contacto\n\nCon eso completamos la reserva de Cancha 1 de Padel a las 19:00 😊', NOW() - INTERVAL '1 day 5 hours 43 minutes'),
  ('56900000002', 'whatsapp', 'outbound', '¡Tu reserva ha sido creada con éxito! 🎉\n\n**Detalles de la reserva:**\n- **Centro:** Sede Sur\n- **Tipo de cancha:** Padel\n- **Cancha:** 1\n- **Fecha:** 11 de marzo de 2026\n- **Hora:** 19:00\n- **Cliente:** Maria Ejemplo (RUT: 22.222.222-2)\n\n⚠️ Para confirmar tu reserva debes abonar el 50% del valor total ($9.000), envía el comprobante de transferencia al WhatsApp de Secretaría: +56 9 1234 5678\n\n💳 **Datos de transferencia:**\n- Cancha Llena SpA\n- RUT: 76.123.456-7\n- Banco Santander\n- Cuenta Corriente: 0-000-1234567-8\n- Email: pagos@canchallena.demo\n\nTienes 30 minutos para realizar el abono. Tu reserva queda en estado *Pendiente* hasta recibir el comprobante. 🎾', NOW() - INTERVAL '1 day 5 hours 37 minutes'),
  ('56900000002', 'whatsapp', 'outbound', '¡Genial! 😊 Recuerda enviar el comprobante al WhatsApp de Secretaría (+56 9 1234 5678) para que tu reserva quede confirmada.\n\n¡Nos vemos mañana! 🎾', NOW() - INTERVAL '1 day 5 hours 30 minutes');

-- CONV 3: Pedro Prueba - Cliente recurrente, flujo rápido (hoy)
INSERT INTO mensajes_raw (sender_id, canal, mensaje, sender_name, created_at) VALUES
  ('56900000003', 'whatsapp', 'Hola, la misma de siempre porfa. Futbolito Sede Norte 20:00', 'Pedro Prueba', NOW() - INTERVAL '3 hours'),
  ('56900000003', 'whatsapp', 'Para hoy', 'Pedro Prueba', NOW() - INTERVAL '2 hours 55 minutes'),
  ('56900000003', 'whatsapp', 'Dale, Cancha 5 está bien', 'Pedro Prueba', NOW() - INTERVAL '2 hours 50 minutes'),
  ('56900000003', 'whatsapp', 'Ya transfiero altiro', 'Pedro Prueba', NOW() - INTERVAL '2 hours 42 minutes');

INSERT INTO mensajes (sender_id, canal, direccion, contenido, created_at) VALUES
  ('56900000003', 'whatsapp', 'outbound', '¡Hola Pedro! 😊 Te tengo registrado. ¿Para qué día necesitas la cancha?', NOW() - INTERVAL '2 hours 58 minutes'),
  ('56900000003', 'whatsapp', 'outbound', 'Para hoy en Sede Norte a las 20:00 tenemos disponible:\n\n- Cancha 5: 20:00\n- Cancha 6: 20:00\n\n¿Cuál prefieres? 😊', NOW() - INTERVAL '2 hours 53 minutes'),
  ('56900000003', 'whatsapp', 'outbound', '¡Tu reserva ha sido creada con éxito! 🎉\n\n**Detalles de la reserva:**\n- **Centro:** Sede Norte\n- **Tipo de cancha:** Futbolito\n- **Cancha:** 5\n- **Fecha:** Hoy\n- **Hora:** 20:00\n- **Cliente:** Pedro Prueba (RUT: 33.333.333-3)\n\n⚠️ Para confirmar debes abonar el 50% ($20.750). Envía el comprobante al WhatsApp de Secretaría: +56 9 1234 5678\n\n💳 Cancha Llena SpA - RUT: 76.123.456-7 - Banco Santander - Cta Cte: 0-000-1234567-8\n\nTienes 30 minutos. ¡Como siempre, te esperamos! ⚽', NOW() - INTERVAL '2 hours 48 minutes'),
  ('56900000003', 'whatsapp', 'outbound', '¡Perfecto Pedro! 😊 Envía el comprobante al +56 9 1234 5678 y quedas confirmado. ¡Buen partido! ⚽', NOW() - INTERVAL '2 hours 40 minutes');

-- CONV 4: Ana Muestra - Padel 90 min con precio (hoy)
INSERT INTO mensajes_raw (sender_id, canal, mensaje, sender_name, created_at) VALUES
  ('56900000004', 'whatsapp', 'Hola! Tienen padel disponible para hoy?', 'Ana Muestra', NOW() - INTERVAL '6 hours'),
  ('56900000004', 'whatsapp', 'A las 18:00 porfa, hora y media', 'Ana Muestra', NOW() - INTERVAL '5 hours 55 minutes'),
  ('56900000004', 'whatsapp', 'A nombre de Ana Muestra\n44.444.444-4\nana.muestra@gmail.com\n900000004', 'Ana Muestra', NOW() - INTERVAL '5 hours 50 minutes'),
  ('56900000004', 'whatsapp', 'Cuanto sería el 50%?', 'Ana Muestra', NOW() - INTERVAL '5 hours 42 minutes'),
  ('56900000004', 'whatsapp', 'Genial, ahí transfiero. Gracias!', 'Ana Muestra', NOW() - INTERVAL '5 hours 38 minutes');

INSERT INTO mensajes (sender_id, canal, direccion, contenido, created_at) VALUES
  ('56900000004', 'whatsapp', 'outbound', '¡Hola Ana! 😊 Sí, para hoy en Padel (Sede Sur) tenemos:\n\n- Cancha 1: 18:00, 20:00\n- Cancha 2: 19:00\n- Cancha 3: 20:00\n\n¿Qué horario te acomoda?', NOW() - INTERVAL '5 hours 58 minutes'),
  ('56900000004', 'whatsapp', 'outbound', 'Cancha 1 a las 18:00 por 90 min (**$24.000**).\n\nPara completar la reserva necesito:\n1. Nombre completo\n2. RUT y email\n3. Teléfono\n\n😊', NOW() - INTERVAL '5 hours 53 minutes'),
  ('56900000004', 'whatsapp', 'outbound', '¡Tu reserva ha sido creada con éxito! 🎉\n\n**Detalles de la reserva:**\n- **Centro:** Sede Sur\n- **Tipo de cancha:** Padel\n- **Cancha:** 1\n- **Fecha:** Hoy\n- **Hora:** 18:00\n- **Duración:** 90 min\n- **Cliente:** Ana Muestra (RUT: 44.444.444-4)\n\n⚠️ Para confirmar tu reserva debes abonar el 50% del valor total, envía el comprobante de transferencia al WhatsApp de Secretaría: +56 9 1234 5678\n\n💳 **Datos de transferencia:**\n- Cancha Llena SpA\n- RUT: 76.123.456-7\n- Banco Santander\n- Cuenta Corriente: 0-000-1234567-8\n- Email: pagos@canchallena.demo\n\nTienes 30 minutos para realizar el abono. ¡Que la pasen bien! 🎾', NOW() - INTERVAL '5 hours 48 minutes'),
  ('56900000004', 'whatsapp', 'outbound', 'El valor total es **$24.000** (90 min), por lo tanto el 50% sería **$12.000**.\n\nRecuerda enviar el comprobante al WhatsApp de Secretaría: +56 9 1234 5678 😊', NOW() - INTERVAL '5 hours 44 minutes'),
  ('56900000004', 'whatsapp', 'outbound', '¡Genial Ana! 😊 Una vez que envíes el comprobante, tu reserva quedará confirmada. ¡Disfruten el partido! 🎾', NOW() - INTERVAL '5 hours 36 minutes');

-- CONV 5: Carlos Ficticio - Reserva futbolito mañana Sede Norte (hoy)
INSERT INTO mensajes_raw (sender_id, canal, mensaje, sender_name, created_at) VALUES
  ('56900000007', 'whatsapp', 'Buenas noches', 'Carlos Ficticio', NOW() - INTERVAL '2 hours'),
  ('56900000007', 'whatsapp', 'Quiero reservar futbolito para mañana a las 18:00', 'Carlos Ficticio', NOW() - INTERVAL '1 hour 57 minutes'),
  ('56900000007', 'whatsapp', 'Cancha 1 de Sede Norte porfa', 'Carlos Ficticio', NOW() - INTERVAL '1 hour 50 minutes'),
  ('56900000007', 'whatsapp', 'Carlos Ficticio\n77.777.777-7\ncficticio@gmail.com\n900000007', 'Carlos Ficticio', NOW() - INTERVAL '1 hour 45 minutes'),
  ('56900000007', 'whatsapp', 'Listo, transfiero ahora. Gracias, buena onda el bot jaja', 'Carlos Ficticio', NOW() - INTERVAL '1 hour 37 minutes');

INSERT INTO mensajes (sender_id, canal, direccion, contenido, created_at) VALUES
  ('56900000007', 'whatsapp', 'outbound', '¡Hola! 😊 ¿En qué puedo ayudarte hoy?', NOW() - INTERVAL '1 hour 59 minutes'),
  ('56900000007', 'whatsapp', 'outbound', 'Para mañana a las 18:00 hay disponibilidad de canchas de futbolito en ambas sedes:\n\n**Sede Norte:**\n- Cancha 1: 18:00\n- Cancha 2: 18:00\n- Cancha 4: 18:00\n- Cancha 6: 18:00\n\n**Sede Sur:**\n- Cancha 1: 18:00\n- Cancha 2: 18:00\n- Cancha 3: 18:00\n\n¿Te gustaría reservar alguna de estas canchas? 😊', NOW() - INTERVAL '1 hour 55 minutes'),
  ('56900000007', 'whatsapp', 'outbound', 'Perfecto, has elegido Cancha 1 en Sede Norte.\n\nAntes de proceder, necesito confirmar algunos datos:\n\n1. ¿A nombre de quién reservo?\n2. Por favor, indícame tu RUT y email.\n3. ¿Cuál es tu número de teléfono?\n\n😊', NOW() - INTERVAL '1 hour 48 minutes'),
  ('56900000007', 'whatsapp', 'outbound', '¡Tu reserva ha sido creada con éxito! 🎉\n\n**Detalles de la reserva:**\n- **Centro:** Sede Norte\n- **Tipo de cancha:** Futbolito\n- **Cancha:** 1\n- **Fecha:** Mañana\n- **Hora:** 18:00\n- **Cliente:** Carlos Ficticio (RUT: 77.777.777-7)\n\n⚠️ Para confirmar tu reserva debes abonar el 50% del valor total ($20.750), envía el comprobante de transferencia al WhatsApp de Secretaría: +56 9 1234 5678\n\n💳 **Datos de transferencia:**\n- Cancha Llena SpA\n- RUT: 76.123.456-7\n- Banco Santander\n- Cuenta Corriente: 0-000-1234567-8\n- Email: pagos@canchallena.demo\n\nTienes 30 minutos para realizar el abono del 50%. Tu reserva queda en estado *Pendiente* hasta recibir el comprobante. ⚽', NOW() - INTERVAL '1 hour 43 minutes'),
  ('56900000007', 'whatsapp', 'outbound', '¡Jaja gracias Carlos! 😄 Una vez que realices la transferencia, envía el comprobante al +56 9 1234 5678 para confirmar. ¡Nos vemos mañana! ⚽', NOW() - INTERVAL '1 hour 35 minutes');

-- CONV 6: Luis Test - Consulta fin de semana Sede Sur (hoy)
INSERT INTO mensajes_raw (sender_id, canal, mensaje, sender_name, created_at) VALUES
  ('56900000005', 'whatsapp', 'Hola, tienen disponibilidad para este fin de semana?', 'Luis Test', NOW() - INTERVAL '4 hours'),
  ('56900000005', 'whatsapp', 'Futbolito en Sede Sur', 'Luis Test', NOW() - INTERVAL '3 hours 55 minutes'),
  ('56900000005', 'whatsapp', 'Sábado a las 19:00 si hay, Cancha 2', 'Luis Test', NOW() - INTERVAL '3 hours 48 minutes'),
  ('56900000005', 'whatsapp', 'Luis Test\n55.555.555-5\nluistest@gmail.com\n900000005', 'Luis Test', NOW() - INTERVAL '3 hours 43 minutes'),
  ('56900000005', 'whatsapp', 'Dale, transfiero ahora', 'Luis Test', NOW() - INTERVAL '3 hours 35 minutes'),
  ('56900000005', 'whatsapp', 'Excelente, quedamos así!', 'Luis Test', NOW() - INTERVAL '3 hours 30 minutes');

INSERT INTO mensajes (sender_id, canal, direccion, contenido, created_at) VALUES
  ('56900000005', 'whatsapp', 'outbound', '¡Hola! 😊 ¿En qué puedo ayudarte hoy?', NOW() - INTERVAL '3 hours 59 minutes'),
  ('56900000005', 'whatsapp', 'outbound', '¡Hola Luis! Para este fin de semana en Sede Sur, Futbolito tenemos buena disponibilidad:\n\n**Sábado:**\n- Cancha 1: 17:00, 18:00, 19:00, 20:00\n- Cancha 2: 17:00, 18:00, 19:00, 20:00\n- Cancha 3: 18:00, 19:00, 20:00\n\n**Domingo:**\n- Todas las canchas disponibles de 09:00 a 23:00\n\n¿Qué día y hora prefieres? 😊', NOW() - INTERVAL '3 hours 52 minutes'),
  ('56900000005', 'whatsapp', 'outbound', 'Cancha 2 el sábado a las 19:00.\n\nPara completar la reserva necesito:\n1. Nombre completo\n2. RUT y email\n3. Teléfono\n\n😊', NOW() - INTERVAL '3 hours 46 minutes'),
  ('56900000005', 'whatsapp', 'outbound', '¡Tu reserva ha sido creada con éxito! 🎉\n\n**Detalles de la reserva:**\n- **Centro:** Sede Sur\n- **Tipo de cancha:** Futbolito\n- **Cancha:** 2\n- **Fecha:** Sábado\n- **Hora:** 19:00\n- **Cliente:** Luis Test (RUT: 55.555.555-5)\n\n⚠️ Para confirmar tu reserva debes abonar el 50% del valor total, envía el comprobante de transferencia al WhatsApp de Secretaría: +56 9 1234 5678\n\n💳 **Datos de transferencia:**\n- Cancha Llena SpA\n- RUT: 76.123.456-7\n- Banco Santander\n- Cuenta Corriente: 0-000-1234567-8\n- Email: pagos@canchallena.demo\n\nTienes 30 minutos para realizar el abono del 50%. ¡Buen partido! ⚽', NOW() - INTERVAL '3 hours 41 minutes'),
  ('56900000005', 'whatsapp', 'outbound', '¡Perfecto Luis! 😊 Envía el comprobante al WhatsApp de Secretaría (+56 9 1234 5678) y quedas confirmado.\n\nRecuerda que tienes 30 minutos para realizar el abono. ⚽', NOW() - INTERVAL '3 hours 37 minutes'),
  ('56900000005', 'whatsapp', 'outbound', '¡Genial! Nos vemos el sábado. ¡Buen partido! ⚽😊', NOW() - INTERVAL '3 hours 28 minutes');

-- =============================================
-- ALERTAS: exactamente 7
-- =============================================
INSERT INTO alertas (tipo, reserva_id, mensaje, canal, sender_id, leida, resuelta, created_at) VALUES
  ('reserva', NULL, 'Nueva reserva por EasyCancha - Sofia Sample, Sede Norte Cancha 1 hoy 17:00', 'easycancha', '56900000006', true, true, NOW() - INTERVAL '8 hours'),
  ('reserva', NULL, 'Nueva reserva por EasyCancha - Carlos Ficticio, Sede Norte Cancha 2 hoy 17:00', 'easycancha', '56900000007', true, true, NOW() - INTERVAL '8 hours'),
  ('reserva', NULL, 'Nueva reserva por EasyCancha - Juan Demo, Sede Norte Cancha 1 hoy 19:00', 'easycancha', '56900000001', true, true, NOW() - INTERVAL '4 hours'),
  ('reserva', NULL, 'Nueva reserva pendiente - Ana Muestra, Sede Norte Cancha 5 hoy 20:00', 'whatsapp', '56900000004', false, false, NOW() - INTERVAL '1 hour'),
  ('reserva', NULL, 'Pre-reserva pendiente - Sofia Sample, Sede Norte Cancha 3 hoy 21:00', 'whatsapp', '56900000006', false, false, NOW() - INTERVAL '30 minutes'),
  ('easycancha_sync', NULL, 'Sincronizacion EasyCancha completada - 9 reservas importadas', NULL, NULL, false, false, NOW() - INTERVAL '4 hours'),
  ('error', NULL, 'Error temporal API WhatsApp - Reconexion automatica exitosa', NULL, NULL, true, true, NOW() - INTERVAL '5 days');

-- =============================================
-- SESSIONS
-- =============================================
INSERT INTO sessions (sender_id, estado, last_activity) VALUES
  ('56900000001', 'activo', NOW() - INTERVAL '2 hours'),
  ('56900000002', 'activo', NOW() - INTERVAL '5 hours'),
  ('56900000003', 'activo', NOW() - INTERVAL '3 hours'),
  ('56900000004', 'activo', NOW() - INTERVAL '6 hours'),
  ('56900000005', 'activo', NOW() - INTERVAL '4 hours'),
  ('56900000007', 'activo', NOW() - INTERVAL '2 hours'),
  ('56900000006', 'finalizado', NOW() - INTERVAL '1 day'),
  ('56900000008', 'finalizado', NOW() - INTERVAL '2 days');
