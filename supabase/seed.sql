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
-- SEED DATA - NEGOCIO EXITOSO
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

-- =============================================
-- ~90 RESERVAS - Alta ocupacion, pocas cancelaciones
-- Distribucion: 80% confirmada/completada, 12% pendiente, 5% cancelada, 3% pre_reserva
-- =============================================
INSERT INTO reservas (centro, tipo_cancha, cancha, fecha, hora, duracion, estado, canal_origen, nombre_cliente, telefono_cliente, rut_cliente, email_cliente, notas, created_at) VALUES
  -- ============ HACE 7 DIAS (dia fuerte) ============
  ('Sede Norte', 'Futbolito', 'Cancha 1', CURRENT_DATE - 7, '17:00', 60, 'completada', 'bot', 'Juan Demo', '+56900000001', '11.111.111-1', 'juan@demo.cl', NULL, NOW() - INTERVAL '7 days'),
  ('Sede Norte', 'Futbolito', 'Cancha 1', CURRENT_DATE - 7, '18:00', 60, 'completada', 'bot', 'Maria Ejemplo', '+56900000002', '22.222.222-2', 'maria@ejemplo.cl', NULL, NOW() - INTERVAL '7 days'),
  ('Sede Norte', 'Futbolito', 'Cancha 2', CURRENT_DATE - 7, '18:00', 60, 'completada', 'easycancha', 'Pedro Prueba', '+56900000003', '33.333.333-3', 'pedro@prueba.cl', NULL, NOW() - INTERVAL '7 days'),
  ('Sede Norte', 'Futbolito', 'Cancha 3', CURRENT_DATE - 7, '19:00', 60, 'completada', 'bot', 'Ana Muestra', '+56900000004', '44.444.444-4', 'ana@muestra.cl', NULL, NOW() - INTERVAL '7 days'),
  ('Sede Norte', 'Futbolito', 'Cancha 4', CURRENT_DATE - 7, '19:00', 60, 'completada', 'easycancha', 'Luis Test', '+56900000005', '55.555.555-5', 'luis@test.cl', NULL, NOW() - INTERVAL '7 days'),
  ('Sede Norte', 'Futbolito', 'Cancha 5', CURRENT_DATE - 7, '20:00', 60, 'completada', 'bot', 'Sofia Sample', '+56900000006', '66.666.666-6', 'sofia@sample.cl', NULL, NOW() - INTERVAL '7 days'),
  ('Sede Norte', 'Futbolito', 'Cancha 6', CURRENT_DATE - 7, '20:00', 60, 'completada', 'telefono', 'Carlos Ficticio', '+56900000007', '77.777.777-7', 'carlos@ficticio.cl', NULL, NOW() - INTERVAL '7 days'),
  ('Sede Norte', 'Futbolito', 'Cancha 2', CURRENT_DATE - 7, '21:00', 60, 'completada', 'bot', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', 'Torneo empresas', NOW() - INTERVAL '7 days'),
  ('Sede Sur', 'Futbolito', 'Cancha 1', CURRENT_DATE - 7, '18:00', 60, 'completada', 'bot', 'Juan Demo', '+56900000001', '11.111.111-1', 'juan@demo.cl', NULL, NOW() - INTERVAL '7 days'),
  ('Sede Sur', 'Futbolito', 'Cancha 2', CURRENT_DATE - 7, '19:00', 60, 'completada', 'easycancha', 'Maria Ejemplo', '+56900000002', '22.222.222-2', 'maria@ejemplo.cl', NULL, NOW() - INTERVAL '7 days'),
  ('Sede Sur', 'Futbolito', 'Cancha 3', CURRENT_DATE - 7, '20:00', 60, 'completada', 'bot', 'Pedro Prueba', '+56900000003', '33.333.333-3', 'pedro@prueba.cl', NULL, NOW() - INTERVAL '7 days'),
  ('Sede Sur', 'Padel', 'Cancha 1', CURRENT_DATE - 7, '18:30', 90, 'completada', 'easycancha', 'Ana Muestra', '+56900000004', '44.444.444-4', 'ana@muestra.cl', 'Clase padel', NOW() - INTERVAL '7 days'),
  ('Sede Sur', 'Padel', 'Cancha 2', CURRENT_DATE - 7, '19:00', 60, 'completada', 'bot', 'Luis Test', '+56900000005', '55.555.555-5', 'luis@test.cl', NULL, NOW() - INTERVAL '7 days'),

  -- ============ HACE 6 DIAS ============
  ('Sede Norte', 'Futbolito', 'Cancha 1', CURRENT_DATE - 6, '17:00', 60, 'completada', 'bot', 'Sofia Sample', '+56900000006', '66.666.666-6', 'sofia@sample.cl', NULL, NOW() - INTERVAL '6 days'),
  ('Sede Norte', 'Futbolito', 'Cancha 2', CURRENT_DATE - 6, '18:00', 60, 'completada', 'easycancha', 'Carlos Ficticio', '+56900000007', '77.777.777-7', 'carlos@ficticio.cl', NULL, NOW() - INTERVAL '6 days'),
  ('Sede Norte', 'Futbolito', 'Cancha 3', CURRENT_DATE - 6, '18:00', 60, 'completada', 'bot', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', NULL, NOW() - INTERVAL '6 days'),
  ('Sede Norte', 'Futbolito', 'Cancha 4', CURRENT_DATE - 6, '19:00', 60, 'completada', 'bot', 'Juan Demo', '+56900000001', '11.111.111-1', 'juan@demo.cl', 'Reserva semanal', NOW() - INTERVAL '6 days'),
  ('Sede Norte', 'Futbolito', 'Cancha 5', CURRENT_DATE - 6, '20:00', 60, 'completada', 'telefono', 'Maria Ejemplo', '+56900000002', '22.222.222-2', 'maria@ejemplo.cl', NULL, NOW() - INTERVAL '6 days'),
  ('Sede Norte', 'Futbolito', 'Cancha 1', CURRENT_DATE - 6, '21:00', 60, 'cancelada', 'bot', 'Pedro Prueba', '+56900000003', '33.333.333-3', 'pedro@prueba.cl', NULL, NOW() - INTERVAL '6 days'),
  ('Sede Sur', 'Futbolito', 'Cancha 1', CURRENT_DATE - 6, '18:00', 60, 'completada', 'bot', 'Ana Muestra', '+56900000004', '44.444.444-4', 'ana@muestra.cl', NULL, NOW() - INTERVAL '6 days'),
  ('Sede Sur', 'Futbolito', 'Cancha 2', CURRENT_DATE - 6, '19:00', 60, 'completada', 'easycancha', 'Luis Test', '+56900000005', '55.555.555-5', 'luis@test.cl', NULL, NOW() - INTERVAL '6 days'),
  ('Sede Sur', 'Futbolito', 'Cancha 3', CURRENT_DATE - 6, '20:00', 60, 'completada', 'bot', 'Sofia Sample', '+56900000006', '66.666.666-6', 'sofia@sample.cl', NULL, NOW() - INTERVAL '6 days'),
  ('Sede Sur', 'Padel', 'Cancha 1', CURRENT_DATE - 6, '19:00', 60, 'completada', 'bot', 'Carlos Ficticio', '+56900000007', '77.777.777-7', 'carlos@ficticio.cl', NULL, NOW() - INTERVAL '6 days'),
  ('Sede Sur', 'Padel', 'Cancha 2', CURRENT_DATE - 6, '20:00', 90, 'completada', 'easycancha', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', NULL, NOW() - INTERVAL '6 days'),

  -- ============ HACE 5 DIAS ============
  ('Sede Norte', 'Futbolito', 'Cancha 1', CURRENT_DATE - 5, '18:00', 60, 'completada', 'bot', 'Juan Demo', '+56900000001', '11.111.111-1', 'juan@demo.cl', NULL, NOW() - INTERVAL '5 days'),
  ('Sede Norte', 'Futbolito', 'Cancha 2', CURRENT_DATE - 5, '18:00', 60, 'completada', 'easycancha', 'Maria Ejemplo', '+56900000002', '22.222.222-2', 'maria@ejemplo.cl', NULL, NOW() - INTERVAL '5 days'),
  ('Sede Norte', 'Futbolito', 'Cancha 3', CURRENT_DATE - 5, '19:00', 60, 'completada', 'bot', 'Pedro Prueba', '+56900000003', '33.333.333-3', 'pedro@prueba.cl', NULL, NOW() - INTERVAL '5 days'),
  ('Sede Norte', 'Futbolito', 'Cancha 4', CURRENT_DATE - 5, '19:00', 60, 'completada', 'dashboard', 'Ana Muestra', '+56900000004', '44.444.444-4', 'ana@muestra.cl', 'Cumpleanos', NOW() - INTERVAL '5 days'),
  ('Sede Norte', 'Futbolito', 'Cancha 5', CURRENT_DATE - 5, '20:00', 60, 'completada', 'bot', 'Luis Test', '+56900000005', '55.555.555-5', 'luis@test.cl', NULL, NOW() - INTERVAL '5 days'),
  ('Sede Norte', 'Futbolito', 'Cancha 6', CURRENT_DATE - 5, '21:00', 60, 'completada', 'bot', 'Sofia Sample', '+56900000006', '66.666.666-6', 'sofia@sample.cl', NULL, NOW() - INTERVAL '5 days'),
  ('Sede Sur', 'Futbolito', 'Cancha 1', CURRENT_DATE - 5, '17:00', 60, 'completada', 'bot', 'Carlos Ficticio', '+56900000007', '77.777.777-7', 'carlos@ficticio.cl', NULL, NOW() - INTERVAL '5 days'),
  ('Sede Sur', 'Futbolito', 'Cancha 2', CURRENT_DATE - 5, '18:00', 60, 'completada', 'easycancha', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', NULL, NOW() - INTERVAL '5 days'),
  ('Sede Sur', 'Futbolito', 'Cancha 3', CURRENT_DATE - 5, '19:00', 60, 'completada', 'bot', 'Juan Demo', '+56900000001', '11.111.111-1', 'juan@demo.cl', NULL, NOW() - INTERVAL '5 days'),
  ('Sede Sur', 'Padel', 'Cancha 1', CURRENT_DATE - 5, '18:00', 90, 'completada', 'easycancha', 'Maria Ejemplo', '+56900000002', '22.222.222-2', 'maria@ejemplo.cl', NULL, NOW() - INTERVAL '5 days'),
  ('Sede Sur', 'Padel', 'Cancha 2', CURRENT_DATE - 5, '19:30', 60, 'completada', 'bot', 'Pedro Prueba', '+56900000003', '33.333.333-3', 'pedro@prueba.cl', NULL, NOW() - INTERVAL '5 days'),
  ('Sede Sur', 'Padel', 'Cancha 3', CURRENT_DATE - 5, '20:00', 60, 'completada', 'bot', 'Ana Muestra', '+56900000004', '44.444.444-4', 'ana@muestra.cl', NULL, NOW() - INTERVAL '5 days'),

  -- ============ HACE 4 DIAS ============
  ('Sede Norte', 'Futbolito', 'Cancha 1', CURRENT_DATE - 4, '17:00', 60, 'completada', 'bot', 'Luis Test', '+56900000005', '55.555.555-5', 'luis@test.cl', NULL, NOW() - INTERVAL '4 days'),
  ('Sede Norte', 'Futbolito', 'Cancha 2', CURRENT_DATE - 4, '18:00', 60, 'completada', 'bot', 'Sofia Sample', '+56900000006', '66.666.666-6', 'sofia@sample.cl', NULL, NOW() - INTERVAL '4 days'),
  ('Sede Norte', 'Futbolito', 'Cancha 3', CURRENT_DATE - 4, '19:00', 60, 'completada', 'easycancha', 'Carlos Ficticio', '+56900000007', '77.777.777-7', 'carlos@ficticio.cl', NULL, NOW() - INTERVAL '4 days'),
  ('Sede Norte', 'Futbolito', 'Cancha 4', CURRENT_DATE - 4, '20:00', 60, 'completada', 'bot', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', NULL, NOW() - INTERVAL '4 days'),
  ('Sede Norte', 'Futbolito', 'Cancha 5', CURRENT_DATE - 4, '20:00', 60, 'completada', 'telefono', 'Juan Demo', '+56900000001', '11.111.111-1', 'juan@demo.cl', 'Liga nocturna', NOW() - INTERVAL '4 days'),
  ('Sede Norte', 'Futbolito', 'Cancha 6', CURRENT_DATE - 4, '21:00', 60, 'completada', 'bot', 'Maria Ejemplo', '+56900000002', '22.222.222-2', 'maria@ejemplo.cl', NULL, NOW() - INTERVAL '4 days'),
  ('Sede Sur', 'Futbolito', 'Cancha 1', CURRENT_DATE - 4, '18:00', 60, 'completada', 'bot', 'Pedro Prueba', '+56900000003', '33.333.333-3', 'pedro@prueba.cl', NULL, NOW() - INTERVAL '4 days'),
  ('Sede Sur', 'Futbolito', 'Cancha 2', CURRENT_DATE - 4, '19:00', 60, 'completada', 'easycancha', 'Ana Muestra', '+56900000004', '44.444.444-4', 'ana@muestra.cl', NULL, NOW() - INTERVAL '4 days'),
  ('Sede Sur', 'Futbolito', 'Cancha 3', CURRENT_DATE - 4, '20:00', 60, 'cancelada', 'bot', 'Luis Test', '+56900000005', '55.555.555-5', 'luis@test.cl', NULL, NOW() - INTERVAL '4 days'),
  ('Sede Sur', 'Padel', 'Cancha 1', CURRENT_DATE - 4, '18:30', 90, 'completada', 'easycancha', 'Sofia Sample', '+56900000006', '66.666.666-6', 'sofia@sample.cl', 'Clase grupal', NOW() - INTERVAL '4 days'),
  ('Sede Sur', 'Padel', 'Cancha 2', CURRENT_DATE - 4, '19:00', 60, 'completada', 'bot', 'Carlos Ficticio', '+56900000007', '77.777.777-7', 'carlos@ficticio.cl', NULL, NOW() - INTERVAL '4 days'),

  -- ============ HACE 3 DIAS ============
  ('Sede Norte', 'Futbolito', 'Cancha 1', CURRENT_DATE - 3, '17:00', 60, 'completada', 'bot', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', NULL, NOW() - INTERVAL '3 days'),
  ('Sede Norte', 'Futbolito', 'Cancha 2', CURRENT_DATE - 3, '18:00', 60, 'completada', 'easycancha', 'Juan Demo', '+56900000001', '11.111.111-1', 'juan@demo.cl', NULL, NOW() - INTERVAL '3 days'),
  ('Sede Norte', 'Futbolito', 'Cancha 3', CURRENT_DATE - 3, '18:00', 60, 'completada', 'bot', 'Maria Ejemplo', '+56900000002', '22.222.222-2', 'maria@ejemplo.cl', NULL, NOW() - INTERVAL '3 days'),
  ('Sede Norte', 'Futbolito', 'Cancha 4', CURRENT_DATE - 3, '19:00', 60, 'completada', 'bot', 'Pedro Prueba', '+56900000003', '33.333.333-3', 'pedro@prueba.cl', NULL, NOW() - INTERVAL '3 days'),
  ('Sede Norte', 'Futbolito', 'Cancha 5', CURRENT_DATE - 3, '20:00', 60, 'completada', 'telefono', 'Ana Muestra', '+56900000004', '44.444.444-4', 'ana@muestra.cl', 'Torneo empresas', NOW() - INTERVAL '3 days'),
  ('Sede Norte', 'Futbolito', 'Cancha 6', CURRENT_DATE - 3, '21:00', 60, 'completada', 'bot', 'Luis Test', '+56900000005', '55.555.555-5', 'luis@test.cl', NULL, NOW() - INTERVAL '3 days'),
  ('Sede Sur', 'Futbolito', 'Cancha 1', CURRENT_DATE - 3, '17:00', 60, 'completada', 'bot', 'Sofia Sample', '+56900000006', '66.666.666-6', 'sofia@sample.cl', NULL, NOW() - INTERVAL '3 days'),
  ('Sede Sur', 'Futbolito', 'Cancha 2', CURRENT_DATE - 3, '18:00', 60, 'completada', 'easycancha', 'Carlos Ficticio', '+56900000007', '77.777.777-7', 'carlos@ficticio.cl', NULL, NOW() - INTERVAL '3 days'),
  ('Sede Sur', 'Futbolito', 'Cancha 3', CURRENT_DATE - 3, '19:00', 60, 'completada', 'bot', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', NULL, NOW() - INTERVAL '3 days'),
  ('Sede Sur', 'Futbolito', 'Cancha 4', CURRENT_DATE - 3, '20:00', 60, 'completada', 'bot', 'Juan Demo', '+56900000001', '11.111.111-1', 'juan@demo.cl', NULL, NOW() - INTERVAL '3 days'),
  ('Sede Sur', 'Padel', 'Cancha 1', CURRENT_DATE - 3, '18:00', 60, 'completada', 'bot', 'Maria Ejemplo', '+56900000002', '22.222.222-2', 'maria@ejemplo.cl', NULL, NOW() - INTERVAL '3 days'),
  ('Sede Sur', 'Padel', 'Cancha 2', CURRENT_DATE - 3, '19:30', 90, 'completada', 'easycancha', 'Pedro Prueba', '+56900000003', '33.333.333-3', 'pedro@prueba.cl', NULL, NOW() - INTERVAL '3 days'),
  ('Sede Sur', 'Padel', 'Cancha 3', CURRENT_DATE - 3, '20:00', 60, 'completada', 'bot', 'Ana Muestra', '+56900000004', '44.444.444-4', 'ana@muestra.cl', NULL, NOW() - INTERVAL '3 days'),

  -- ============ HACE 2 DIAS ============
  ('Sede Norte', 'Futbolito', 'Cancha 1', CURRENT_DATE - 2, '17:00', 60, 'completada', 'bot', 'Luis Test', '+56900000005', '55.555.555-5', 'luis@test.cl', NULL, NOW() - INTERVAL '2 days'),
  ('Sede Norte', 'Futbolito', 'Cancha 2', CURRENT_DATE - 2, '18:00', 60, 'completada', 'easycancha', 'Sofia Sample', '+56900000006', '66.666.666-6', 'sofia@sample.cl', NULL, NOW() - INTERVAL '2 days'),
  ('Sede Norte', 'Futbolito', 'Cancha 3', CURRENT_DATE - 2, '19:00', 60, 'completada', 'bot', 'Carlos Ficticio', '+56900000007', '77.777.777-7', 'carlos@ficticio.cl', NULL, NOW() - INTERVAL '2 days'),
  ('Sede Norte', 'Futbolito', 'Cancha 4', CURRENT_DATE - 2, '19:00', 60, 'completada', 'bot', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', NULL, NOW() - INTERVAL '2 days'),
  ('Sede Norte', 'Futbolito', 'Cancha 5', CURRENT_DATE - 2, '20:00', 60, 'completada', 'telefono', 'Juan Demo', '+56900000001', '11.111.111-1', 'juan@demo.cl', NULL, NOW() - INTERVAL '2 days'),
  ('Sede Norte', 'Futbolito', 'Cancha 6', CURRENT_DATE - 2, '21:00', 60, 'completada', 'bot', 'Maria Ejemplo', '+56900000002', '22.222.222-2', 'maria@ejemplo.cl', NULL, NOW() - INTERVAL '2 days'),
  ('Sede Sur', 'Futbolito', 'Cancha 1', CURRENT_DATE - 2, '18:00', 60, 'completada', 'bot', 'Pedro Prueba', '+56900000003', '33.333.333-3', 'pedro@prueba.cl', NULL, NOW() - INTERVAL '2 days'),
  ('Sede Sur', 'Futbolito', 'Cancha 2', CURRENT_DATE - 2, '19:00', 60, 'completada', 'easycancha', 'Ana Muestra', '+56900000004', '44.444.444-4', 'ana@muestra.cl', NULL, NOW() - INTERVAL '2 days'),
  ('Sede Sur', 'Futbolito', 'Cancha 3', CURRENT_DATE - 2, '20:00', 60, 'completada', 'bot', 'Luis Test', '+56900000005', '55.555.555-5', 'luis@test.cl', NULL, NOW() - INTERVAL '2 days'),
  ('Sede Sur', 'Padel', 'Cancha 1', CURRENT_DATE - 2, '18:30', 90, 'completada', 'bot', 'Sofia Sample', '+56900000006', '66.666.666-6', 'sofia@sample.cl', NULL, NOW() - INTERVAL '2 days'),
  ('Sede Sur', 'Padel', 'Cancha 2', CURRENT_DATE - 2, '19:00', 60, 'completada', 'easycancha', 'Carlos Ficticio', '+56900000007', '77.777.777-7', 'carlos@ficticio.cl', NULL, NOW() - INTERVAL '2 days'),

  -- ============ AYER ============
  ('Sede Norte', 'Futbolito', 'Cancha 1', CURRENT_DATE - 1, '17:00', 60, 'completada', 'bot', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', NULL, NOW() - INTERVAL '1 day'),
  ('Sede Norte', 'Futbolito', 'Cancha 2', CURRENT_DATE - 1, '18:00', 60, 'completada', 'easycancha', 'Juan Demo', '+56900000001', '11.111.111-1', 'juan@demo.cl', NULL, NOW() - INTERVAL '1 day'),
  ('Sede Norte', 'Futbolito', 'Cancha 3', CURRENT_DATE - 1, '18:00', 60, 'completada', 'bot', 'Maria Ejemplo', '+56900000002', '22.222.222-2', 'maria@ejemplo.cl', NULL, NOW() - INTERVAL '1 day'),
  ('Sede Norte', 'Futbolito', 'Cancha 4', CURRENT_DATE - 1, '19:00', 60, 'completada', 'bot', 'Pedro Prueba', '+56900000003', '33.333.333-3', 'pedro@prueba.cl', NULL, NOW() - INTERVAL '1 day'),
  ('Sede Norte', 'Futbolito', 'Cancha 5', CURRENT_DATE - 1, '20:00', 60, 'completada', 'telefono', 'Ana Muestra', '+56900000004', '44.444.444-4', 'ana@muestra.cl', NULL, NOW() - INTERVAL '1 day'),
  ('Sede Norte', 'Futbolito', 'Cancha 6', CURRENT_DATE - 1, '20:00', 60, 'completada', 'bot', 'Luis Test', '+56900000005', '55.555.555-5', 'luis@test.cl', NULL, NOW() - INTERVAL '1 day'),
  ('Sede Norte', 'Futbolito', 'Cancha 1', CURRENT_DATE - 1, '21:00', 60, 'completada', 'bot', 'Sofia Sample', '+56900000006', '66.666.666-6', 'sofia@sample.cl', 'Reserva semanal', NOW() - INTERVAL '1 day'),
  ('Sede Sur', 'Futbolito', 'Cancha 1', CURRENT_DATE - 1, '17:00', 60, 'completada', 'bot', 'Carlos Ficticio', '+56900000007', '77.777.777-7', 'carlos@ficticio.cl', NULL, NOW() - INTERVAL '1 day'),
  ('Sede Sur', 'Futbolito', 'Cancha 2', CURRENT_DATE - 1, '18:00', 60, 'completada', 'easycancha', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', NULL, NOW() - INTERVAL '1 day'),
  ('Sede Sur', 'Futbolito', 'Cancha 3', CURRENT_DATE - 1, '19:00', 60, 'completada', 'bot', 'Juan Demo', '+56900000001', '11.111.111-1', 'juan@demo.cl', NULL, NOW() - INTERVAL '1 day'),
  ('Sede Sur', 'Futbolito', 'Cancha 4', CURRENT_DATE - 1, '20:00', 60, 'cancelada', 'bot', 'Maria Ejemplo', '+56900000002', '22.222.222-2', 'maria@ejemplo.cl', NULL, NOW() - INTERVAL '1 day'),
  ('Sede Sur', 'Padel', 'Cancha 1', CURRENT_DATE - 1, '18:00', 90, 'completada', 'bot', 'Pedro Prueba', '+56900000003', '33.333.333-3', 'pedro@prueba.cl', NULL, NOW() - INTERVAL '1 day'),
  ('Sede Sur', 'Padel', 'Cancha 2', CURRENT_DATE - 1, '19:00', 60, 'completada', 'easycancha', 'Ana Muestra', '+56900000004', '44.444.444-4', 'ana@muestra.cl', NULL, NOW() - INTERVAL '1 day'),
  ('Sede Sur', 'Padel', 'Cancha 3', CURRENT_DATE - 1, '20:00', 60, 'completada', 'bot', 'Luis Test', '+56900000005', '55.555.555-5', 'luis@test.cl', NULL, NOW() - INTERVAL '1 day'),

  -- ============ HOY (alta demanda ~76% SN, ~70% SS) ============
  -- Sede Norte 17:00 (5/6 canchas)
  ('Sede Norte', 'Futbolito', 'Cancha 1', CURRENT_DATE, '17:00', 60, 'confirmada', 'bot', 'Sofia Sample', '+56900000006', '66.666.666-6', 'sofia@sample.cl', NULL, NOW() - INTERVAL '8 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 2', CURRENT_DATE, '17:00', 60, 'confirmada', 'easycancha', 'Carlos Ficticio', '+56900000007', '77.777.777-7', 'carlos@ficticio.cl', NULL, NOW() - INTERVAL '8 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 3', CURRENT_DATE, '17:00', 60, 'confirmada', 'bot', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', NULL, NOW() - INTERVAL '7 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 4', CURRENT_DATE, '17:00', 60, 'confirmada', 'bot', 'Juan Demo', '+56900000001', '11.111.111-1', 'juan@demo.cl', NULL, NOW() - INTERVAL '7 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 5', CURRENT_DATE, '17:00', 60, 'confirmada', 'telefono', 'Maria Ejemplo', '+56900000002', '22.222.222-2', 'maria@ejemplo.cl', NULL, NOW() - INTERVAL '7 hours'),
  -- Sede Norte 18:00 (6/6 canchas)
  ('Sede Norte', 'Futbolito', 'Cancha 1', CURRENT_DATE, '18:00', 60, 'confirmada', 'bot', 'Carlos Ficticio', '+56900000007', '77.777.777-7', 'carlos@ficticio.cl', NULL, NOW() - INTERVAL '6 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 2', CURRENT_DATE, '18:00', 60, 'confirmada', 'easycancha', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', NULL, NOW() - INTERVAL '6 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 3', CURRENT_DATE, '18:00', 60, 'confirmada', 'bot', 'Pedro Prueba', '+56900000003', '33.333.333-3', 'pedro@prueba.cl', NULL, NOW() - INTERVAL '6 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 4', CURRENT_DATE, '18:00', 60, 'confirmada', 'dashboard', 'Ana Muestra', '+56900000004', '44.444.444-4', 'ana@muestra.cl', NULL, NOW() - INTERVAL '5 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 5', CURRENT_DATE, '18:00', 60, 'confirmada', 'bot', 'Luis Test', '+56900000005', '55.555.555-5', 'luis@test.cl', NULL, NOW() - INTERVAL '5 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 6', CURRENT_DATE, '18:00', 60, 'confirmada', 'easycancha', 'Sofia Sample', '+56900000006', '66.666.666-6', 'sofia@sample.cl', NULL, NOW() - INTERVAL '5 hours'),
  -- Sede Norte 19:00 (6/6 canchas)
  ('Sede Norte', 'Futbolito', 'Cancha 1', CURRENT_DATE, '19:00', 60, 'confirmada', 'bot', 'Juan Demo', '+56900000001', '11.111.111-1', 'juan@demo.cl', NULL, NOW() - INTERVAL '4 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 2', CURRENT_DATE, '19:00', 60, 'confirmada', 'easycancha', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', NULL, NOW() - INTERVAL '4 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 3', CURRENT_DATE, '19:00', 60, 'confirmada', 'bot', 'Pedro Prueba', '+56900000003', '33.333.333-3', 'pedro@prueba.cl', NULL, NOW() - INTERVAL '4 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 4', CURRENT_DATE, '19:00', 60, 'confirmada', 'bot', 'Maria Ejemplo', '+56900000002', '22.222.222-2', 'maria@ejemplo.cl', NULL, NOW() - INTERVAL '3 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 5', CURRENT_DATE, '19:00', 60, 'confirmada', 'telefono', 'Ana Muestra', '+56900000004', '44.444.444-4', 'ana@muestra.cl', NULL, NOW() - INTERVAL '3 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 6', CURRENT_DATE, '19:00', 60, 'confirmada', 'bot', 'Luis Test', '+56900000005', '55.555.555-5', 'luis@test.cl', NULL, NOW() - INTERVAL '3 hours'),
  -- Sede Norte 20:00 (6/6 canchas)
  ('Sede Norte', 'Futbolito', 'Cancha 1', CURRENT_DATE, '20:00', 60, 'confirmada', 'bot', 'Sofia Sample', '+56900000006', '66.666.666-6', 'sofia@sample.cl', NULL, NOW() - INTERVAL '3 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 2', CURRENT_DATE, '20:00', 60, 'confirmada', 'easycancha', 'Carlos Ficticio', '+56900000007', '77.777.777-7', 'carlos@ficticio.cl', NULL, NOW() - INTERVAL '2 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 3', CURRENT_DATE, '20:00', 60, 'confirmada', 'bot', 'Juan Demo', '+56900000001', '11.111.111-1', 'juan@demo.cl', NULL, NOW() - INTERVAL '2 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 4', CURRENT_DATE, '20:00', 60, 'confirmada', 'bot', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', NULL, NOW() - INTERVAL '2 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 5', CURRENT_DATE, '20:00', 60, 'confirmada', 'easycancha', 'Pedro Prueba', '+56900000003', '33.333.333-3', 'pedro@prueba.cl', NULL, NOW() - INTERVAL '2 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 6', CURRENT_DATE, '20:00', 60, 'pendiente', 'bot', 'Ana Muestra', '+56900000004', '44.444.444-4', 'ana@muestra.cl', NULL, NOW() - INTERVAL '1 hour'),
  -- Sede Norte 21:00 (5/6 canchas)
  ('Sede Norte', 'Futbolito', 'Cancha 1', CURRENT_DATE, '21:00', 60, 'confirmada', 'bot', 'Maria Ejemplo', '+56900000002', '22.222.222-2', 'maria@ejemplo.cl', NULL, NOW() - INTERVAL '2 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 2', CURRENT_DATE, '21:00', 60, 'confirmada', 'bot', 'Luis Test', '+56900000005', '55.555.555-5', 'luis@test.cl', 'Liga nocturna', NOW() - INTERVAL '2 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 3', CURRENT_DATE, '21:00', 60, 'pre_reserva', 'bot', 'Sofia Sample', '+56900000006', '66.666.666-6', 'sofia@sample.cl', NULL, NOW() - INTERVAL '30 minutes'),
  ('Sede Norte', 'Futbolito', 'Cancha 4', CURRENT_DATE, '21:00', 60, 'confirmada', 'easycancha', 'Carlos Ficticio', '+56900000007', '77.777.777-7', 'carlos@ficticio.cl', NULL, NOW() - INTERVAL '1 hour'),
  ('Sede Norte', 'Futbolito', 'Cancha 5', CURRENT_DATE, '21:00', 60, 'confirmada', 'bot', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', NULL, NOW() - INTERVAL '1 hour'),
  -- Sede Norte 22:00 (4/6 canchas)
  ('Sede Norte', 'Futbolito', 'Cancha 1', CURRENT_DATE, '22:00', 60, 'confirmada', 'bot', 'Juan Demo', '+56900000001', '11.111.111-1', 'juan@demo.cl', NULL, NOW() - INTERVAL '1 hour'),
  ('Sede Norte', 'Futbolito', 'Cancha 2', CURRENT_DATE, '22:00', 60, 'confirmada', 'telefono', 'Pedro Prueba', '+56900000003', '33.333.333-3', 'pedro@prueba.cl', NULL, NOW() - INTERVAL '1 hour'),
  ('Sede Norte', 'Futbolito', 'Cancha 3', CURRENT_DATE, '22:00', 60, 'pendiente', 'bot', 'Ana Muestra', '+56900000004', '44.444.444-4', 'ana@muestra.cl', NULL, NOW() - INTERVAL '30 minutes'),
  ('Sede Norte', 'Futbolito', 'Cancha 4', CURRENT_DATE, '22:00', 60, 'confirmada', 'bot', 'Luis Test', '+56900000005', '55.555.555-5', 'luis@test.cl', NULL, NOW() - INTERVAL '30 minutes'),
  -- Sede Sur Futbolito 17:00 (3/4)
  ('Sede Sur', 'Futbolito', 'Cancha 1', CURRENT_DATE, '17:00', 60, 'confirmada', 'bot', 'Carlos Ficticio', '+56900000007', '77.777.777-7', 'carlos@ficticio.cl', NULL, NOW() - INTERVAL '7 hours'),
  ('Sede Sur', 'Futbolito', 'Cancha 2', CURRENT_DATE, '17:00', 60, 'confirmada', 'easycancha', 'Sofia Sample', '+56900000006', '66.666.666-6', 'sofia@sample.cl', NULL, NOW() - INTERVAL '7 hours'),
  ('Sede Sur', 'Futbolito', 'Cancha 3', CURRENT_DATE, '17:00', 60, 'confirmada', 'bot', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', NULL, NOW() - INTERVAL '6 hours'),
  -- Sede Sur Futbolito 18:00 (4/4)
  ('Sede Sur', 'Futbolito', 'Cancha 1', CURRENT_DATE, '18:00', 60, 'confirmada', 'easycancha', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', NULL, NOW() - INTERVAL '6 hours'),
  ('Sede Sur', 'Futbolito', 'Cancha 2', CURRENT_DATE, '18:00', 60, 'confirmada', 'bot', 'Juan Demo', '+56900000001', '11.111.111-1', 'juan@demo.cl', NULL, NOW() - INTERVAL '5 hours'),
  ('Sede Sur', 'Futbolito', 'Cancha 3', CURRENT_DATE, '18:00', 60, 'confirmada', 'bot', 'Maria Ejemplo', '+56900000002', '22.222.222-2', 'maria@ejemplo.cl', NULL, NOW() - INTERVAL '5 hours'),
  ('Sede Sur', 'Futbolito', 'Cancha 4', CURRENT_DATE, '18:00', 60, 'confirmada', 'telefono', 'Pedro Prueba', '+56900000003', '33.333.333-3', 'pedro@prueba.cl', NULL, NOW() - INTERVAL '5 hours'),
  -- Sede Sur Futbolito 19:00 (4/4)
  ('Sede Sur', 'Futbolito', 'Cancha 1', CURRENT_DATE, '19:00', 60, 'confirmada', 'bot', 'Ana Muestra', '+56900000004', '44.444.444-4', 'ana@muestra.cl', NULL, NOW() - INTERVAL '4 hours'),
  ('Sede Sur', 'Futbolito', 'Cancha 2', CURRENT_DATE, '19:00', 60, 'confirmada', 'bot', 'Luis Test', '+56900000005', '55.555.555-5', 'luis@test.cl', 'Reserva semanal', NOW() - INTERVAL '4 hours'),
  ('Sede Sur', 'Futbolito', 'Cancha 3', CURRENT_DATE, '19:00', 60, 'confirmada', 'telefono', 'Carlos Ficticio', '+56900000007', '77.777.777-7', 'carlos@ficticio.cl', NULL, NOW() - INTERVAL '3 hours'),
  ('Sede Sur', 'Futbolito', 'Cancha 4', CURRENT_DATE, '19:00', 60, 'confirmada', 'easycancha', 'Sofia Sample', '+56900000006', '66.666.666-6', 'sofia@sample.cl', NULL, NOW() - INTERVAL '3 hours'),
  -- Sede Sur Futbolito 20:00 (4/4)
  ('Sede Sur', 'Futbolito', 'Cancha 1', CURRENT_DATE, '20:00', 60, 'confirmada', 'bot', 'Pedro Prueba', '+56900000003', '33.333.333-3', 'pedro@prueba.cl', NULL, NOW() - INTERVAL '3 hours'),
  ('Sede Sur', 'Futbolito', 'Cancha 2', CURRENT_DATE, '20:00', 60, 'confirmada', 'easycancha', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', NULL, NOW() - INTERVAL '2 hours'),
  ('Sede Sur', 'Futbolito', 'Cancha 3', CURRENT_DATE, '20:00', 60, 'confirmada', 'bot', 'Juan Demo', '+56900000001', '11.111.111-1', 'juan@demo.cl', NULL, NOW() - INTERVAL '2 hours'),
  ('Sede Sur', 'Futbolito', 'Cancha 4', CURRENT_DATE, '20:00', 60, 'pendiente', 'bot', 'Maria Ejemplo', '+56900000002', '22.222.222-2', 'maria@ejemplo.cl', NULL, NOW() - INTERVAL '1 hour'),
  -- Sede Sur Futbolito 21:00 (3/4)
  ('Sede Sur', 'Futbolito', 'Cancha 1', CURRENT_DATE, '21:00', 60, 'confirmada', 'bot', 'Sofia Sample', '+56900000006', '66.666.666-6', 'sofia@sample.cl', NULL, NOW() - INTERVAL '2 hours'),
  ('Sede Sur', 'Futbolito', 'Cancha 2', CURRENT_DATE, '21:00', 60, 'confirmada', 'bot', 'Carlos Ficticio', '+56900000007', '77.777.777-7', 'carlos@ficticio.cl', NULL, NOW() - INTERVAL '2 hours'),
  ('Sede Sur', 'Futbolito', 'Cancha 3', CURRENT_DATE, '21:00', 60, 'confirmada', 'easycancha', 'Ana Muestra', '+56900000004', '44.444.444-4', 'ana@muestra.cl', NULL, NOW() - INTERVAL '1 hour'),
  -- Sede Sur Futbolito 22:00 (2/4)
  ('Sede Sur', 'Futbolito', 'Cancha 1', CURRENT_DATE, '22:00', 60, 'confirmada', 'bot', 'Luis Test', '+56900000005', '55.555.555-5', 'luis@test.cl', NULL, NOW() - INTERVAL '1 hour'),
  ('Sede Sur', 'Futbolito', 'Cancha 2', CURRENT_DATE, '22:00', 60, 'pendiente', 'bot', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', NULL, NOW() - INTERVAL '30 minutes'),
  -- Sede Sur Padel 17:00-22:00
  ('Sede Sur', 'Padel', 'Cancha 1', CURRENT_DATE, '17:00', 60, 'confirmada', 'bot', 'Pedro Prueba', '+56900000003', '33.333.333-3', 'pedro@prueba.cl', NULL, NOW() - INTERVAL '7 hours'),
  ('Sede Sur', 'Padel', 'Cancha 2', CURRENT_DATE, '17:00', 60, 'confirmada', 'easycancha', 'Ana Muestra', '+56900000004', '44.444.444-4', 'ana@muestra.cl', NULL, NOW() - INTERVAL '7 hours'),
  ('Sede Sur', 'Padel', 'Cancha 3', CURRENT_DATE, '17:00', 60, 'confirmada', 'bot', 'Luis Test', '+56900000005', '55.555.555-5', 'luis@test.cl', NULL, NOW() - INTERVAL '6 hours'),
  ('Sede Sur', 'Padel', 'Cancha 1', CURRENT_DATE, '17:30', 60, 'confirmada', 'bot', 'Sofia Sample', '+56900000006', '66.666.666-6', 'sofia@sample.cl', NULL, NOW() - INTERVAL '6 hours'),
  ('Sede Sur', 'Padel', 'Cancha 2', CURRENT_DATE, '17:30', 60, 'confirmada', 'easycancha', 'Carlos Ficticio', '+56900000007', '77.777.777-7', 'carlos@ficticio.cl', NULL, NOW() - INTERVAL '6 hours'),
  ('Sede Sur', 'Padel', 'Cancha 1', CURRENT_DATE, '18:00', 90, 'confirmada', 'bot', 'Ana Muestra', '+56900000004', '44.444.444-4', 'ana@muestra.cl', NULL, NOW() - INTERVAL '6 hours'),
  ('Sede Sur', 'Padel', 'Cancha 2', CURRENT_DATE, '18:00', 60, 'confirmada', 'easycancha', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', NULL, NOW() - INTERVAL '5 hours'),
  ('Sede Sur', 'Padel', 'Cancha 3', CURRENT_DATE, '18:00', 60, 'confirmada', 'bot', 'Maria Ejemplo', '+56900000002', '22.222.222-2', 'maria@ejemplo.cl', NULL, NOW() - INTERVAL '5 hours'),
  ('Sede Sur', 'Padel', 'Cancha 1', CURRENT_DATE, '18:30', 60, 'confirmada', 'bot', 'Juan Demo', '+56900000001', '11.111.111-1', 'juan@demo.cl', NULL, NOW() - INTERVAL '5 hours'),
  ('Sede Sur', 'Padel', 'Cancha 2', CURRENT_DATE, '18:30', 60, 'confirmada', 'easycancha', 'Pedro Prueba', '+56900000003', '33.333.333-3', 'pedro@prueba.cl', NULL, NOW() - INTERVAL '5 hours'),
  ('Sede Sur', 'Padel', 'Cancha 3', CURRENT_DATE, '18:30', 60, 'confirmada', 'bot', 'Sofia Sample', '+56900000006', '66.666.666-6', 'sofia@sample.cl', NULL, NOW() - INTERVAL '4 hours'),
  ('Sede Sur', 'Padel', 'Cancha 1', CURRENT_DATE, '19:00', 60, 'confirmada', 'easycancha', 'Luis Test', '+56900000005', '55.555.555-5', 'luis@test.cl', NULL, NOW() - INTERVAL '4 hours'),
  ('Sede Sur', 'Padel', 'Cancha 2', CURRENT_DATE, '19:00', 60, 'confirmada', 'bot', 'Carlos Ficticio', '+56900000007', '77.777.777-7', 'carlos@ficticio.cl', NULL, NOW() - INTERVAL '3 hours'),
  ('Sede Sur', 'Padel', 'Cancha 3', CURRENT_DATE, '19:00', 60, 'confirmada', 'bot', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', NULL, NOW() - INTERVAL '3 hours'),
  ('Sede Sur', 'Padel', 'Cancha 1', CURRENT_DATE, '19:30', 60, 'confirmada', 'bot', 'Maria Ejemplo', '+56900000002', '22.222.222-2', 'maria@ejemplo.cl', NULL, NOW() - INTERVAL '3 hours'),
  ('Sede Sur', 'Padel', 'Cancha 2', CURRENT_DATE, '19:30', 60, 'confirmada', 'easycancha', 'Ana Muestra', '+56900000004', '44.444.444-4', 'ana@muestra.cl', NULL, NOW() - INTERVAL '3 hours'),
  ('Sede Sur', 'Padel', 'Cancha 1', CURRENT_DATE, '20:00', 60, 'confirmada', 'bot', 'Sofia Sample', '+56900000006', '66.666.666-6', 'sofia@sample.cl', NULL, NOW() - INTERVAL '2 hours'),
  ('Sede Sur', 'Padel', 'Cancha 2', CURRENT_DATE, '20:00', 60, 'confirmada', 'easycancha', 'Juan Demo', '+56900000001', '11.111.111-1', 'juan@demo.cl', NULL, NOW() - INTERVAL '2 hours'),
  ('Sede Sur', 'Padel', 'Cancha 3', CURRENT_DATE, '20:00', 60, 'confirmada', 'bot', 'Pedro Prueba', '+56900000003', '33.333.333-3', 'pedro@prueba.cl', NULL, NOW() - INTERVAL '2 hours'),
  ('Sede Sur', 'Padel', 'Cancha 1', CURRENT_DATE, '20:30', 60, 'confirmada', 'bot', 'Carlos Ficticio', '+56900000007', '77.777.777-7', 'carlos@ficticio.cl', NULL, NOW() - INTERVAL '2 hours'),
  ('Sede Sur', 'Padel', 'Cancha 2', CURRENT_DATE, '20:30', 60, 'confirmada', 'bot', 'Luis Test', '+56900000005', '55.555.555-5', 'luis@test.cl', NULL, NOW() - INTERVAL '1 hour'),
  ('Sede Sur', 'Padel', 'Cancha 1', CURRENT_DATE, '21:00', 60, 'confirmada', 'bot', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', NULL, NOW() - INTERVAL '1 hour'),
  ('Sede Sur', 'Padel', 'Cancha 2', CURRENT_DATE, '21:00', 60, 'confirmada', 'easycancha', 'Maria Ejemplo', '+56900000002', '22.222.222-2', 'maria@ejemplo.cl', NULL, NOW() - INTERVAL '1 hour'),
  ('Sede Sur', 'Padel', 'Cancha 3', CURRENT_DATE, '21:00', 60, 'pendiente', 'bot', 'Ana Muestra', '+56900000004', '44.444.444-4', 'ana@muestra.cl', NULL, NOW() - INTERVAL '30 minutes'),
  ('Sede Sur', 'Padel', 'Cancha 1', CURRENT_DATE, '21:30', 60, 'confirmada', 'bot', 'Juan Demo', '+56900000001', '11.111.111-1', 'juan@demo.cl', NULL, NOW() - INTERVAL '1 hour'),
  ('Sede Sur', 'Padel', 'Cancha 2', CURRENT_DATE, '21:30', 60, 'pre_reserva', 'bot', 'Pedro Prueba', '+56900000003', '33.333.333-3', 'pedro@prueba.cl', NULL, NOW() - INTERVAL '30 minutes'),
  ('Sede Sur', 'Padel', 'Cancha 1', CURRENT_DATE, '22:00', 60, 'confirmada', 'bot', 'Sofia Sample', '+56900000006', '66.666.666-6', 'sofia@sample.cl', NULL, NOW() - INTERVAL '30 minutes'),

  -- ============ MANANA (ya con reservas anticipadas) ============
  ('Sede Norte', 'Futbolito', 'Cancha 1', CURRENT_DATE + 1, '18:00', 60, 'confirmada', 'bot', 'Carlos Ficticio', '+56900000007', '77.777.777-7', 'carlos@ficticio.cl', NULL, NOW() - INTERVAL '2 hours'),
  ('Sede Norte', 'Futbolito', 'Cancha 2', CURRENT_DATE + 1, '19:00', 60, 'confirmada', 'easycancha', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', NULL, NOW() - INTERVAL '1 hour'),
  ('Sede Norte', 'Futbolito', 'Cancha 3', CURRENT_DATE + 1, '19:00', 60, 'pendiente', 'bot', 'Juan Demo', '+56900000001', '11.111.111-1', 'juan@demo.cl', NULL, NOW()),
  ('Sede Norte', 'Futbolito', 'Cancha 4', CURRENT_DATE + 1, '20:00', 60, 'confirmada', 'bot', 'Maria Ejemplo', '+56900000002', '22.222.222-2', 'maria@ejemplo.cl', NULL, NOW()),
  ('Sede Norte', 'Futbolito', 'Cancha 5', CURRENT_DATE + 1, '20:00', 60, 'pre_reserva', 'bot', 'Pedro Prueba', '+56900000003', '33.333.333-3', 'pedro@prueba.cl', NULL, NOW()),
  ('Sede Sur', 'Futbolito', 'Cancha 1', CURRENT_DATE + 1, '18:00', 60, 'confirmada', 'bot', 'Ana Muestra', '+56900000004', '44.444.444-4', 'ana@muestra.cl', NULL, NOW()),
  ('Sede Sur', 'Futbolito', 'Cancha 2', CURRENT_DATE + 1, '19:00', 60, 'confirmada', 'easycancha', 'Luis Test', '+56900000005', '55.555.555-5', 'luis@test.cl', NULL, NOW()),
  ('Sede Sur', 'Padel', 'Cancha 1', CURRENT_DATE + 1, '19:00', 60, 'confirmada', 'dashboard', 'Sofia Sample', '+56900000006', '66.666.666-6', 'sofia@sample.cl', 'Clase padel', NOW()),
  ('Sede Sur', 'Padel', 'Cancha 2', CURRENT_DATE + 1, '20:00', 90, 'pendiente', 'bot', 'Carlos Ficticio', '+56900000007', '77.777.777-7', 'carlos@ficticio.cl', NULL, NOW()),

  -- ============ PASADO MANANA Y DESPUES ============
  ('Sede Norte', 'Futbolito', 'Cancha 1', CURRENT_DATE + 2, '18:00', 60, 'confirmada', 'bot', 'Valentina Mock', '+56900000008', '88.888.888-8', 'valentina@mock.cl', NULL, NOW()),
  ('Sede Norte', 'Futbolito', 'Cancha 2', CURRENT_DATE + 2, '19:00', 60, 'pendiente', 'bot', 'Juan Demo', '+56900000001', '11.111.111-1', 'juan@demo.cl', NULL, NOW()),
  ('Sede Sur', 'Futbolito', 'Cancha 1', CURRENT_DATE + 2, '19:00', 60, 'confirmada', 'easycancha', 'Maria Ejemplo', '+56900000002', '22.222.222-2', 'maria@ejemplo.cl', NULL, NOW()),
  ('Sede Sur', 'Padel', 'Cancha 1', CURRENT_DATE + 3, '18:00', 90, 'pendiente', 'bot', 'Pedro Prueba', '+56900000003', '33.333.333-3', 'pedro@prueba.cl', NULL, NOW());

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
-- CONVERSACIONES REALISTAS (flujo completo de reserva)
-- =============================================

-- CONV 1: Juan Demo - Flujo completo de reserva futbolito (hace 2 dias)
INSERT INTO mensajes_raw (sender_id, canal, mensaje, sender_name, created_at) VALUES
  ('56900000001', 'whatsapp', 'Hola buenas tardes', 'Juan Demo', NOW() - INTERVAL '2 days 5 hours'),
  ('56900000001', 'whatsapp', 'Quiero reservar una cancha de futbolito', 'Juan Demo', NOW() - INTERVAL '2 days 4 hours 58 minutes'),
  ('56900000001', 'whatsapp', 'Para hoy en la tarde si es posible', 'Juan Demo', NOW() - INTERVAL '2 days 4 hours 55 minutes'),
  ('56900000001', 'whatsapp', 'Sede Norte porfa', 'Juan Demo', NOW() - INTERVAL '2 days 4 hours 50 minutes'),
  ('56900000001', 'whatsapp', 'La de las 18:00 esta bien', 'Juan Demo', NOW() - INTERVAL '2 days 4 hours 45 minutes'),
  ('56900000001', 'whatsapp', 'Juan Demo', 'Juan Demo', NOW() - INTERVAL '2 days 4 hours 42 minutes'),
  ('56900000001', 'whatsapp', '11.111.111-1', 'Juan Demo', NOW() - INTERVAL '2 days 4 hours 40 minutes'),
  ('56900000001', 'whatsapp', 'Perfecto, ahi estaremos. Gracias!', 'Juan Demo', NOW() - INTERVAL '2 days 4 hours 35 minutes');

INSERT INTO mensajes (sender_id, canal, direccion, contenido, created_at) VALUES
  ('56900000001', 'whatsapp', 'outbound', 'Hola! Bienvenido a Cancha Llena. Soy el asistente virtual y te puedo ayudar a reservar tu cancha. Que tipo de cancha necesitas? (Futbolito / Padel)', NOW() - INTERVAL '2 days 4 hours 59 minutes'),
  ('56900000001', 'whatsapp', 'outbound', 'Genial! Para que dia necesitas la cancha de futbolito?', NOW() - INTERVAL '2 days 4 hours 57 minutes'),
  ('56900000001', 'whatsapp', 'outbound', 'Perfecto! En que sede prefieres? Tenemos Sede Norte y Sede Sur.', NOW() - INTERVAL '2 days 4 hours 53 minutes'),
  ('56900000001', 'whatsapp', 'outbound', 'Excelente! En Sede Norte para hoy tenemos disponible: Cancha 1 a las 18:00, Cancha 2 a las 18:00, Cancha 3 a las 19:00, Cancha 4 a las 19:00. Cual prefieres?', NOW() - INTERVAL '2 days 4 hours 48 minutes'),
  ('56900000001', 'whatsapp', 'outbound', 'Listo! Para confirmar necesito tu nombre completo.', NOW() - INTERVAL '2 days 4 hours 44 minutes'),
  ('56900000001', 'whatsapp', 'outbound', 'Gracias Juan! Y tu RUT por favor?', NOW() - INTERVAL '2 days 4 hours 41 minutes'),
  ('56900000001', 'whatsapp', 'outbound', 'Tu reserva quedo confirmada! Resumen: Futbolito - Sede Norte, Cancha 2 - Hoy a las 18:00 - 60 min - A nombre de Juan Demo (11.111.111-1). Te esperamos!', NOW() - INTERVAL '2 days 4 hours 38 minutes');

-- CONV 2: Maria Ejemplo - Reserva padel con consulta de precios (hace 1 dia)
INSERT INTO mensajes_raw (sender_id, canal, mensaje, sender_name, created_at) VALUES
  ('56900000002', 'whatsapp', 'Buenas! Cuanto sale la hora de padel?', 'Maria Ejemplo', NOW() - INTERVAL '1 day 6 hours'),
  ('56900000002', 'whatsapp', 'Y la hora y media?', 'Maria Ejemplo', NOW() - INTERVAL '1 day 5 hours 55 minutes'),
  ('56900000002', 'whatsapp', 'Ok quiero reservar para manana una hora', 'Maria Ejemplo', NOW() - INTERVAL '1 day 5 hours 50 minutes'),
  ('56900000002', 'whatsapp', 'A las 19:00', 'Maria Ejemplo', NOW() - INTERVAL '1 day 5 hours 45 minutes'),
  ('56900000002', 'whatsapp', 'Maria Ejemplo', 'Maria Ejemplo', NOW() - INTERVAL '1 day 5 hours 42 minutes'),
  ('56900000002', 'whatsapp', '22.222.222-2', 'Maria Ejemplo', NOW() - INTERVAL '1 day 5 hours 40 minutes'),
  ('56900000002', 'whatsapp', 'Gracias! Nos vemos manana', 'Maria Ejemplo', NOW() - INTERVAL '1 day 5 hours 36 minutes');

INSERT INTO mensajes (sender_id, canal, direccion, contenido, created_at) VALUES
  ('56900000002', 'whatsapp', 'outbound', 'Hola Maria! La hora de padel en Sede Sur tiene un valor de $18.000 (60 min) o $24.000 (90 min). Quieres reservar?', NOW() - INTERVAL '1 day 5 hours 58 minutes'),
  ('56900000002', 'whatsapp', 'outbound', 'La hora y media (90 min) sale $24.000. Es ideal para partidos mas largos!', NOW() - INTERVAL '1 day 5 hours 53 minutes'),
  ('56900000002', 'whatsapp', 'outbound', 'Para manana tenemos disponible en Padel: Cancha 1 a las 18:00, 19:00 y 20:00. Cancha 2 a las 19:00 y 20:00. Cancha 3 a las 18:30 y 20:00. Que horario prefieres?', NOW() - INTERVAL '1 day 5 hours 48 minutes'),
  ('56900000002', 'whatsapp', 'outbound', 'Perfecto! Cancha 1 de Padel a las 19:00. Para confirmar necesito tu nombre completo.', NOW() - INTERVAL '1 day 5 hours 43 minutes'),
  ('56900000002', 'whatsapp', 'outbound', 'Gracias Maria! Tu RUT por favor?', NOW() - INTERVAL '1 day 5 hours 41 minutes'),
  ('56900000002', 'whatsapp', 'outbound', 'Reserva confirmada! Padel - Sede Sur, Cancha 1 - Manana a las 19:00 - 60 min - A nombre de Maria Ejemplo (22.222.222-2). Nos vemos!', NOW() - INTERVAL '1 day 5 hours 38 minutes');

-- CONV 3: Pedro Prueba - Reserva rapida recurrente (hoy)
INSERT INTO mensajes_raw (sender_id, canal, mensaje, sender_name, created_at) VALUES
  ('56900000003', 'whatsapp', 'Hola, la misma de siempre porfa. Futbolito Sede Norte 20:00', 'Pedro Prueba', NOW() - INTERVAL '3 hours'),
  ('56900000003', 'whatsapp', 'Para hoy', 'Pedro Prueba', NOW() - INTERVAL '2 hours 55 minutes'),
  ('56900000003', 'whatsapp', 'Dale, Cancha 5 esta bien', 'Pedro Prueba', NOW() - INTERVAL '2 hours 50 minutes');

INSERT INTO mensajes (sender_id, canal, direccion, contenido, created_at) VALUES
  ('56900000003', 'whatsapp', 'outbound', 'Hola Pedro! Te tengo registrado. Para hoy en Sede Norte a las 20:00 tenemos disponible: Cancha 5 y Cancha 6. Cual prefieres?', NOW() - INTERVAL '2 hours 58 minutes'),
  ('56900000003', 'whatsapp', 'outbound', 'Listo! Reserva confirmada: Futbolito - Sede Norte, Cancha 5 - Hoy a las 20:00 - A nombre de Pedro Prueba. Como siempre, te esperamos!', NOW() - INTERVAL '2 hours 48 minutes');

-- CONV 4: Ana Muestra - Consulta + reserva padel para hoy (hoy)
INSERT INTO mensajes_raw (sender_id, canal, mensaje, sender_name, created_at) VALUES
  ('56900000004', 'whatsapp', 'Hola! Tienen padel disponible para hoy?', 'Ana Muestra', NOW() - INTERVAL '6 hours'),
  ('56900000004', 'whatsapp', 'A las 18:00 porfa, hora y media', 'Ana Muestra', NOW() - INTERVAL '5 hours 55 minutes'),
  ('56900000004', 'whatsapp', 'Ana Muestra, rut 44.444.444-4', 'Ana Muestra', NOW() - INTERVAL '5 hours 50 minutes'),
  ('56900000004', 'whatsapp', 'Genial, gracias!', 'Ana Muestra', NOW() - INTERVAL '5 hours 45 minutes');

INSERT INTO mensajes (sender_id, canal, direccion, contenido, created_at) VALUES
  ('56900000004', 'whatsapp', 'outbound', 'Hola Ana! Si, para hoy en Padel tenemos: Cancha 1 a las 18:00 y 20:00, Cancha 2 a las 19:00, Cancha 3 a las 20:00. Que horario te acomoda?', NOW() - INTERVAL '5 hours 58 minutes'),
  ('56900000004', 'whatsapp', 'outbound', 'Cancha 1 a las 18:00 por 90 min ($24.000). Para confirmar necesito nombre y RUT.', NOW() - INTERVAL '5 hours 53 minutes'),
  ('56900000004', 'whatsapp', 'outbound', 'Reserva confirmada! Padel - Sede Sur, Cancha 1 - Hoy a las 18:00 - 90 min - A nombre de Ana Muestra (44.444.444-4). Que la pasen bien!', NOW() - INTERVAL '5 hours 48 minutes');

-- CONV 5: Carlos Ficticio - Reserva futbolito manana (hoy)
INSERT INTO mensajes_raw (sender_id, canal, mensaje, sender_name, created_at) VALUES
  ('56900000007', 'whatsapp', 'Buenas noches, quiero reservar futbolito para manana', 'Carlos Ficticio', NOW() - INTERVAL '2 hours'),
  ('56900000007', 'whatsapp', 'Sede Norte, tipo 18:00-19:00', 'Carlos Ficticio', NOW() - INTERVAL '1 hour 55 minutes'),
  ('56900000007', 'whatsapp', 'Cancha 1 porfa', 'Carlos Ficticio', NOW() - INTERVAL '1 hour 50 minutes'),
  ('56900000007', 'whatsapp', 'Carlos Ficticio, 77.777.777-7', 'Carlos Ficticio', NOW() - INTERVAL '1 hour 47 minutes'),
  ('56900000007', 'whatsapp', 'Gracias, buena onda el bot jaja', 'Carlos Ficticio', NOW() - INTERVAL '1 hour 43 minutes');

INSERT INTO mensajes (sender_id, canal, direccion, contenido, created_at) VALUES
  ('56900000007', 'whatsapp', 'outbound', 'Hola Carlos! Con gusto te ayudo. En Sede Norte para manana a las 18:00 tenemos disponible: Cancha 1, Cancha 2, Cancha 4 y Cancha 6. Cual quieres?', NOW() - INTERVAL '1 hour 58 minutes'),
  ('56900000007', 'whatsapp', 'outbound', 'Excelente eleccion! Para confirmar necesito tu nombre completo y RUT.', NOW() - INTERVAL '1 hour 48 minutes'),
  ('56900000007', 'whatsapp', 'outbound', 'Reserva confirmada! Futbolito - Sede Norte, Cancha 1 - Manana a las 18:00 - 60 min - A nombre de Carlos Ficticio (77.777.777-7). Nos vemos!', NOW() - INTERVAL '1 hour 45 minutes'),
  ('56900000007', 'whatsapp', 'outbound', 'Jaja gracias Carlos! Cualquier cosa me escribes. Buenas noches!', NOW() - INTERVAL '1 hour 42 minutes');

-- CONV 6: Luis Test - Consulta horarios de fin de semana (hoy)
INSERT INTO mensajes_raw (sender_id, canal, mensaje, sender_name, created_at) VALUES
  ('56900000005', 'whatsapp', 'Hola, tienen disponibilidad para este fin de semana?', 'Luis Test', NOW() - INTERVAL '4 hours'),
  ('56900000005', 'whatsapp', 'Futbolito en Sede Sur', 'Luis Test', NOW() - INTERVAL '3 hours 55 minutes'),
  ('56900000005', 'whatsapp', 'Sabado a las 19:00 si hay', 'Luis Test', NOW() - INTERVAL '3 hours 48 minutes'),
  ('56900000005', 'whatsapp', 'Luis Test, 55.555.555-5', 'Luis Test', NOW() - INTERVAL '3 hours 43 minutes'),
  ('56900000005', 'whatsapp', 'Excelente, quedamos asi!', 'Luis Test', NOW() - INTERVAL '3 hours 38 minutes');

INSERT INTO mensajes (sender_id, canal, direccion, contenido, created_at) VALUES
  ('56900000005', 'whatsapp', 'outbound', 'Hola Luis! Que tipo de cancha buscas y en que sede?', NOW() - INTERVAL '3 hours 58 minutes'),
  ('56900000005', 'whatsapp', 'outbound', 'Para este fin de semana en Sede Sur Futbolito tenemos buena disponibilidad! El sabado: Cancha 1, 2 y 3 a las 17:00, 18:00, 19:00 y 20:00. Domingo: todas disponibles de 09:00 a 23:00. Que dia y hora prefieres?', NOW() - INTERVAL '3 hours 50 minutes'),
  ('56900000005', 'whatsapp', 'outbound', 'Sabado Cancha 2 a las 19:00. Tu nombre y RUT para confirmar?', NOW() - INTERVAL '3 hours 45 minutes'),
  ('56900000005', 'whatsapp', 'outbound', 'Confirmado! Futbolito - Sede Sur, Cancha 2 - Sabado a las 19:00 - A nombre de Luis Test (55.555.555-5). Buen partido!', NOW() - INTERVAL '3 hours 40 minutes');

-- =============================================
-- ALERTAS (mas positivas, menos errores)
-- =============================================

INSERT INTO alertas (tipo, reserva_id, mensaje, canal, sender_id, leida, resuelta, created_at) VALUES
  -- Alertas de reserva (nuevas y exitosas)
  ('reserva', NULL, 'Nueva reserva por bot - Sofia Sample, Sede Norte Cancha 1 hoy 17:00', 'whatsapp', '56900000006', true, true, NOW() - INTERVAL '8 hours'),
  ('reserva', NULL, 'Nueva reserva por bot - Carlos Ficticio, Sede Norte Cancha 2 hoy 17:00', 'whatsapp', '56900000007', true, true, NOW() - INTERVAL '8 hours'),
  ('reserva', NULL, 'Nueva reserva por bot - Juan Demo, Sede Norte Cancha 1 hoy 19:00', 'whatsapp', '56900000001', true, true, NOW() - INTERVAL '4 hours'),
  ('reserva', NULL, 'Nueva reserva por EasyCancha - Pedro Prueba, Sede Norte Cancha 5 hoy 20:00', 'easycancha', '56900000003', false, false, NOW() - INTERVAL '2 hours'),
  ('reserva', NULL, 'Nueva reserva pendiente - Ana Muestra, Sede Norte Cancha 6 hoy 20:00', 'whatsapp', '56900000004', false, false, NOW() - INTERVAL '1 hour'),
  ('reserva', NULL, 'Nueva reserva por bot - Luis Test, Sede Norte Cancha 2 hoy 21:00 (Liga nocturna)', 'whatsapp', '56900000005', false, false, NOW() - INTERVAL '2 hours'),
  ('reserva', NULL, 'Pre-reserva pendiente - Sofia Sample, Sede Norte Cancha 3 hoy 21:00', 'whatsapp', '56900000006', false, false, NOW() - INTERVAL '30 minutes'),
  ('reserva', NULL, 'Nueva reserva por bot - Carlos Ficticio, Sede Norte Cancha 1 manana 18:00', 'whatsapp', '56900000007', false, false, NOW() - INTERVAL '2 hours'),

  -- Alertas EasyCancha sync (todo funcionando bien)
  ('easycancha_sync', NULL, 'Sincronizacion EasyCancha completada - 8 reservas importadas', NULL, NULL, true, true, NOW() - INTERVAL '3 days'),
  ('easycancha_sync', NULL, 'Sincronizacion EasyCancha completada - 12 reservas importadas', NULL, NULL, true, true, NOW() - INTERVAL '2 days'),
  ('easycancha_sync', NULL, 'Sincronizacion EasyCancha completada - 6 reservas importadas', NULL, NULL, true, true, NOW() - INTERVAL '1 day'),
  ('easycancha_sync', NULL, 'Sincronizacion EasyCancha completada - 9 reservas importadas', NULL, NULL, false, false, NOW() - INTERVAL '4 hours'),

  -- Escalamiento (solo 1, resuelto)
  ('escalamiento', NULL, 'Cliente consulta sobre torneos disponibles - Pedro Prueba', 'whatsapp', '56900000003', true, true, NOW() - INTERVAL '2 days'),

  -- Sin errores recientes (negocio estable)
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
