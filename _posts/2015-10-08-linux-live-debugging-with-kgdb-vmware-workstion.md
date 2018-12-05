* * *

layout: post
title: Linux Kernel Live Debugging with VMware Workstation
categories:

-   post

* * *

Recently, I've been assigned a task to fix our vmhgfs kernel module for Ubuntu 15.10
which sports a cutting edge Linux 4.2 Kernel. It is not crashing but the file system
just not work. As a sustaining engineer, live debugging is so valuable to jungle through
the code base i am not so familiar with...

* * *

## The Goal

 **Debug Guest OS Linux kernel over virtual serial port with VMware Workstation.**

## Step-by-Step

### Virtual Serial Port

you can add a serial port from the VMware workstation UI as well, but the effect
is the same, vmx configure file now has a few more lines for serial port.

```text
serial1.present = "TRUE"
serial1.yieldOnMsrRead = "TRUE"
serial1.fileType = "pipe"
serial1.fileName = "/tmp/com_ubuntu1510"
```

#### ttyS0 or ttyS1?

There might already be another virtual hardware occupies `ttyS0`.

**On Host**

-   on one terminal run `socat -d -d /tmp/com_ubuntu1510 tcp-listen:9999` to redirect named pipe to a socket.
-   on another terminal run `telnet 127.0.0.1 9999`

**Inside the Guest as root**

-   `echo whatever > /dev/ttyS0`

check if "whatever" shows on the host telnet terminal, if it is there, then it is `ttyS0`. If it is not, try `ttyS1`.

### Guest: KGDB Setup

The first question is whether your Guest OS Linux Kernel support KGDB ...

```text
hfu@ubuntu:~$ grep KGDB /boot/config-$(uname -r)
CONFIG_SERIAL_KGDB_NMI=y
CONFIG_HAVE_ARCH_KGDB=y
CONFIG_KGDB=y                         <---
CONFIG_KGDB_SERIAL_CONSOLE=y          <---
# CONFIG_KGDB_TESTS is not set
CONFIG_KGDB_LOW_LEVEL_TRAP=y
CONFIG_KGDB_KDB=y
```

Now, configure the kernel to start kgdb server, simply put, add `kgdboc=ttyS0,115200 kgdbwait` to the kernel cmdline.

-   <https://www.kernel.org/doc/Documentation/kernel-parameters.txt>
-   `kgdboc=ttyS0,115200` - kgdb over console, serial port `ttyS0`, and baud rate is 115200
-   `kgdbwait` - "Stop kernel execution and enter the 			kernel debugger at the earliest opportunity."

Here we create a grub menu entry in `/etc/grub.d/40_custom`.
_(I have to complain about the grub2 design, the configuration so arcane compare to grub1 that makes you don't even want to touch it...)_

```bash
# /etc/grub.d/40-custom, copied from /boot/grub/grub.cfg
menuentry 'UbuntuKGDB' --class ubuntu --class gnu-linux --class gnu --class os $menuentry_id_option 'gnulinux-simple-4492a93c-91e2-4979-b5b9-71e32901511c' {
	insmod gzio
	insmod part_msdos
	insmod ext2
	set root='hd0,msdos1'
	search --no-floppy --fs-uuid --set=root 4492a93c-91e2-4979-b5b9-71e32901511c
	linux	/boot/vmlinuz-4.2.0-14-generic root=UUID=4492a93c-91e2-4979-b5b9-71e32901511c ro find_preseed=/preseed.cfg auto noprompt priority=critical locale=en_US kgdboc=ttyS0,115200 kgdbwait
	initrd	/boot/initrd.img-4.2.0-14-generic
}
```

If you cannot see the grub menu, in `/etc/default/grub`, comment out the 2 lines.

    #GRUB_HIDDEN_TIMEOUT=10
    #GRUB_HIDDEN_TIMEOUT_QUIET=false

after all these modification, don't forget to run `update-grub`

Reboot Guest with the newly added kernel entry, and see if kgdb server is waiting for connection.

### SysRq Config Host/Guest

-   Host

Since we are going to use SysRq to break into debugger, we need to
disable `sysrq` on the host. Or SysRq will be captured by the host.

```bash
echo 0 > /proc/sys/kernel/sysrq
# Or with command,
# sysctl kernel.sysrq = 0
# And to survive reboot,
# echo 'kernel.sysrq = 0' >> /etc/sysctl.conf
```

-   Guest

Same thing on guest, just to enable all.

    echo 1 > /proc/sys/kernel/sysrq

### Kernel Break/Resume

For how to get the source code and debug symbols check my previous post
[Linux Kernel DebugInfo](/post/2015/08/31/linux-kernel-dbuginfo.html). 
attach gdb to the kgdb server,

    gdb debuginfo/usr/lib/debug/boot/vmlinux-4.2.0-14-generic
    (gdb) set substitute-path /build/linux-xyuzCP/linux-4.2.0 /home/hfu/debuginfo/linux-source-4.2.0/linux-source-4.2.0
    (gdb) target remote localhost:9999
    (gdb) c

now inside the guest,

    # press Alt+SysRq+g
    # OR
    echo g > /proc/sysreq-trigger

will break into the debugger.

### Kernel Module Debug

build your module with gcc debugging option `-g`, and load the module, e.g. `modprobe vmhgfs`

```bash
_dir=/sys/module/vmhgfs/sections
cmd="add-symbol-file ~/vmhgfs.ko $(cat $_dir/.text) -s .bss $(cat $_dir/.bss) -s .data $(cat $_dir/.data)"
echo "$cmd" > add_vmhgfs_symbol.gdb
```

Copy the symbol file loading gdb script to the host and break into debugger,

    (gdb) source add_vmhgfs_symbol.gdb
    (gdb) break HgfsSendRequest

## Miscellaneous

1.  how to debug `module_init`?

## Reference

### KGDB

<https://www.kernel.org/doc/Documentation/gdb-kernel-debugging.txt>

    The kernel debugger kgdb, hypervisors like QEMU or JTAG-based hardware
    interfaces allow to debug the Linux kernel and its modules during runtime
    using gdb. Gdb comes with a powerful scripting interface for python. The
    kernel provides a collection of helper scripts that can simplify typical
    kernel debugging steps. This is a short tutorial about how to enable and use
    them. It focuses on QEMU/KVM virtual machines as target, but the examples can
    be transferred to the other gdb stubs as well.

I actually use VMware Workstation as the virtualization solution...

### SysRq

<https://www.kernel.org/doc/Documentation/sysrq.txt>

    It is a 'magical' key combo you can hit which the kernel will respond to
    regardless of whatever else it is doing, unless it is completely locked up.
    ...
    On x86   - You press the key combo 'ALT-SysRq-<command key>'. Note - Some
               keyboards may not have a key labeled 'SysRq'. The 'SysRq' key is
               also known as the 'Print Screen' key. Also some keyboards cannot
               handle so many keys being pressed at the same time, so you might
               have better luck with "press Alt", "press SysRq", "release SysRq",
               "press <command key>", release everything.

Not like a user world application, we use SysRq to break running kernel into debugger.
