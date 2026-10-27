CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT NOT NULL UNIQUE,
  email TEXT,
  salt TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'client',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS sessions (
  token TEXT PRIMARY KEY,
  user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS orders (
  id SERIAL PRIMARY KEY,
  user_id INT NOT NULL REFERENCES users(id),
  copies INT NOT NULL DEFAULT 1,
  color TEXT NOT NULL DEFAULT 'bw',
  paper_size TEXT NOT NULL,
  paper_type TEXT NOT NULL,
  duplex BOOLEAN NOT NULL DEFAULT false,
  page_range TEXT,
  notes TEXT,
  status TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  finished_at TIMESTAMPTZ
);
CREATE TABLE IF NOT EXISTS order_files (
  id SERIAL PRIMARY KEY,
  order_id INT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  original_name TEXT NOT NULL,
  stored_name TEXT NOT NULL,
  size BIGINT NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_orders_user ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_files_order ON order_files(order_id);

CREATE INDEX IF NOT EXISTS idx_orders_user ON orders(user_id, id DESC);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status, id DESC);
CREATE INDEX IF NOT EXISTS idx_files_order ON order_files(order_id);

-- v0.0.2 offline sync: lets the app retry an upload safely without duplicating the order
ALTER TABLE orders ADD COLUMN IF NOT EXISTS client_id TEXT;
CREATE UNIQUE INDEX IF NOT EXISTS idx_orders_client ON orders(user_id, client_id) WHERE client_id IS NOT NULL;
