--  DevOps Test - Section 1.1: Database schema
--  Target: PostgreSQL 14 on Ubuntu 22.04
--  Database: devops_test

DROP TABLE IF EXISTS logs, deployments, servers, users CASCADE;
DROP TYPE  IF EXISTS user_status, server_status, deployment_status, log_level CASCADE;

CREATE TYPE user_status        AS ENUM ('active', 'inactive', 'suspended');
CREATE TYPE server_status      AS ENUM ('active', 'maintenance', 'decommissioned');
CREATE TYPE deployment_status  AS ENUM ('success', 'failed', 'in_progress', 'rolled_back');
CREATE TYPE log_level          AS ENUM ('DEBUG', 'INFO', 'WARN', 'ERROR');

-- users
CREATE TABLE users (
    id          BIGINT       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username    VARCHAR(50)  NOT NULL UNIQUE,
    email       VARCHAR(255) NOT NULL UNIQUE,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    status      user_status  NOT NULL DEFAULT 'active'
);

-- servers  (created_by -> users.id)
CREATE TABLE servers (
    id          BIGINT        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR(100)  NOT NULL,
    ip_address  INET          NOT NULL,
    region      VARCHAR(50)   NOT NULL,
    created_by  BIGINT        NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    created_at  TIMESTAMPTZ   NOT NULL DEFAULT now(),
    status      server_status NOT NULL DEFAULT 'active'
);

-- deployments  (server_id -> servers.id)
CREATE TABLE deployments (
    id           BIGINT            GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    server_id    BIGINT            NOT NULL REFERENCES servers(id) ON DELETE CASCADE,
    app_version  VARCHAR(20)       NOT NULL,
    deployed_at  TIMESTAMPTZ       NOT NULL DEFAULT now(),
    status       deployment_status NOT NULL DEFAULT 'in_progress'
);

-- logs  (server_id -> servers.id, deployment_id -> deployments.id)
-- deployment_id is nullable: not every log line belongs to a deployment.
CREATE TABLE logs (
    id             BIGINT      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    server_id      BIGINT      NOT NULL REFERENCES servers(id) ON DELETE CASCADE,
    deployment_id  BIGINT      REFERENCES deployments(id) ON DELETE SET NULL,
    message        TEXT        NOT NULL,
    level          log_level   NOT NULL DEFAULT 'INFO',
    timestamp      TIMESTAMPTZ NOT NULL DEFAULT now()
);

--  Indexes — chosen to match the query patterns in queries.sql

-- FK lookups (Postgres does NOT auto-index FK columns)
CREATE INDEX idx_servers_created_by       ON servers(created_by);
CREATE INDEX idx_deployments_server_id    ON deployments(server_id);
CREATE INDEX idx_logs_server_id           ON logs(server_id);
CREATE INDEX idx_logs_deployment_id       ON logs(deployment_id);

-- Range / filter columns used in WHERE and ORDER BY
CREATE INDEX idx_deployments_deployed_at  ON deployments(deployed_at DESC);
CREATE INDEX idx_logs_timestamp           ON logs("timestamp" DESC);
CREATE INDEX idx_servers_region           ON servers(region);
CREATE INDEX idx_servers_created_at       ON servers(created_at DESC);

-- Partial index: error-log queries only ever look at ERROR rows,
-- so indexing just those keeps the index tiny and fast.
CREATE INDEX idx_logs_error_only
    ON logs("timestamp" DESC)
    WHERE level = 'ERROR';

-- Composite index for "successful deployments by version" aggregation
CREATE INDEX idx_deployments_status_version
    ON deployments(status, app_version);

COMMENT ON TABLE users       IS 'Platform users who own servers';
COMMENT ON TABLE servers     IS 'Managed servers, each created by a user';
COMMENT ON TABLE deployments IS 'Application deployments performed on servers';
COMMENT ON TABLE logs        IS 'Log lines emitted by servers, optionally tied to a deployment';
