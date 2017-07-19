# authorizer

Match bib record auth headings to auth record using LD dumps.

## Getting started

Create input / out directories:

```bash
mkdir -p data/auth
mkdir -p data/bib # copy mrc records here
```

Install the required gems:

```
bundle install
```

Create a MySQL database:

```bash
docker run -d \
  -p 3306:3306 \
  --name mysql \
  -e MYSQL_ROOT_PASSWORD=123456 \
  -e MYSQL_DATABASE=authorizer \
  -e MYSQL_USER=authorizer \
  -e MYSQL_PASSWORD=authorizer \
  mysql:5.7 --innodb_buffer_pool_size=4G --innodb_buffer_pool_instances=4

mysql -h 127.0.0.1 -uroot -p123456 -e \
  'ALTER DATABASE authorizer CHARACTER SET utf8 COLLATE utf8_unicode_ci;'
```

Run the schema migrations:

```bash
bundle exec sequel -m db/migrations \
  "mysql2://127.0.0.1/authorizer?user=authorizer&password=authorizer"
```

To reset the migrations (then re-run the migration command):

```
bundle exec sequel -m db/migrations \
  -M 0 \
  "mysql2://127.0.0.1/authorizer?user=authorizer&password=authorizer"
```

## Loading data

```bash
rake authorizer:db:populate
rake authorizer:authorities:lookup
```

## Tasks

```bash
rake authorizer:authorities:search_name['Obama\, Barack']
rake authorizer:authorities:search_subject['Cyberpunk fiction']
```

## Queries

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