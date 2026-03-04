-- TaskStack Cloud Schema
-- Run: psql "$DATABASE_URL" -f schema.sql

-- Enable pgcrypto for gen_random_bytes / gen_random_uuid
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ── Users ────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  username      TEXT        UNIQUE NOT NULL,
  email         TEXT        UNIQUE NOT NULL,
  password_hash TEXT        NOT NULL,
  display_name  TEXT,
  bio           TEXT,
  avatar_url    TEXT,
  is_public     BOOLEAN     NOT NULL DEFAULT false,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── Groups ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS groups (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT        NOT NULL,
  description TEXT,
  created_by  UUID        REFERENCES users(id) ON DELETE SET NULL,
  -- 12-hex-char invite code — used for QR and manual entry
  invite_code TEXT        UNIQUE NOT NULL DEFAULT encode(gen_random_bytes(6), 'hex'),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── Group Members ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS group_members (
  group_id   UUID        NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  user_id    UUID        NOT NULL REFERENCES users(id)  ON DELETE CASCADE,
  role       TEXT        NOT NULL DEFAULT 'member', -- 'owner' | 'member'
  joined_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (group_id, user_id)
);

-- ── Group Invites ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS group_invites (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id         UUID        NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  invited_by       UUID        NOT NULL REFERENCES users(id)  ON DELETE CASCADE,
  invited_user_id  UUID        NOT NULL REFERENCES users(id)  ON DELETE CASCADE,
  status           TEXT        NOT NULL DEFAULT 'pending', -- 'pending'|'accepted'|'rejected'
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (group_id, invited_user_id)  -- no duplicate invites to same group
);

-- ── Indexes ───────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_group_members_user  ON group_members(user_id);
CREATE INDEX IF NOT EXISTS idx_group_invites_user  ON group_invites(invited_user_id);
CREATE INDEX IF NOT EXISTS idx_group_invites_group ON group_invites(group_id);
