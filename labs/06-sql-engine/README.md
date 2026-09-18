# Lab 6 -- Impala (Deprecated / Optional)

[ภาษาไทย](README.th.md) | **English**

Impala is not installed in this sandbox. It was tightly coupled to
Cloudera's packaging, adds another JVM-class daemon (catalogd/statestored/
impalad) and its own metadata-caching model on top of the same Hive
metastore -- meaningful operational weight for a single-node teaching
environment where the learning objective ("fast interactive SQL over the
same tables") is already covered by Hive/Beeline (labs/05) and Spark SQL
(labs/10).

If a fast interactive SQL engine over Hive tables is wanted in a future
phase, **Trino** (https://trino.io) is the natural modern replacement --
it's a single binary-ish server, has a Hive connector that reads the exact
metastore this sandbox already runs, and is not tied to any vendor
distribution. Not implemented here to avoid adding a second query engine
before the core stack is proven.

Status: **deprecated / optional, not implemented in trainbigdata:2026.**
