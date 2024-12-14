CREATE TABLE IF NOT EXISTS users (
  id serial PRIMARY KEY,
  username text NOT NULL UNIQUE,
  password_hash text NOT NULL,
  created_at timestamp NOT NULL DEFAULT now(),
  updated_at timestamp NOT NULL DEFAULT now(),
  UNIQUE (username, password_hash)
);

CREATE TABLE IF NOT EXISTS credentials (
  id serial PRIMARY KEY,
  user_id integer NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  name text NOT NULL,
  username text NOT NULL,
  encrypted_password text,
  iv text,
  notes text,
  UNIQUE(name, username)
);
