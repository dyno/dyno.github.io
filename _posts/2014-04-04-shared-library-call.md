---
layout: post
title:  Experiment to Trace the Shared Library Call Translation
categories:
- post
---

I am wondering how the execution flow was branched to a function implemented in shared library,
and the reference links in the "_Extended Reading_" section gives enough info about the theory.
I only make the following experiment to show the process. `PLT` and `GOT` are the key to the translation.

* PLT (Procedure Linkage Table)
* GOT (Global Offset Table)

---

## Environment ##

Here the environment for the experiment (on __Ubuntu amd64__),

```bash
sudo apt-get install build-essential
sudo apt-get install libc-dbg
# libc source
sudo apt-get source libc6
```

`foo` & `foo2` are the functions to be examined, (code to produce it is listed at Source Code List).

```
[dyno@ubuntu:plt]$ make

[dyno@ubuntu:plt]$ objdump --syms main.exe | grep -E "(foo|xyz)"
0000000000000000       F *UND*    0000000000000000              foo2 <---- 1
0000000000000000       F *UND*    0000000000000000              foo  <---- 2
0000000000601028 g     O .bss    0000000000000004              xyz

[dyno@ubuntu:plt]$ readelf --sections --wide main.exe | grep got
  [22] .got              PROGBITS        0000000000600fe0 000fe0 000008 08  WA  0   0  8
  [23] .got.plt          PROGBITS        0000000000600fe8 000fe8 000030 08  WA  0   0  8
```

## Experiment ##

``` bash
export LD_LIBRARY_PATH=$PWD
gdb main.exe

(gdb) break main
(gdb) run
Breakpoint 1, main () at main.c:4
4       xyz = 100;

symbol file for ld need to be explicitly loaded,
(gdb) info sharedlibrary
From To Syms Read Shared Object Library
0x00007ffff7ddcaf0 0x00007ffff7df5a66 Yes (*) /lib64/ld-linux-x86-64.so.2
0x00007ffff7bda500 0x00007ffff7bda628 Yes /home/dyno/codes/plt/libtest.so
0x00007ffff7864c00 0x00007ffff79817ec Yes /lib/x86_64-linux-gnu/libc.so.6

(gdb) add-symbol-file /usr/lib/debug/lib/x86_64-linux-gnu/ld-2.13.so 0x00007ffff7ddcaf0
(gdb) directory ~/codes/debsrc/eglibc-2.13/elf
(gdb) set disassemble-next-line on
```

when we first see `foo()`,

```
(gdb) disassemble main
Dump of assembler code for function main:
0x0000000000400674 <+0>: push %rbp
0x0000000000400675 <+1>: mov %rsp,%rbp
0x0000000000400678 <+4>: movl $0x64,0x2009a6(%rip) # 0x601028 <xyz>
0x0000000000400682 <+14>: mov $0x0,%eax
0x0000000000400687 <+19>: callq 0x400578 <foo@plt> <----
0x000000000040068c <+24>: mov $0x0,%eax
0x0000000000400691 <+29>: callq 0x400578 <foo@plt>
...
(gdb) disassemble 0x400578
Dump of assembler code for function foo@plt:
0x0000000000400578 <+0>: jmpq *0x200a92(%rip) # 0x601010 <_GLOBAL_OFFSET_TABLE_+40>
0x000000000040057e <+6>: pushq $0x2 <----
0x0000000000400583 <+11>: jmpq 0x400548 <----
End of assembler dump.
```

what is `$0x2`? it's `reloc_index`, offset of `foo` in `GOT` (see below).  
`rip` is now next instruction address (`0x40057e`),

```
# jump destination, GOT
(gdb) p/x 0x40057e + 0x200a92
$3 = 0x601010

(gdb) disassemble 0x400548
No function contains specified address.
(gdb) x/5i 0x400548
0x400548: pushq 0x200aa2(%rip) # 0x600ff0 <_GLOBAL_OFFSET_TABLE_+8> <----
0x40054e: jmpq *0x200aa4(%rip) # 0x600ff8 <_GLOBAL_OFFSET_TABLE_+16> <----
0x400554: nopl 0x0(%rax)
0x400558 <__libc_start_main@plt>: jmpq *0x200aa2(%rip) # 0x601000 <_GLOBAL_OFFSET_TABLE_+24>__
__0x40055e <__libc_start_main@plt+6>: pushq $0x0
```
another `pushq`，and it's parameter `link_map` (see below).  

next `jumpq` to the runtime resolver,

