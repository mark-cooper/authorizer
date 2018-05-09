# CLEANUP

```sql
-- cleanup names
UPDATE name_person
JOIN   name_authority_id
ON     name_person.id = name_authority_id.name_person_id
SET    name_person.source_id = (
        SELECT ev.id FROM enumeration_value ev JOIN enumeration e ON ev.enumeration_id = e.id WHERE e.name = 'name_source' AND ev.value = 'local'
       )
WHERE name_authority_id.authority_id LIKE 'dts_%' AND name_authority_id.created_by = 'lyrasis-dts';

UPDATE name_corporate_entity
JOIN   name_authority_id
ON     name_corporate_entity.id = name_authority_id.name_corporate_entity_id
SET    name_corporate_entity.source_id = (
        SELECT ev.id FROM enumeration_value ev JOIN enumeration e ON ev.enumeration_id = e.id WHERE e.name = 'name_source' AND ev.value = 'local'
       )
WHERE name_authority_id.authority_id LIKE 'dts_%' AND name_authority_id.created_by = 'lyrasis-dts';

UPDATE name_family
JOIN   name_authority_id
ON     name_family.id = name_authority_id.name_family_id
SET    name_family.source_id = (
        SELECT ev.id FROM enumeration_value ev JOIN enumeration e ON ev.enumeration_id = e.id WHERE e.name = 'name_source' AND ev.value = 'local'
       )
WHERE name_authority_id.authority_id LIKE 'dts_%' AND name_authority_id.created_by = 'lyrasis-dts';

DELETE FROM name_authority_id
WHERE authority_id LIKE 'dts_%' AND created_by = 'lyrasis-dts';

UPDATE agent_person SET system_mtime = NOW() WHERE created_by = 'lyrasis-dts';
UPDATE name_person  SET system_mtime = NOW() WHERE created_by = 'lyrasis-dts';
UPDATE agent_corporate_entity SET system_mtime = NOW() WHERE created_by = 'lyrasis-dts';
UPDATE name_corporate_entity  SET system_mtime = NOW() WHERE created_by = 'lyrasis-dts';
UPDATE agent_family SET system_mtime = NOW() WHERE created_by = 'lyrasis-dts';
UPDATE name_family  SET system_mtime = NOW() WHERE created_by = 'lyrasis-dts';

-- cleanup subjects
UPDATE subject
SET    authority_id = NULL,
		   source_id    = (
         SELECT ev.id FROM enumeration_value ev JOIN enumeration e ON ev.enumeration_id = e.id WHERE e.name = 'subject_source' AND ev.value = 'local'
       ),
       system_mtime = NOW()
WHERE authority_id LIKE 'dts_%' AND created_by = 'lyrasis-dts';
```

Run the auth id update. Then:

```sql
SELECT count(*) FROM name_authority_id WHERE authority_id NOT LIKE 'http://id.loc.gov/%' AND created_by = 'lyrasis-dts';
SELECT * FROM name_authority_id WHERE authority_id NOT LIKE 'http://id.loc.gov/%' AND created_by = 'lyrasis-dts';
```
