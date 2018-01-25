# authorizer

Download authority records matched to bib auth heading subfield $0.

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

To try things out in an IRB session:

```
bundle exec sequel sqlite://db/authorizer.db -L app/models/
```

## Loading data

```bash
bundle exec rake authorizer:db:populate_from_file # requires data/bib/authorizer.mrc
bundle exec rake authorizer:authorities:download:batch
bundle exec rake authorizer:db:generate_stub_records
bundle exec rake authorizer:authorities:validate_loc_headings
bundle exec rake authorizer:db:dump_auth_xml['loc']
bundle exec rake authorizer:db:dump_auth_xml['aat']
bundle exec rake authorizer:db:dump_auth_xml['dts']
bundle exec rake authorizer:authorities:summary
```

## Other tasks

```bash
bundle exec rake authorizer:authorities:download:single[http://vocab.getty.edu/aat/300028689,AAT] | xmllint --format -
bundle exec rake authorizer:authorities:search_name['Obama\, Barack']
bundle exec rake authorizer:authorities:search_subject['Cyberpunk fiction']
```

## Preparing dumped authorities for import

For use with [aspace-importer](https://github.com/lyrasis/aspace-importer.git):

```bash
mkdir -p /tmp/aspace/import
for file in ./data/auth/loc/*/*.xml; do cp "$file" /tmp/aspace/import/; done

# removing
for file in /tmp/aspace/import/*.xml; do rm "$file"; done
for file in /tmp/aspace/json/*.json; do rm "$file"; done
```

There's a helper for testing with ArchivesSpace:

```bash
./archivesspace.sh
```

Note: requires Docker and MySQL CLI tools.

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
