# authorizer

Match bib record auth headings to auth record using LD dumps.

## Getting started

```
mkdir -p data/auth
mkdir -p data/bib
mkdir -p data/ld
```

Download linked data in ntriples format (for example from the [LOC](http://id.loc.gov/download/)) and copy it to `data/ld `.

Start Blazegraph and import the data:

```bash
# start container making files available under /data
docker run --name blazegraph -d \
  -e JAVA_OPTIONS='-server -Xmx8G -XX:+UseParallelOldGC' \
  -p 8889:8080 \
  -v $PWD/RWStore.properties:/RWStore.properties \
  -v $PWD/data/ld:/data \
  lyrasis/blazegraph:2.1.4

# trigger data import
curl -X POST \
  --data-binary @dataloader.txt \
  --header 'Content-Type:text/plain' \
  http://localhost:8889/bigdata/dataloader
```

Perform a sample query to test the import:

```sparql
# http://localhost:8889/bigdata/#query
prefix bds: <http://www.bigdata.com/rdf/search#>
select ?identifier ?value
where {
  ?value bds:search "Women" .
  ?value bds:matchAllTerms "true" .
  ?identifier <http://www.loc.gov/mads/rdf/v1#authoritativeLabel> ?value .
}
```

---