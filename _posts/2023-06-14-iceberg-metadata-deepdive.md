---
layout: post
title: Iceberg Metadata Deep Dive
categories:
- post,iceberg,spark,parquet
---

![Table Operation and Iceberg Metadata](http://www.plantuml.com/plantuml/proxy?cache=no&src=https://raw.githubusercontent.com/dyno/dyno.github.io/master/images/iceberg.iuml)

## Key Concepts

* metadata file -
    * the entry point of table, the current_snapshot_id
    * has all metadata like schema spec, partition spec etc
    * backed the $snapshots metatable.
    * maintenance requirement: as new file for each commit, and set table properties `write.metadata.previous-versions-max`
    * e.g. `00247-74e94d3d-871c-4e20-a217-2fb9c5ffb430.metadata.json`
* manifest list -
    * a.k.a snapshot, is a point-in-time consistent view of table
    * backed the `$manifests` metatable
    * used to filter query on partitions
    * maintenance requirement: `expire_snapshots` to keep metadata file/manifest list for bloating and release the reference for old files.
    * e.g. `snap-6301781580282422576-1-de30417a-c9a9-4f5f-9c64-944f9111ab0e.avro`
* manifest file -
    * work like a commit, a unit of work.
    * backed the `$files` metatable
    * used to filter query on column metrics
    * maintenance requirement: `rewrite_manifests` to speed up the metadata loading and release reference of old snapshots.
* data file -
    * the real table data file in parquet
    * maintenance requirement: `rewrite_data_files` and `expire_snapshots` to consolidate small files and also help to maintain the manifest file size, `remove_ophan_files` to keep the table metadata and data in sync.
* one commit (dataframe write/delete/overwrite) → one snapshot → one added_snapshot_id → one new manifest_list file snap-*.avro → one new manifest file *-m0.avro → one new sequence number
* The top to bottom dependency also implies the maintenance should be bottom to top to release the reference.

![ER Diagram](http://www.plantuml.com/plantuml/proxy?cache=no&src=https://raw.githubusercontent.com/dyno/dyno.github.io/master/images/iceberg_metatables.iuml)
