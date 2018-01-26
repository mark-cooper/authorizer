# ArchivesSpace

```sql
-- GATHER user_defined mapping
SELECT 'accession_id' as type, accession_id, string_2 as bib_number
FROM user_defined WHERE accession_id IS NOT NULL and string_2 IS NOT NULL
UNION
SELECT 'resource_id' as type, resource_id, string_2 as bib_number
FROM user_defined WHERE resource_id IS NOT NULL and string_2 IS NOT NULL
;

-- GATHER role map
SELECT ev.value, ev.id FROM enumeration_value ev
JOIN enumeration e ON ev.enumeration_id = e.id
WHERE e.name = 'linked_agent_role';

-- GATHER AGENTS
SELECT 'name_person_id' as type, name_person_id as id, authority_id
FROM archivesspace.name_authority_id
WHERE name_person_id IS NOT NULL AND authority_id IS NOT NULL
UNION
SELECT 'name_family_id' as type, name_family_id as id, authority_id
FROM archivesspace.name_authority_id
WHERE name_family_id IS NOT NULL AND authority_id IS NOT NULL
UNION
SELECT 'name_corporate_entity_id' as type, name_corporate_entity_id as id, authority_id
FROM archivesspace.name_authority_id
WHERE name_corporate_entity_id IS NOT NULL AND authority_id IS NOT NULL
;

-- GATHER SUBJECTS
SELECT id, authority_id FROM archivesspace.subject WHERE authority_id IS NOT NULL;
```

Process cross references for:

- authorizer summary
- user defined map
- agent roles map
- agent authority ids
- subject authority ids

Assemble data grouped by record type for the inserts.

```sql
-- AGENTS
INSERT INTO archivesspace.linked_agents_rlshp (
  accession_id, # resource_id
  agent_person_id, # agent_family_id, agent_corporate_entity_id
  aspace_relationship_position,
  system_mtime,
  created_by,
  last_modified_by,
  create_time,
  user_mtime,
  role_id,
  suppressed
) VALUES (
  1,
  1000,
  0,
  'admin',
  'admin',
  NOW(),
  NOW(),
  NOW(),
  800,
  0
);

-- SUBJECTS
INSERT INTO archivesspace.subject_rlshp (
	accession_id, # resource_id
  subject_id,
  aspace_relationship_position,
  created_by,
  last_modified_by,
  system_mtime,
  user_mtime,
  suppressed
) VALUES (
	1,
  1000,
  0,
  'admin',
  'admin',
  NOW(),
  NOW(),
  0
);
```

Integrated / portable insert query:

```sql
-- ACCESSION AGENT INSERT
INSERT INTO linked_agents_rlshp
SELECT
  udef.accession_id,
  name_agent.agent__AGENT_TYPE__id,
  0,
  'admin',
  'admin',
  NOW(),
  NOW(),
  NOW(),
  ev.value,
  0
FROM user_defined udef
JOIN name__AGENT_TYPE__id name_agent ON name_agent.authority_id = '__IDENTIFIER__'
JOIN enumeration_value ev ON ev.value = '__AGENT_ROLE__'
JOIN enumeration e ON ev.enumeration_id = e.id
WHERE udef.accession_id IS NOT NULL
AND   udef.string_2 IS NOT NULL
AND   udef.string_2 = '__BIB_NUMBER__'
AND   e.name = 'linked_agent_role'
AND   name_agent.id IS NOT NULL;

-- RESOURCE AGENT INSERT
INSERT INTO linked_agents_rlshp
SELECT
  udef.resource_id,
  name_agent.agent__AGENT_TYPE__id,
  0,
  'admin',
  'admin',
  NOW(),
  NOW(),
  NOW(),
  ev.value,
  0
FROM user_defined udef
JOIN name__AGENT_TYPE__id name_agent ON name_agent.authority_id = '__IDENTIFIER__'
JOIN enumeration_value ev ON ev.value = '__AGENT_ROLE__'
JOIN enumeration e ON ev.enumeration_id = e.id
WHERE udef.resource_id IS NOT NULL
AND   udef.string_2 IS NOT NULL
AND   udef.string_2 = '__BIB_NUMBER__'
AND   e.name = 'linked_agent_role'
AND   name_agent.id IS NOT NULL;

-- ACCESSION SUBJECT INSERT
INSERT INTO subject_rlshp
SELECT
	udef.accession_id,
  s.id,
  0,
  'admin',
  'admin',
  NOW(),
  NOW(),
  0
FROM user_defined udef
JOIN subject s ON s.authority_id = '__IDENTIFIER__'
WHERE udef.accession_id IS NOT NULL
AND   udef.string_2 IS NOT NULL
AND   udef.string_2 = '__BIB_NUMBER__'
AND   s.id IS NOT NULL;

-- RESOURCE SUBJECT INSERT
INSERT INTO subject_rlshp
SELECT
	udef.resource_id,
  s.id,
  0,
  'admin',
  'admin',
  NOW(),
  NOW(),
  0
FROM user_defined udef
JOIN subject s ON s.authority_id = '__IDENTIFIER__'
WHERE udef.resource_id IS NOT NULL
AND   udef.string_2 IS NOT NULL
AND   udef.string_2 = '__BIB_NUMBER__'
AND   s.id IS NOT NULL;
```

---
