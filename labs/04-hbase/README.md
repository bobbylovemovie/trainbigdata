# Lab 4 -- HBase

Start HBase first: `labctl start hbase` (from your host: `docker compose
exec bigdata labctl start hbase`).

Column family names used to contain spaces (`'personal data'`). Spaces in
HBase identifiers are legal but awkward to type and script against, so this
lab uses underscore-based names instead: `personal_data`, `professional_data`.

```bash
hbase shell
```

```text
create 'employee', 'personal_data', 'professional_data'
list

put 'employee','1','personal_data:name','raju'
put 'employee','1','personal_data:city','hyderabad'
put 'employee','1','professional_data:designation','manager'
put 'employee','1','professional_data:salary','5000'

put 'employee','2','personal_data:name','bobby'

scan 'employee'
get 'employee','1'

exit
```

HBase Master UI: http://localhost:16010
