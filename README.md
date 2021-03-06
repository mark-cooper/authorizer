# authorizer

Download authority records matched to bib auth heading subfield $0.

## Getting started

Create input / out directories:

```bash
mkdir -p data/auth
mkdir -p data/bib # copy mrc record/s here
./reset.sh

echo "Running database migrations"
bundle exec sequel -m db/migrations -M 0 'sqlite://db/authorizer.db'
bundle exec sequel -m db/migrations 'sqlite://db/authorizer.db'
# to try things out in an IRB session
bundle exec sequel sqlite://db/authorizer.db -L app/models/
```

## Loading data

```bash
bundle exec rake authorizer:db:populate_from_file # requires data/bib/authorizer.mrc
bundle exec rake authorizer:authorities:download:batch
bundle exec rake authorizer:db:generate_aat_records
bundle exec rake authorizer:db:generate_stub_records
bundle exec rake authorizer:authorities:undifferentiated
bundle exec rake authorizer:authorities:validate_loc_headings
bundle exec rake authorizer:authorities:update_identifier_to_uri
bundle exec rake authorizer:db:dump_auth_xml['loc']
bundle exec rake authorizer:db:dump_auth_xml['aat']
bundle exec rake authorizer:db:dump_auth_xml['dts']
bundle exec rake authorizer:authorities:summary
# map.csv: SELECT TRIM(string_2) as bib_number, accession_id, resource_id FROM user_defined WHERE string_2 IS NOT NULL;
bundle exec rake authorizer:authorities:as_sql
bundle exec rake authorizer:authorities:as_koch_sql
```

## Other tasks

```bash
bundle exec rake authorizer:authorities:undifferentiated
bundle exec rake authorizer:authorities:download:single[http://vocab.getty.edu/aat/300028689,AAT] | xmllint --format -
bundle exec rake authorizer:authorities:search_name['Obama\, Barack']
bundle exec rake authorizer:authorities:search_subject['Cyberpunk fiction']
```

## Preparing dumped authorities for import

For use with [aspace-importer](https://github.com/lyrasis/aspace-importer.git):

```bash
mkdir -p /tmp/aspace/import
mkdir -p /tmp/aspace/json
for file in ./data/auth/loc/*.xml; do cp "$file" /tmp/aspace/import/; done
for file in ./data/auth/dts/*.xml; do cp "$file" /tmp/aspace/import/; done
for file in ./data/auth/aat/*.xml; do cp "$file" /tmp/aspace/import/; done

ls /tmp/aspace/import/ | wc -l

# for rsync
./upload.sh loc mcooper yale-staging 922 /tmp/aspace/import
./upload.sh dts mcooper yale-staging 922 /tmp/aspace/import

# removing
for file in /tmp/aspace/import/*.xml; do rm "$file"; done
for file in /tmp/aspace/json/*.json; do rm "$file"; done
```

There's a helper for testing with ArchivesSpace:

```bash
./archivesspace.sh
```

Note: requires Docker and MySQL CLI tools.

From source:

```bash
cd /path/to/archivesspace
git checkout 2.2.0_marcxml_backport
./build/run bootstrap
# run db prep, check config.rb
supervisord -c supervisord/backend.conf
```

After import run the authorizer SQL:

```bash
# loading authorizer.sql ()
mysql --verbose -h 127.0.0.1 -u as -pas123 archivesspace < koch.sql
mysql --verbose -h 127.0.0.1 -u as -pas123 archivesspace < authorizer.sql
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
  b.title,
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

Some counts:

```sql
SELECT COUNT(*) FROM auths WHERE uri IS NOT NULL;
SELECT COUNT(DISTINCT(uri)) FROM auths WHERE uri IS NOT NULL;
SELECT COUNT(DISTINCT(uri)) FROM auths WHERE uri IS NOT NULL and record IS NOT NULL;
SELECT * FROM auths WHERE uri IS NOT NULL and record IS NULL;
```

---