```
(gdb) x/a 0x600ff8
0x600ff8 <_GLOBAL_OFFSET_TABLE_+16>: 0x7ffff7df0760
(gdb) info symbol 0x7ffff7df0760
_dl_runtime_resolve in section .text of /usr/lib/debug/lib/x86_64-linux-gnu/ld-2.13.so
```

so how does `_dl_runtime_resolve` work? ...

```
(gdb) break _dl_runtime_resolve
(gdb) info breakpoints
Num Type Disp Enb Address What
1 breakpoint keep y 0x0000000000400678 in main at main.c:4
breakpoint already hit 1 time
2 breakpoint keep y 0x00007ffff7df0760 ../sysdeps/x86_64/dl-trampoline.S:30

(gdb) si
0x0000000000400548 in ?? ()
=> 0x0000000000400548: ff 35 a2 0a 20 00 pushq 0x200aa2(%rip) # 0x600ff0 <_GLOBAL_OFFSET_TABLE_+8>
```

`0x600ff0`, the second parameter mentioned earlier,

```
(gdb) x/x 0x600ff0
0x600ff0 <_GLOBAL_OFFSET_TABLE_+8>: 0x00007ffff7ffe2e8

(gdb) list _dl_runtime_resolve
...
29 _dl_runtime_resolve:
30 subq $56,%rsp
31 cfi_adjust_cfa_offset(72) # Incorporate PLT
32 movq %rax,(%rsp) # Preserve registers otherwise clobbered.
...
39 movq 64(%rsp), %rsi # Copy args pushed by PLT in register.
40 movq 56(%rsp), %rdi # %rdi: link_map, %rsi: reloc_index <----
41 call _dl_fixup # Call resolver.
42 movq %rax, %r11 # Save return value <---- the real address of the function
43 movq 48(%rsp), %r9 # Get register content back.
...
```

break the execution and watch the change,

```
(gdb) info line _dl_runtime_resolve
Line 30 of "../sysdeps/x86_64/dl-trampoline.S" starts at address 0x7ffff7df0760 <_dl_runtime_resolve>
and ends at 0x7ffff7df0764 <_dl_runtime_resolve+4>.
(gdb) break ../sysdeps/x86_64/dl-trampoline.S:40
Breakpoint 3 at 0x7ffff7df078b: file ../sysdeps/x86_64/dl-trampoline.S, line 40.

(gdb) c
(gdb) x/a 0x601010
0x601010 <_GLOBAL_OFFSET_TABLE_+40>: 0x40057e <foo@plt+6> <---- before _dl_fixup
(gdb) ni
42 movq %rax, %r11 # Save return value
=> 0x00007ffff7df0795 <_dl_runtime_resolve+53>: 49 89 c3 mov %rax,%r11
(gdb) x/a 0x601010
0x601010 <_GLOBAL_OFFSET_TABLE_+40>: 0x7ffff7bda5cc <foo> <---- after _dl_fixup
Translation done.
```

## Source Code List ##

```Makefile
all:
gcc -g -fPIC -c -o test.o test.c
gcc -g -shared -Wl,-soname,libtest.so -o libtest.so test.o -lc
gcc -g -I. -L. main.c -o main.exe -ltest

tar:
tar zcvf main.tar.gz main.c test.c test.h Makefile

clean:
rm -f *.so *.o *.exe

.PHONY: all tar clean
```

```c
/* main.c */
#include "test.h"

int main() {
xyz = 100;
foo();
foo();
foo2();
foo2();

return 0;
}

/* test.h */
#ifndef TEST_H
#define TEST_H

extern int xyz;
int foo();

#endif

/* test.c */
#include "test.h"

int xyz = 4;

int foo() {
return xyz;
}

int foo2() {
return xyz * 2;
}
```

## Extended Reading ##

* Reversing the ELF Stepping with GDB during PLT uses and .GOT fixup, http://packetstormsecurity.org/files/view/25642/elf-runtime-fixup.txt
* AMD64 Application Binary Interface (v 0.99), http://www.x86-64.org/documentation/abi.pdf
* PLT and GOT - the key to code sharing and dynamic libraries, http://www.technovelty.org/linux/pltgot.html
* examining PLT/GOT structures, http://althing.cs.dartmouth.edu/secref/resources/plt-got.txt
* Debugging with GDB, http://sourceware.org/gdb/current/onlinedocs/gdb/
* 共享库函数调用原理, http://blog.csdn.net/absurd/article/details/3169860
* How main() is executed on Linux, http://linuxgazette.net/issue84/hawk.html
* Gentle Introduction to x86-64 Assembly, http://www.x86-64.org/documentation/assembly.html
