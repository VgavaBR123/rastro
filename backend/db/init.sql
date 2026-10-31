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
  -- Fica NULL quando a decodificacao falha ou ha menos de 2 pontos.
  route         geometry(LineString, 4326),
  -- Quantidade de pontos com posicao valida lidos do FIT (NULL se nao deu).
  point_count   INTEGER
);

-- Para bancos criados antes destas colunas existirem.
ALTER TABLE uploads ADD COLUMN IF NOT EXISTS route geometry(LineString, 4326);
ALTER TABLE uploads ADD COLUMN IF NOT EXISTS point_count INTEGER;

CREATE INDEX IF NOT EXISTS idx_uploads_received_at ON uploads (received_at DESC);

-- Contas. email ja chega normalizado (trim + lowercase). password_hash no
-- formato pbkdf2_sha256$<iter>$<salt_b64>$<hash_b64>.
CREATE TABLE IF NOT EXISTS users (
  id            TEXT PRIMARY KEY,
  email         TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  display_name  TEXT NOT NULL,
  created_at    BIGINT NOT NULL
);

-- Sessoes. Guarda so o sha256 do token (nunca o token em claro).
CREATE TABLE IF NOT EXISTS sessions (
  token_hash TEXT PRIMARY KEY,
  user_id    TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at BIGINT NOT NULL,
  expires_at BIGINT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions (user_id);

-- Dono do upload. Uploads anteriores as contas ficam NULL (invisiveis pela API).
-- ON DELETE CASCADE: excluir a conta (DELETE /me) leva os uploads junto.
ALTER TABLE uploads ADD COLUMN IF NOT EXISTS user_id TEXT NULL
  REFERENCES users(id) ON DELETE CASCADE;

-- Uma atividade de um usuario = um upload (reenvio devolve o existente).
-- Parcial porque uploads sem guid continuam aceitos. Substitui o indice antigo
-- so por activity_guid. O servidor tambem aplica isto ao conectar.
DROP INDEX IF EXISTS uq_uploads_activity_guid;
CREATE UNIQUE INDEX IF NOT EXISTS uq_uploads_user_activity_guid
  ON uploads (user_id, activity_guid) WHERE activity_guid IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_uploads_user_received
  ON uploads (user_id, received_at DESC);

-- Metadados da atividade: informados pelo app nos headers do upload
-- (x-activity-type, x-start-time, x-timer-time-ms, x-distance-meters) ou
-- derivados dos timestamps dos records do FIT (start_time, elapsed_time_ms).
-- name e o nome dado pelo usuario (PATCH /activities/<id>).
ALTER TABLE uploads ADD COLUMN IF NOT EXISTS activity_type TEXT NULL;
ALTER TABLE uploads ADD COLUMN IF NOT EXISTS name TEXT NULL;
ALTER TABLE uploads ADD COLUMN IF NOT EXISTS start_time BIGINT NULL;
ALTER TABLE uploads ADD COLUMN IF NOT EXISTS elapsed_time_ms BIGINT NULL;
ALTER TABLE uploads ADD COLUMN IF NOT EXISTS timer_time_ms BIGINT NULL;
ALTER TABLE uploads ADD COLUMN IF NOT EXISTS distance_meters DOUBLE PRECISION NULL;
-- Fechamento gentil (F04): esforco percebido (1 a 10) e humor.
ALTER TABLE uploads ADD COLUMN IF NOT EXISTS rpe SMALLINT NULL;
ALTER TABLE uploads ADD COLUMN IF NOT EXISTS mood TEXT NULL;

-- Paginacao por keyset de GET /activities: startTime (senao receivedAt) desc,
-- desempate por id desc (collation "C" para a ordem ser por bytes).
CREATE INDEX IF NOT EXISTS idx_uploads_user_sort ON uploads
  (user_id, (COALESCE(start_time, received_at)) DESC, id COLLATE "C" DESC);

-- Recuperacao de senha: um pedido por usuario (pedido novo substitui o
-- anterior). Guarda so o hash PBKDF2 do codigo, nunca o codigo em claro.
CREATE TABLE IF NOT EXISTS password_resets (
  user_id    TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  code_hash  TEXT NOT NULL,
  created_at BIGINT NOT NULL,
  expires_at BIGINT NOT NULL,
  attempts   INTEGER NOT NULL DEFAULT 0
);

-- Rastro Seguro (F08). Mesmo DDL de safetySchemaSql em
-- lib/src/safety/postgres_safety_store.dart (aplicado tambem ao conectar).
-- Contatos de confianca: owner_id convidou contact_user_id.
CREATE TABLE IF NOT EXISTS safety_contacts (
  id              TEXT PRIMARY KEY,
  owner_id        TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  contact_user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status          TEXT NOT NULL CHECK (status IN ('pending', 'accepted')),
  created_at      BIGINT NOT NULL,
  accepted_at     BIGINT NULL,
  UNIQUE (owner_id, contact_user_id)
);
CREATE INDEX IF NOT EXISTS idx_safety_contacts_contact
  ON safety_contacts (contact_user_id);

-- Sessoes. Sem historico de trajeto: so a ultima posicao e desde quando as
-- amostras vem paradas (still_since). Apagadas 24 h depois do fim.
CREATE TABLE IF NOT EXISTS safety_sessions (
  id                TEXT PRIMARY KEY,
  owner_id          TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  activity_guid     TEXT NOT NULL,
  status            TEXT NOT NULL CHECK (status IN ('active', 'checking', 'alerted', 'ended')),
  eta_ms            BIGINT NOT NULL,
  started_at        BIGINT NOT NULL,
  ended_at          BIGINT NULL,
  end_reason        TEXT NULL,
  last_signal_at    BIGINT NOT NULL,
  last_lat          DOUBLE PRECISION NULL,
  last_lon          DOUBLE PRECISION NULL,
  last_accuracy_m   DOUBLE PRECISION NULL,
  last_recorded_at  BIGINT NULL,
  still_since       BIGINT NULL,
  contact_ids       JSONB NOT NULL DEFAULT '[]'::jsonb,
  check_reason      TEXT NULL,
  check_started_at  BIGINT NULL,
  check_deadline    BIGINT NULL,
  alerted_at        BIGINT NULL,
  eta_recheck_after BIGINT NULL,
  share_token       TEXT NOT NULL UNIQUE,
  share_expires_at  BIGINT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_safety_sessions_owner_open
  ON safety_sessions (owner_id) WHERE status <> 'ended';
CREATE INDEX IF NOT EXISTS idx_safety_sessions_ended
  ON safety_sessions (ended_at) WHERE status = 'ended';

-- Caixa de entrada de notificacoes.
CREATE TABLE IF NOT EXISTS notifications (
  id         TEXT PRIMARY KEY,
  user_id    TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type       TEXT NOT NULL,
  title      TEXT NOT NULL,
  body       TEXT NOT NULL,
  data       JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at BIGINT NOT NULL,
  read_at    BIGINT NULL
);
CREATE INDEX IF NOT EXISTS idx_notifications_user_created
  ON notifications (user_id, created_at DESC, id DESC);

-- Tokens de push (FCM). Um token pertence a uma conta por vez.
CREATE TABLE IF NOT EXISTS push_tokens (
  token      TEXT PRIMARY KEY,
  user_id    TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  platform   TEXT NOT NULL CHECK (platform IN ('android', 'ios')),
  updated_at BIGINT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_push_tokens_user ON push_tokens (user_id);
