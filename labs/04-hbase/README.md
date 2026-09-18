# Lab 4 -- HBase

[ภาษาไทย](README.th.md) | **English**

Start HBase first: `labctl start hbase` (from your host: `docker compose
exec bigdata labctl start hbase`).

This table uses two column families: `personal_data` and
`professional_data`.

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
