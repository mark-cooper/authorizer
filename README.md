# authorizer

Match bib record auth headings to auth record using LD dumps.

## Getting started

Create input / out directories:

```bash
mkdir -p data/auth
mkdir -p data/bib # copy mrc record/s here
```

Install the required gems:

```
bundle install
```

Run the schema migrations:

```bash
bundle exec sequel -m db/migrations 'sqlite://db/authorizer.db'
```

To reset the migrations (then re-run the migration command):

```
bundle exec sequel -m db/migrations -M 0 'sqlite://db/authorizer.db'
```

## Loading data

```bash
rake authorizer:db:populate_from_file
rake authorizer:authorities:lookup
```

## Tasks

```bash
rake authorizer:authorities:search_name['Obama\, Barack']
rake authorizer:authorities:search_subject['Cyberpunk fiction']
```

## Queries

Auths only:

```sql
SELECT
  a.tag,
  a.datafield,
  a.heading,
  a.type,
  a.source,
  a.query,
  a.uri,
  a.ils
FROM authorizer.auths a
ORDER BY a.tag, a.source, a.heading
;
```

By bib:

```sql
SELECT
  b.bib_number,
  a.tag,
  a.datafield,
  a.heading,
  a.type,
  a.source,
  a.query,
  a.uri,
  a.ils
FROM authorizer.auths a
JOIN authorizer.auths_bibs ab
ON a.id = ab.auth_id
JOIN authorizer.bibs  b
ON b.id = ab.bib_id
ORDER BY b.bib_number, a.tag, a.source, a.heading
;
```

---
