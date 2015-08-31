---
layout: post
title: Linux Kernel Coredump Analysis with Crash Utility
categories:
- post
---

There are excellent tutorials around using crash utility to analyze Linux kernel coredump.
And this is yet another one ...

---

## Before we start ... ##

1. Capture the memory core dump file (in VMware environment).
    - Suspending a virtual machine on ESX/ESXi to collect diagnostic information (2005831), http://kb.vmware.com/kb/2005831

    > This basically means it is not necessary to enable `kexec/kdump` in a virtualization environment.

1. Converting a snapshot file to memory dump using the [`vmss2core`](https://labs.vmware.com/flings/vmss2core) tool (2003941), http://kb.vmware.com/kb/2003941

    > Actually, crash utility can understand VMware `vmss` file from version [`7.10`](http://people.redhat.com/anderson/crash.changelog.html)

1. Find the linux kernel symbols/source code which I have written in [another post](/post/2015/08/31/linux-kernel-dbuginfo.html).

here is a typical command looks like:

```bash
#!/bin/bash
VMLINUX_DEBUGINFO=$PWD/debuginfo/usr/lib/debug/boot/vmlinux-3.0.101-0.15-default.debug
VMLINUX=$PWD/debuginfo/boot/vmlinux-3.0.101-0.15-default
KERNEL_MEM_DUMP="vm123.vmss"

crash $VMLINUX $VMLINUX_DEBUGINFO $KERNEL_MEM_DUMP
```

## The "How to" Guide ##

* __How to figure out the kernel version?__

```bash
strings vmss.core | grep "Linux version [0-9]\.[0-9]" -m 1
```

* __How to solve the `vmlinux and vmss.core do not match` problem?__

> If you are sure that vmlinux contains the match debug information, then most likely you need to specify the `phys_base` machine dependent parameter. and experience shows that __RHEL 5 kernels 2.6.18-*__ need __--machdep phys_base=2M__  
> Dave, the crash utility author, explained the problem in a Redhat Bug, [crash fails to read RHEL-5 FV core dump files collected from xm dump-core](https://bugzilla.redhat.com/show_bug.cgi?id=233151).

* __How to list source code?__

```text
crash> gdb list schedule
3515    kernel/sched.c: No such file or directory.
crash> directory /mysrc/kernel-2.6.18/linux-2.6.18-371.1.2.el5.x86_64/
crash> gdb list schedule
warning: Source file is more recent than executable.
3515
3516    /*
3517     * schedule() is the main scheduler function.
3518     */
3519    asmlinkage void __sched schedule(void)
3520    {
3521            struct task_struct *prev, *next;
3522            struct prio_array *array;
3523            struct list_head *queue;
3524            unsigned long long now;
crash> dis -l schedule
crash> gdb disas /m schedule
```

* __How to load module symbol?__

```text
crash> mod -s ext4 usr/lib/debug/lib/modules/2.6.32-220.el6.x86_64/kernel/fs/ext4/ext4.ko.debug
     MODULE       NAME              SIZE  OBJECT FILE
ffffffffa01181e0  ext4            364410  usr/lib/debug/lib/modules/2.6.32-220.el6.x86_64/kernel/fs/ext4/ext4.ko.debug
crash> whatis ext4_file_write
ssize_t ext4_file_write(struct kiocb *, const struct iovec *, unsigned long, loff_t);
crash> mod -d ext4
crash> whatis ext4_file_write
whatis: gdb request failed: whatis ext4_file_write
```

* __How to extract parameter information from backtrace?__

    - For AMD64, __RDI/RSI/RDX/RCX__ are the first four parameters according to [X86_calling_conventions](http://en.wikipedia.org/wiki/X86_calling_conventions)  
    - Sometimes you need to search the value from the stack. `bt -f` will be more helpful in that case.  
    - `gdb disas /m <function>` the disassembled code will give more information how the parameter are passed around.  
    - [crash command help page __bt__](http://people.redhat.com/anderson/crash_whitepaper/help_pages/bt.html) has an example to  extract 32bit process parameters.  
    - [crash extension __fp__](http://people.redhat.com/anderson/extensions/fp_help.html) - Obtaining functions' parameters from stack frames - is designed to simplify the process but does not work reliably.  

* __Howto get user process backtrace? or extract a userland process core dump?__

    - There was mailing list discussion [Re: [Crash-utility] User Stack back trace of the process](http://www.redhat.com/archives/crash-utility/2007-September/msg00002.html)
    - [__gcore__](http://people.redhat.com/anderson/extensions/gcore_help_gcore.html) - retrieve a process image as a core dump
    - It might also possible to piece up the stack infomation from memory, like [lsstack](http://sourceforge.net/projects/lsstack/)

## Extended Reading ##
* volatility, http://www.volatilityfoundation.org
* crash extension modules, http://people.redhat.com/anderson/extensions.html
* A Clarification on Linux Addressing, http://users.nccs.gov/~fwang2/linux/lk_addressing.txt
