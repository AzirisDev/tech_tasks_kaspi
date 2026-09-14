--  DevOps Test - Section 1.2: 10 analytical SQL queries

-- Query 1: All users together with their ACTIVE servers.
-- Output: username, email, server names.
-- INNER JOIN drops users with no active server; use LEFT JOIN if you
-- also want serverless users. Uses idx_servers_created_by.
-- ---------------------------------------------------------------------
SELECT u.username,
       u.email,
       s.name AS server_name
FROM   users   u
JOIN   servers s ON s.created_by = u.id
WHERE  s.status = 'active'
ORDER  BY u.username, s.name;


-- ---------------------------------------------------------------------
-- Query 2: Servers with no deployment in the last 30 days
--          (including servers that were never deployed).
-- Output: id, name, last deployment date (NULL if none).
-- LEFT JOIN + GROUP BY gets the max deployed_at per server; the HAVING
-- keeps servers whose latest deploy is old OR absent.
-- ---------------------------------------------------------------------
SELECT s.id,
       s.name,
       MAX(d.deployed_at) AS last_deployed_at
FROM   servers s
LEFT   JOIN deployments d ON d.server_id = s.id
GROUP  BY s.id, s.name
HAVING MAX(d.deployed_at) < now() - INTERVAL '30 days'
    OR MAX(d.deployed_at) IS NULL
ORDER  BY last_deployed_at NULLS FIRST;


-- ---------------------------------------------------------------------
-- Query 3: Count of SUCCESSFUL deployments per application version.
-- Output: app_version, successful_count, sorted descending.
-- Filtering on status='success' lets idx_deployments_status_version
-- serve the aggregation.
-- ---------------------------------------------------------------------
SELECT app_version,
       COUNT(*) AS successful_deployments
FROM   deployments
WHERE  status = 'success'
GROUP  BY app_version
ORDER  BY successful_deployments DESC;


-- ---------------------------------------------------------------------
-- Query 4: Users who created more than 5 servers.
-- Output: id, username, server_count.
-- HAVING filters on the aggregate; INNER JOIN because a user with
-- zero servers can never exceed 5.
-- ---------------------------------------------------------------------
SELECT u.id,
       u.username,
       COUNT(s.id) AS server_count
FROM   users   u
JOIN   servers s ON s.created_by = u.id
GROUP  BY u.id, u.username
HAVING COUNT(s.id) > 5
ORDER  BY server_count DESC;


-- ---------------------------------------------------------------------
-- Query 5: ERROR logs from the last 24 hours, with server info.
-- Output: server name, message, timestamp, newest first.
-- The partial index idx_logs_error_only covers exactly this filter.
-- ---------------------------------------------------------------------
SELECT s.name AS server_name,
       l.message,
       l."timestamp"
FROM   logs    l
JOIN   servers s ON s.id = l.server_id
WHERE  l.level = 'ERROR'
  AND  l."timestamp" >= now() - INTERVAL '24 hours'
ORDER  BY l."timestamp" DESC;


-- ---------------------------------------------------------------------
-- Query 6: Average interval (in days) between consecutive deployments
--          for each server.
-- Output: server_id, avg_interval_days rounded to 2 decimals.
-- Window function LAG() gets the previous deploy time per server;
-- the outer query averages the gaps. Servers with a single deploy
-- have no gap and are excluded by the NULL interval.
-- ---------------------------------------------------------------------
WITH gaps AS (
    SELECT server_id,
           deployed_at,
           deployed_at - LAG(deployed_at) OVER (
               PARTITION BY server_id
               ORDER BY deployed_at
           ) AS gap
    FROM   deployments
)
SELECT server_id,
       ROUND(AVG(EXTRACT(EPOCH FROM gap) / 86400)::numeric, 2) AS avg_interval_days
FROM   gaps
WHERE  gap IS NOT NULL
GROUP  BY server_id
ORDER  BY avg_interval_days;


-- ---------------------------------------------------------------------
-- Query 7: Top-3 regions by number of servers.
-- Output: region, server_count.
-- idx_servers_region assists the grouping; LIMIT 3 after ordering.
-- ---------------------------------------------------------------------
SELECT region,
       COUNT(*) AS server_count
FROM   servers
GROUP  BY region
ORDER  BY server_count DESC
LIMIT  3;


-- ---------------------------------------------------------------------
-- Query 8: Users who have not created a server in more than 60 days
--          (or never created one).
-- Output: id, username, last server-creation date.
-- LEFT JOIN keeps users with no servers (last date = NULL).
-- ---------------------------------------------------------------------
SELECT u.id,
       u.username,
       MAX(s.created_at) AS last_server_created_at
FROM   users   u
LEFT   JOIN servers s ON s.created_by = u.id
GROUP  BY u.id, u.username
HAVING MAX(s.created_at) < now() - INTERVAL '60 days'
    OR MAX(s.created_at) IS NULL
ORDER  BY last_server_created_at NULLS FIRST;


-- ---------------------------------------------------------------------
-- Query 9: Success rate (%) of deployments per server.
-- Output: server_id, success_percent (0-100), total_deployments.
-- FILTER isolates the success count without a second scan; the
-- 100.0 multiplier forces float division.
-- ---------------------------------------------------------------------
SELECT server_id,
       ROUND(
           100.0 * COUNT(*) FILTER (WHERE status = 'success') / COUNT(*),
           2
       ) AS success_percent,
       COUNT(*) AS total_deployments
FROM   deployments
GROUP  BY server_id
ORDER  BY success_percent DESC, total_deployments DESC;


-- ---------------------------------------------------------------------
-- Query 10: Deployments that produced ERROR-level logs.
-- Output: deployment_id, server_name, error_count, last error message.
-- We join logs -> deployments -> servers, restrict to ERROR, and use
-- a window/aggregate to grab the most recent error text per deployment.
-- DISTINCT ON keeps one row per deployment (the latest error).
-- ---------------------------------------------------------------------
SELECT DISTINCT ON (l.deployment_id)
       l.deployment_id,
       s.name                                   AS server_name,
       COUNT(*) OVER (PARTITION BY l.deployment_id) AS error_count,
       l.message                                AS last_error_message
FROM   logs    l
JOIN   deployments d ON d.id = l.deployment_id
JOIN   servers     s ON s.id = l.server_id
WHERE  l.level = 'ERROR'
ORDER  BY l.deployment_id, l."timestamp" DESC;
