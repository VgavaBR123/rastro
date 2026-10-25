-- Esquema inicial do backend. Executado pelo container na primeira subida.
CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE IF NOT EXISTS uploads (
  id            TEXT PRIMARY KEY,
  status        TEXT NOT NULL DEFAULT 'received',
  received_at   BIGINT NOT NULL,
  size_bytes    INTEGER NOT NULL,
  activity_guid TEXT,
  fit           BYTEA NOT NULL,
  -- Geometria da rota (preenchida quando decodificarmos o FIT no servidor).
  route         geometry(LineString, 4326)
);

CREATE INDEX IF NOT EXISTS idx_uploads_received_at ON uploads (received_at DESC);
