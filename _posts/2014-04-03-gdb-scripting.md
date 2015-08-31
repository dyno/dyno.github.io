---
layout: post
title: Scripting GDB
categories:
- post
---

It is often desirable to parse the output of a `gdb` command and then feed it to a following command (__pipe__).
in the following example, I want to get the start address of `ld-linux-x86-64.so.2` and use it as the
second parameter of `add-symbol-file`.

---

## The Old Way ##

Redirect the command output to a file then process the file with what tools you have.
and create a gdb file with desirable command inside, source it in.

Here we define the helper functions to capture the output.

```bash
##~/.gdbinit ##

define CAPTURE_OUTPUT_BEGIN
  set logging overwrite on
  set logging file $arg0
  set logging on
end
document CAPTURE_OUTPUT_BEGIN
  Capture output by logging begin
end

define CAPTURE_OUTPUT_END
  set logging off
end
document CAPTURE_OUTPUT_END
 Capture output by logging end
end

define CAPTURE_OUTPUT_CLEAN
  shell rm $arg0
end
document CAPTURE_OUTPUT_CLEAN
  Remove temporary files
end
```

script to automate the process,

```bash
## auto.gdb ##
file main.exe
start
#now add shared library symbols
CAPTURE_OUTPUT_BEGIN _output.tmp
info sharedlibrary
CAPTURE_OUTPUT_END

shell awk '/ld/ {printf("add-symbol-file /usr/lib/debug/lib/x86_64-linux-gnu/ld-2.13.so %s\n", $1);}' _output.tmp > _gdb.tmp
source _gdb.tmp

CAPTURE_OUTPUT_CLEAN _output.tmp
CAPTURE_OUTPUT_CLEAN _gdb.tmp
```

and execution output,

```text
[hfu@oneiric:plt]$ gdb -q -x auto.gdb
Temporary breakpoint 1 at 0x400678: file main.c, line 4.

Temporary breakpoint 1, main () at main.c:4
4 xyz = 100;

From To Syms Read Shared Object Library
0x00007ffff7ddcaf0 0x00007ffff7df555a Yes (*) /lib64/ld-linux-x86-64.so.2
0x00007ffff7bda500 0x00007ffff7bda628 Yes /home/hfu/codes/plt/libtest.so
0x00007ffff7859b80 0x00007ffff797ff6c Yes /lib/x86_64-linux-gnu/libc.so.6
(*): Shared library is missing debugging information.

add symbol table from file "/usr/lib/debug/lib/x86_64-linux-gnu/ld-2.13.so" at
.text_addr = 0x7ffff7ddcaf0
_dl_runtime_resolve in section .text of /usr/lib/debug/lib/x86_64-linux-gnu/ld-2.13.so
(gdb)
```

Works, but _UGLY_ ...

## The Python Way ##

[Scripting gdb is possible with python](http://sourceware.org/gdb/onlinedocs/gdb.html#Python),
but capturing the output of gdb.execute() to a string is only available in gdb 7.2 and later.

script to automate the process,

```bash
## auto.py.gdb ##
file main.exe
start

info sharedlibrary
python import gdb
python addr = [e for e in gdb.execute("info sharedlibrary", False, True).splitlines() if e.find("ld") != -1][0].split()[0]
python gdb.execute("add-symbol-file /usr/lib/debug/lib/x86_64-linux-gnu/ld-2.13.so %s" % addr)

info symbol _dl_runtime_resolve
```

the execution output,

```
[hfu@oneiric:plt]$ gdb -q -x auto.py.gdb
Temporary breakpoint 1 at 0x400678: file main.c, line 4.

Temporary breakpoint 1, main () at main.c:4
4 xyz = 100;
From To Syms Read Shared Object Library
0x00007ffff7ddcaf0 0x00007ffff7df555a Yes (*) /lib64/ld-linux-x86-64.so.2
0x00007ffff7bda500 0x00007ffff7bda628 Yes /home/hfu/codes/plt/libtest.so
0x00007ffff7859b80 0x00007ffff797ff6c Yes /lib/x86_64-linux-gnu/libc.so.6
(*): Shared library is missing debugging information.
add symbol table from file "/usr/lib/debug/lib/x86_64-linux-gnu/ld-2.13.so" at
.text_addr = 0x7ffff7ddcaf0
_dl_runtime_resolve in section .text of /usr/lib/debug/lib/x86_64-linux-gnu/ld-2.13.so
(gdb)
```

Looks better...
