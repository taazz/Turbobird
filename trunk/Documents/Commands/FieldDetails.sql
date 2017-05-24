SELECT r.RDB$FIELD_NAME AS              cFldName,
       f.RDB$FIELD_TYPE AS              cfldType,
       f.RDB$FIELD_SUB_TYPE AS          cFldSubType,
       f.RDB$FIELD_LENGTH AS            cFldLength,
       f.RDB$FIELD_PRECISION AS         cFldPrecision,
       f.RDB$FIELD_SCALE AS             cFldScale,
       f.RDB$CHARACTER_LENGTH AS        characterlength,  --{character_length seems a reserved word}
       r.RDB$DESCRIPTION AS             cFldDescription,
       r.RDB$DEFAULT_SOURCE AS          cFldDefSource,
       r.RDB$NULL_FLAG AS               cFldNullFlag,
       coll.RDB$COLLATION_NAME AS       cFldCollation,
       cset.RDB$CHARACTER_SET_NAME AS   cFldCharset,
       f.RDB$computed_source AS         cFldComputedSrc,
       dim.RDB$UPPER_BOUND AS           cArrUpBound,
       r.RDB$FIELD_SOURCE AS            cFldSource
FROM RDB$RELATION_FIELDS r
LEFT JOIN RDB$FIELDS f             ON r.RDB$FIELD_SOURCE = f.RDB$FIELD_NAME
LEFT JOIN RDB$COLLATIONS coll      ON f.RDB$COLLATION_ID = coll.RDB$COLLATION_ID
LEFT JOIN RDB$CHARACTER_SETS cset  ON f.RDB$CHARACTER_SET_ID = cset.RDB$CHARACTER_SET_ID
LEFT JOIN RDB$FIELD_DIMENSIONS dim ON f.RDB$FIELD_NAME = dim.RDB$FIELD_NAME
WHERE    r.RDB$RELATION_NAME = 'CUSTOMER'
ORDER BY r.RDB$FIELD_POSITION

