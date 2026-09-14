--  DevOps Test - Section 1.1: Test data

-- ---------- users (12 rows) ----------
INSERT INTO users (username, email, created_at, status) VALUES
    ('alice',   'alice@example.com',   now() - INTERVAL '200 days', 'active'),
    ('bob',     'bob@example.com',     now() - INTERVAL '180 days', 'active'),
    ('charlie', 'charlie@example.com', now() - INTERVAL '150 days', 'active'),
    ('diana',   'diana@example.com',   now() - INTERVAL '120 days', 'inactive'),
    ('erin',    'erin@example.com',    now() - INTERVAL '100 days', 'active'),
    ('frank',   'frank@example.com',   now() - INTERVAL '90 days',  'suspended'),
    ('grace',   'grace@example.com',   now() - INTERVAL '80 days',  'active'),
    ('heidi',   'heidi@example.com',   now() - INTERVAL '70 days',  'active'),
    ('ivan',    'ivan@example.com',    now() - INTERVAL '60 days',  'active'),
    ('judy',    'judy@example.com',    now() - INTERVAL '40 days',  'active'),
    ('mallory', 'mallory@example.com', now() - INTERVAL '30 days',  'inactive'),
    ('oscar',   'oscar@example.com',   now() - INTERVAL '10 days',  'active');

-- ---------- servers (15 rows) ----------
-- alice (id 1) intentionally owns 6 servers -> satisfies "more than 5" query.
-- diana (id 4) created her only server long ago -> "no server in 60+ days".
INSERT INTO servers (name, ip_address, region, created_by, created_at, status) VALUES
    ('web-01',   '10.0.1.11',  'us-east-1',      1, now() - INTERVAL '190 days', 'active'),
    ('web-02',   '10.0.1.12',  'us-east-1',      1, now() - INTERVAL '185 days', 'active'),
    ('db-01',    '10.0.2.11',  'us-east-1',      1, now() - INTERVAL '150 days', 'active'),
    ('cache-01', '10.0.2.12',  'eu-west-1',      1, now() - INTERVAL '120 days', 'active'),
    ('web-03',   '10.0.1.13',  'eu-west-1',      1, now() - INTERVAL '90 days',  'maintenance'),
    ('batch-01', '10.0.3.11',  'eu-west-1',      1, now() - INTERVAL '5 days',   'active'),
    ('web-04',   '10.0.1.14',  'ap-south-1',     2, now() - INTERVAL '160 days', 'active'),
    ('db-02',    '10.0.2.13',  'ap-south-1',     2, now() - INTERVAL '80 days',  'active'),
    ('idle-01',  '10.0.4.11',  'us-west-2',      3, now() - INTERVAL '70 days',  'active'),
    ('old-01',   '10.0.4.12',  'us-west-2',      4, now() - INTERVAL '110 days', 'active'),
    ('web-05',   '10.0.1.15',  'us-east-1',      5, now() - INTERVAL '50 days',  'active'),
    ('web-06',   '10.0.1.16',  'eu-west-1',      7, now() - INTERVAL '20 days',  'active'),
    ('db-03',    '10.0.2.14',  'ap-south-1',     8, now() - INTERVAL '15 days',  'active'),
    ('cache-02', '10.0.2.15',  'us-east-1',      9, now() - INTERVAL '12 days',  'active'),
    ('web-07',   '10.0.1.17',  'us-west-2',     10, now() - INTERVAL '3 days',   'active');

