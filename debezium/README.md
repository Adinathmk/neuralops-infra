# Debezium Outbox CDC Connectors

Two connectors, one per database, implementing the transactional outbox
pattern via Debezium's Outbox Event Router SMT. Each watches the `outbox`
table (written to by `write_outbox()` in django and fastapi respectively)
and republishes each row to the Kafka topic named in that row's `topic`
column - e.g. a row with `topic="incidents.created"` gets published to
the `incidents.created` Kafka topic directly (no prefix), matching what
existing consumers (e.g. `consume_incidents.py`) already expect.

## Prerequisites (one-time, per RDS instance)

1. RDS instance must have `rds.logical_replication = 1` set via a custom
   parameter group (see `terraform/platform/rds.tf` -
   `aws_db_parameter_group.postgres_logical_replication`), and the
   instance must be **rebooted** after attaching the group (this is a
   static parameter).
2. Grant replication to the app's DB user:
   `GRANT rds_replication TO <django_admin|fastapi_admin>;`
3. Create the publication:
   `CREATE PUBLICATION outbox_publication FOR TABLE outbox;`

## Registering a connector

These configs contain a placeholder for `database.password` - fetch the
real value from Secrets Manager first:

```bash
aws secretsmanager get-secret-value --secret-id neuralops/django \
  --region ap-south-1 --query SecretString --output text | \
  python3 -c "import sys,json; print(json.load(sys.stdin)['DATABASE_URL'].split(':')[2].split('@')[0])"
```

Substitute that value into `database.password`, then:

```bash
kubectl cp debezium/connectors/django-outbox-connector.json \
  data/<debezium-pod>:/tmp/django-outbox-connector.json

kubectl exec -n data <debezium-pod> -- curl -s -X POST \
  -H "Content-Type: application/json" \
  --data @/tmp/django-outbox-connector.json \
  localhost:8083/connectors
```

Repeat for `fastapi-outbox-connector.json`.

## Verifying

```bash
kubectl exec -n data <debezium-pod> -- curl -s \
  localhost:8083/connectors/django-outbox-connector/status
```

Should show `"state": "RUNNING"` for both the connector and its task.

## Known limitations (not yet addressed)

- **Not GitOps-automated.** These connectors are registered manually via
  the REST API and live only in Kafka Connect's internal config topic -
  there is no reconciliation loop that re-applies them if the Connect
  worker is ever recreated from scratch. A future improvement would be
  a Strimzi `KafkaConnector` custom resource per connector, which IS
  GitOps-native and would close this gap.
- **No config provider for secrets.** `database.password` is stored in
  plaintext inside Kafka Connect's internal config topic, and is
  visible in any `GET`/`POST`/`PUT` response against the REST API. A
  proper fix is a `ConfigProvider` (e.g. backed by a mounted k8s Secret)
  so the connector config can reference `${file:...}` instead of a raw
  value. Deferred - acceptable for a portfolio-scale project, but flag
  before ever exposing this Connect REST API publicly.
- **`published` column on `outbox` table is never actually set.**
  Debezium reads the WAL directly and does not write back to Postgres -
  this column appears to be a vestigial field from an earlier design
  assumption. Harmless, just always `false`.
- **`indexing.status` topic doesn't exist yet** - the outbox pattern is
  fully wired for `incidents.*` events (confirmed working end-to-end),
  but nothing currently writes an outbox row with
  `topic="indexing.status"`, so `consume_indexing_status` in
  django-kafka-consumer will keep logging
  `indexing_status_topic_not_ready` until something does.
