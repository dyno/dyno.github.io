---
layout: post
title: Take a Peek Inside the Kernel Memory Layout
categories:
- post
---

How does the kernel layout in memory and in dump file?
Let's do some experiment to understand how the [_crash utility_](http://people.redhat.com/anderson/crash_whitepaper/), [_volatility_](https://github.com/volatilityfoundation/volatility/wiki) and other memory forensics tools work.

---

## Address Translation ##

### crash utility ###

```
[dyno@cola:tmp]$ crash vmlinux vmss.core

...
please wait... (determining panic task)
crash: invalid task address: ffffffff8178ded8
      KERNEL: vmlinux
    DUMPFILE: vmss.core
        CPUS: 2
        DATE: Tue Sep 27 17:11:00 2011
      UPTIME: 00:03:48
LOAD AVERAGE: 0.12, 0.30, 0.15
       TASKS: 259
    NODENAME: lucid
     RELEASE: 2.6.32-34-generic
     VERSION: #77-Ubuntu SMP Tue Sep 13 19:39:17 UTC 2011
     MACHINE: x86_64  (2493 Mhz)
      MEMORY: 1 GB
       PANIC: ""
         PID: 0
     COMMAND: "swapper"    <---- HERE, init_task.comm
        TASK: ffffffff817b4600  (1 of 2)  [THREAD_INFO: ffffffff8178c000]
         CPU: 0
       STATE: TASK_RUNNING (ACTIVE)
     WARNING: panic task not found
```

`COMMAND: "swapper"`, how `crash` get this `init_task` ("Initial task structure")
from the memory coredump? (`linux_banner` is another well known anchor you can try.)

### GDB ###

let's try to get the physical address of ```init_task.comm``` with GDB.

```
[dyno@cola:tmp]$ gdb vmlinux vmss.core
(gdb) ptype init_task.comm
type = char [16]
(gdb) print init_task.comm
(gdb) info address init_task
Symbol "init_task" is static storage at address 0xffffffff817b4600.
gdb) p /x (unsigned long)&init_task - 0xffffffff80000000
$15 = 0x17b4600
(gdb) p ((unsigned)&((struct task_struct *) 0)->comm)
$17 = 1144
(gdb) p /x 0x17b4600 + 1144
$18 = 0x17b4a78
```

`init_task` is at address `0xffffffff817b4600` which is apparently a [Virtual Address](http://makelinux.com/ldd3/?u=chp-15-sect-1).
and `init_task.comm`'s address is translated to a physical address `0x17b4a78`.
Here is code from kernel source for the translation.

```C
//## Documentation/x86/x86_64/mm.txt
//## arch/x86/include/asm/page.h
#define __pa(x)        __phys_addr((unsigned long)(x))

//## arch/x86/mm/physaddr.c
unsigned long __phys_addr(unsigned long x)
{
  if (x >= __START_KERNEL_map) {
    x -= __START_KERNEL_map;
    VIRTUAL_BUG_ON(x >= KERNEL_IMAGE_SIZE);
    x += phys_base;
  } else {
    VIRTUAL_BUG_ON(x < PAGE_OFFSET);
    x -= PAGE_OFFSET;
    VIRTUAL_BUG_ON(!phys_addr_valid(x));
  }
  return x;
}

//## arch/x86/include/asm/page_64_types.h
#define __PAGE_OFFSET           _AC(0xffff880000000000, UL)
#define __START_KERNEL_map    _AC(0xffffffff80000000, UL)
```

### objdump ###

So what's in physical address `0x17b4a78`? raw data...

```
[dyno@cola:tmp]$ objdump --full-contents --start-address=0x17b4a78 --stop-address=0x17b4a88 vmss.core

vmss.core:     file format elf64-x86-64

Contents of section load1:
 17b4a78 73776170 70657200 00000000 00000000  swapper.........
```

Wow! `init_task.comm = "swapper"` :-)

## Registers ##

