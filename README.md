# authorizer

Match bib record auth headings to auth record using LD dumps.

## Getting started

```
mkdir -p data/auth
mkdir -p data/bib
```

## Tasks

```
rake authorizer:authorities:search_name['Obama\, Barack']
rake authorizer:authorities:search_subject['Cyberpunk fiction']
```

---