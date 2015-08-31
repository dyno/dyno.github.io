---
layout: post
title: The guide to find Linux kernel debuginfo package
categories:
- post
---

A repeat task to Linux core dump analysis is to find the corresponding kernel debuginfo package.
When you extract the kernel version from the memory, the first question is which release the kernel is at.
Then where to find the kernel debuginfo package that has the symbols and maybe also the source package.
The most popular commercial Linux distributions are RHEL, SLES, Ubuntu and their relatives, so
here is the guide to find those packages.

---

### Ubuntu ###

* Ubuntu List of Releases, https://wiki.ubuntu.com/Releases
* Ubuntu Releases and Kernel Versions, https://en.wikipedia.org/wiki/List_of_Ubuntu_releases#Table_of_versions
* debuginfo online repository: http://ddebs.ubuntu.com/pool/main/l/linux/
* package name:

```
kernel: linux-image
symbol: linux-image-*-dbgsym
source: linux-source
```

* extract package

```bash
    ar -x linux-image-3.2.0-41-generic-dbgsym_3.2.0-41.66_amd64.ddeb
```

#### Debian ####
* [Add support for creating a "debuginfo" package](http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=365349)
* e.g. `https://packages.debian.org/jessie/linux-image-3.16.0-4-amd64-dbg`

### RHEL ###
* Red Hat Enterprise Linux Release Dates, https://access.redhat.com/articles/3078
* __CentOS debug packages are compatible with Redhat__
* package online repository: http://vault.centos.org/
* debuginfo online repository: http://debuginfo.centos.org/

```
kernel: kernel
source: kernel-debuginfo-common
symbol: kernel-debuginfo
```

* extract package

```
    rpm2cpio kernel-2.6.32-573.el6.x86_64.rpm | cpio -idmv
```

#### Oracle UEK (Unbreakable Enterprise Kernel) ####
* package online repository: http://public-yum.oracle.com/repo/OracleLinux/
* debuginfo online repository: https://oss.oracle.com/ol6/debuginfo/

#### More Relatives ####
* [CentOS AdditionalResources/Repositories/DebugInfo](http://wiki.centos.org/AdditionalResources/Repositories/DebugInfo)
* [Fedora Packaging:Debuginfo](http://fedoraproject.org/wiki/Packaging:Debuginfo)

### SLES ###
* SLES kernel releases, https://wiki.novell.com/index.php/Kernel_versions
* SLES [How to add the catalog for debuginfo packages](http://www.novell.com/support/documentLink.do?externalID#3074997)

```bash
zypper search -s 'kernel-default'
zypper install --download-only --oldpackage kernel-default-debuginfo-3.0.101-0.15.1
# find the rpm in /var/cache/zypp/packages
```
* _I've not yet found an open free online repository for SLES..._
