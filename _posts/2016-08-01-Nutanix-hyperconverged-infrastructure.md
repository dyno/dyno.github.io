---
layout: post
title: Nutanix Hyperconverged Infrastructure
categories:
- post
---

## The Hyperconverged Infrastructure Ideas

* Distributed System - GFS, The Google File System, Map Reduce
* RAID - Reduncancy Array of Inexpensive Disk
* FUSE - FileSytem in User Space
  http://libfuse.github.io/doxygen/structfuse__operations.html
* Gabage Collection - Java
* Fault Tolerance - Database System: Redo/Undo Log, Journaling Filesystem
* Virtualization - Virtual Machine/Disk abstraction

## the Implementation

### the Model

vDisk -> file handle, offset, size

### A Distributed Filesystem (for Virtualization)

* System Configuration: Zookeeper
  - Cluster Configuration: node, disk, hypervisor, etc,
  - Leader election
  - Sequence/ID generation
* Metadata: Cassandra
  - Consistent Hashing
  - Paxos for consistency
* Data: Homegrown
  - fuse alike API, QoS
  - Journaling
  - Layered Cache

### the Protocol

* NFS - VMware ESXi
* SMB - Microsoft HyperV
* iSCSI - Nutanix AHV (KVM)

## Solutions Built on Top

* Snapshot
* Deduplication
* Compression
* Erasure-Coding(RAID)
* DR(Disaster/Recovery)

## Other Open Source Technology

https://www.quora.com/What-is-the-technology-stack-at-Nutanix

* https://gflags.github.io/gflags/
* https://github.com/google/protobuf
* https://google.github.io/flatbuffers/

http://nutanixbible.com/

