---
layout: post
title: vmhgfs-fuse: User Level VMware Host-Guest FileSystem Client
categories:
- post
---

*vmhgfs* is the Host-Guest filesystem in the VMware desktop product Workstation/Fusion
so that user can can share files between Host OS and Guest OS without caring about network setup.

Ideally, we just do `mount .host:/ /mnt` as any other filesystem and do not need to know
how it works below the surface. But things always break and we have to burden ourself to fix things ...

 - *vmhgfs.ko* The kernel module, along with the kernel update, constantly facing compiling issue.   
   The Ubuntu open-vm-tools [launchpad bug#1500581](https://bugs.launchpad.net/ubuntu/+source/open-vm-tools/+bug/1500581)
 - *vmhgfs-fuse* The user level client with libfuse to workaround the kernel update burden.   

Both clients can work talk to the the hypervisor backend, and as I am one of the vmhgfs-fuse author,
I will document the steps to compile and use *vmhgfs-fuse* clients.

---

```bash
sudo apt-get install build-essential autoconf libtool
# really just to make the configure script happy, not really used by vmhgfs-fuse
sudo apt-get install libmspack-dev libglib2.0-dev libprocps4-dev libdnet-dev libdumbnet-dev
sudo apt-get install libfuse-dev

git clone https://github.com/vmware/open-vm-tools.git
git tag -l
git checkout tags/stable-10.0.5 -b branch-stable-10.0.5

cd open-vm-tools/open-vm-tools
./configure --without-x --without-pam --without-ssl --without-icu
make
#ls -l vmhgfs-fuse/vmhgfs-fuse
# btw: build the kernel module vmhgfs.ko
# https://github.com/vmware/open-vm-tools/issues/62#issuecomment-168337132
# make MODULES=vmhgfs

# tweak mount.vmhgfs so that `mount -t vmhgfs .host:/ /mnt/hgfs` works.
# XXX: hgfsclient/hgfsmounter should be able to make `mount .host:/ /mnt/hgfs` work 
sudo mv vmhgfs-fuse/vmhgfs-fuse /usr/local/bin/
cd /sbin/
sudo mv mount.vmhgfs mount.vmhgfs.kernel
sudo vim /sbin/mount.vmhgfs.fuse
#-----%<------------------------------------------------------------------------
#!/bin/bash
# /usr/local/bin/vmhgfs-fuse -o allow_other -o uid=1000 -o gid=1000 $@
/usr/local/bin/vmhgfs-fuse $@
#----->%------------------------------------------------------------------------
sudo ln -s mount.vmhgfs.fuse mount.vmhgfs

# Auto mount on system start
# mkdir /mnt/hgfs and add line to /etc/fstab
#.host:/         /mnt/hgfs    vmhgfs  defaults 0       0
```
