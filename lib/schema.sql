CREATE TABLE IF NOT EXISTS users (
  id serial PRIMARY KEY,
  username text NOT NULL UNIQUE,
  password_hash text NOT NULL,
  created_at timestamp NOT NULL DEFAULT now(),
  updated_at timestamp NOT NULL DEFAULT now(),
  CHECK (length(username) BETWEEN 2 AND 36),
  CHECK (username ~* '^[a-z0-9]+$')
);

CREATE TABLE IF NOT EXISTS credentials (
  id serial PRIMARY KEY,
  user_id integer NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  name text NOT NULL,
  username text NOT NULL,
  encrypted_password text,
  iv text,
  notes text,
  created_at timestamp NOT NULL DEFAULT now(),
  updated_at timestamp NOT NULL DEFAULT now(),
  UNIQUE (name, username),
  CHECK (length(name) BETWEEN 1 AND 64),
  CHECK (length(username) BETWEEN 2 AND 256)
);
