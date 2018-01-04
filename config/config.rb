AppConfig[:plugins] << 'aspace-importer'

AppConfig[:importer] = {
  batch: {
    create_enums: true,
    enabled: true,
    repository: {
      repo_code: 'TEST',
    },
    username: 'admin',
  },
  import: {
    converter: "MarcXMLConverter",
    type: "marcxml_subjects_and_agents",
    directory: "/tmp/aspace/import",
    error_file: "/tmp/aspace/import/importer.err",
  },
  json: {
    directory: "/tmp/aspace/json",
    error_file: "/tmp/aspace/json/importer.err",
  },
  schedule: nil,
  threads: 2,
  verbose: true,
}