-- ---------- deployments (20 rows) ----------
-- idle-01 (server 9) & old-01 (10) have NO recent deployments -> "idle > 30 days".
-- Mixed success/failed across versions for the aggregation & success-rate queries.
INSERT INTO deployments (server_id, app_version, deployed_at, status) VALUES
    (1, 'v1.0.0', now() - INTERVAL '40 days', 'success'),
    (1, 'v1.1.0', now() - INTERVAL '20 days', 'success'),
    (1, 'v1.2.0', now() - INTERVAL '2 days',  'success'),
    (2, 'v1.0.0', now() - INTERVAL '35 days', 'failed'),
    (2, 'v1.1.0', now() - INTERVAL '15 days', 'success'),
    (3, 'v1.0.0', now() - INTERVAL '50 days', 'success'),
    (3, 'v1.2.0', now() - INTERVAL '1 day',   'failed'),
    (4, 'v1.1.0', now() - INTERVAL '10 days', 'success'),
    (5, 'v1.0.0', now() - INTERVAL '60 days', 'success'),
    (6, 'v1.2.0', now() - INTERVAL '3 days',  'in_progress'),
    (7, 'v1.0.0', now() - INTERVAL '45 days', 'success'),
    (7, 'v1.1.0', now() - INTERVAL '25 days', 'success'),
    (7, 'v1.2.0', now() - INTERVAL '5 days',  'success'),
    (8, 'v1.1.0', now() - INTERVAL '12 days', 'rolled_back'),
    (9, 'v1.0.0', now() - INTERVAL '65 days', 'success'),  
    (10,'v1.0.0', now() - INTERVAL '90 days', 'success'), 
    (11,'v1.2.0', now() - INTERVAL '4 days',  'success'),
    (12,'v1.2.0', now() - INTERVAL '6 days',  'failed'),
    (13,'v1.1.0', now() - INTERVAL '8 days',  'success'),
    (14,'v1.2.0', now() - INTERVAL '1 day',   'success');

-- ---------- logs (22 rows) ----------
-- Several ERROR rows inside the last 24h for the "recent errors" query,
-- tied to deployments for the "deployments with critical errors" query.
INSERT INTO logs (server_id, deployment_id, message, level, timestamp) VALUES
    (1,  3,  'Deployment v1.2.0 completed',              'INFO',  now() - INTERVAL '2 days'),
    (2,  4,  'Connection pool exhausted',                'ERROR', now() - INTERVAL '2 hours'),
    (2,  4,  'Retrying database connection',             'WARN',  now() - INTERVAL '2 hours'),
    (3,  7,  'Migration failed: relation missing',       'ERROR', now() - INTERVAL '1 hour'),
    (3,  7,  'Rolling back schema change',               'ERROR', now() - INTERVAL '55 minutes'),
    (5,  9,  'Healthcheck passed',                       'INFO',  now() - INTERVAL '30 days'),
    (6,  10, 'Build artifact uploaded',                  'INFO',  now() - INTERVAL '3 days'),
    (7,  13, 'Deploy succeeded',                         'INFO',  now() - INTERVAL '5 days'),
    (8,  14, 'Rollback triggered by failed healthcheck', 'ERROR', now() - INTERVAL '12 days'),
    (11, 17, 'Cache warmed',                             'INFO',  now() - INTERVAL '4 days'),
    (12, 18, 'OOMKilled: worker process',                'ERROR', now() - INTERVAL '90 minutes'),
    (12, 18, 'Restarting container',                     'WARN',  now() - INTERVAL '88 minutes'),
    (13, 19, 'DB replica in sync',                       'INFO',  now() - INTERVAL '8 days'),
    (14, 20, 'Static assets served',                     'DEBUG', now() - INTERVAL '1 day'),
    (1,  NULL,'Nightly backup completed',                'INFO',  now() - INTERVAL '12 hours'),
    (1,  NULL,'Disk usage at 82%',                       'WARN',  now() - INTERVAL '6 hours'),
    (4,  8,  'Timeout talking to upstream',              'ERROR', now() - INTERVAL '20 hours'),
    (7,  12, 'Slow query detected (>2s)',                'WARN',  now() - INTERVAL '10 days'),
    (9,  15, 'Server idle, no traffic',                  'INFO',  now() - INTERVAL '65 days'),
    (2,  5,  'Recovered after retry',                    'INFO',  now() - INTERVAL '15 days'),
    (12, 18, 'Second OOM in an hour',                    'ERROR', now() - INTERVAL '20 minutes'),
    (3,  7,  'Alert paged on-call',                      'ERROR', now() - INTERVAL '40 minutes');

-- Refresh planner statistics so EXPLAIN ANALYZE reflects the seeded data.
ANALYZE;