Let's get more information about the core file.
Different tools ([_readelf_](https://sourceware.org/binutils/docs/binutils/readelf.html), [_objdump_](http://sourceware.org/binutils/docs/binutils/objdump.html), [_elfutils_](https://fedorahosted.org/elfutils/)) present the information in different perspective.

```
[dyno@cola:tmp]$ readelf --program-headers --wide vmss.core

Elf file type is CORE (Core file)
Entry point 0x0
There are 2 program headers, starting at offset 64

Program Headers:
  Type           Offset   VirtAddr           PhysAddr           FileSiz  MemSiz   Flg Align
  NOTE           0x0000b0 0x0000000000000000 0x0000000000000000 0x00020c 0x000000     0
  LOAD           0x001000 0x0000000000000000 0x0000000000000000 0x40000000 0x40000000 RWE 0x1000

[dyno@cola:tmp]$ objdump --all-headers vmss.core

vmss.core:     file format elf64-x86-64
vmss.core
architecture: i386:x86-64, flags 0x00000000:

start address 0x0000000000000000

Program Header:
    NOTE off    0x00000000000000b0 vaddr 0x0000000000000000 paddr 0x0000000000000000 align 2**0
         filesz 0x000000000000020c memsz 0x0000000000000000 flags ---
    LOAD off    0x0000000000001000 vaddr 0x0000000000000000 paddr 0x0000000000000000 align 2**12
         filesz 0x0000000040000000 memsz 0x0000000040000000 flags rwx

Sections:
Idx Name          Size      VMA               LMA               File off  Algn
  0 note0         0000020c  0000000000000000  0000000000000000  000000b0  2**0
                  CONTENTS, READONLY
  1 .reg/12345    000000d8  0000000000000000  0000000000000000  00000130  2**2
                  CONTENTS
  2 .reg          000000d8  0000000000000000  0000000000000000  00000130  2**2
                  CONTENTS
  3 load1         40000000  0000000000000000  0000000000000000  00001000  2**12
                  CONTENTS, ALLOC, LOAD, CODE
SYMBOL TABLE:
no symbols
```

__register information is part of a running system snapshot but not part of memory.__
So register information is stored in the ELF NOTE section.

```
[dyno@cola:tmp]$ readelf --notes --wide vmss.core

Notes at offset 0x000000b0 with length 0x0000020c:
  Owner        Data size    Description
  CORE        0x00000150    NT_PRSTATUS (prstatus structure)
  CORE        0x00000080    NT_PRPSINFO (prpsinfo structure)
  CORE        0x0000000c    NT_TASKSTRUCT (task structure)

[dyno@cola:tmp]$ eu-readelf --note vmss.core

Note segment of 524 bytes at offset 0xb0:
  Owner          Data size  Type
  CORE                 336  PRSTATUS
    info.si_signo: 11, info.si_code: 0, info.si_errno: 0, cursig: 11
    sigpend: <>
    sighold: <>
    pid: 12345, ppid: 12345, pgrp: 12345, sid: 12345
    utime: 3.000003, stime: 3.000000, cutime: 3.000003, cstime: 0.000003
    orig_rax: 0, fpvalid: 0
    r15:                  573440  r14:             -2122784856
    r13:             -2120982528  r12:             -2122132608
    rbp:      0xffffffff8178ded8  rbx:             -2122784808
    r11:                       1  r10:            229096160046
    r9:                        0  r8:                        0
    rax:                       0  rcx:                       0
    rdx:                       0  rsi:                       1
    rdi:             -2120970328  rip:      0xffffffff81037b6b
    rflags:   0x0000000000000246  rsp:      0xffffffff8178ded8
    fs.base:   0x0000000000000000  gs.base:   0xffff880001c00000
    cs: 0x0010  ss: 0x0018  ds: 0x0018  es: 0x0018  fs: 0x0000  gs: 0x0000
  CORE                 128  PRPSINFO
  CORE                  12  TASKSTRUCT
```
