---
layout: post
title: Bash String Manipulation
categories:
- post
---

```bash
#!/bin/bash
#basic string manipulation in shell script

set -v

s=" hello world! racn4 "
#  01234567890123456789

# length
echo ${#s}
expr length "$s"

# find substring index
ss='world'
expr index "$s" $ss

# substr
echo ${s:14}
echo ${s:14:4}
echo ${s:(-2)}

# match
[[ $s =~ "o.*o" ]] && echo "yes"
(echo $s | grep -q "o.*o") && echo "yes"

# trim space
s=${s%% }
s=${s## }
echo "<${s}>"

# basic replace
echo ${s/o/O}
echo ${s/#h/O}
echo ${s/%racn4/O}
echo ${s//o/O}

# trim (pre|post)fix
# hard to remember? Hah! look at your keyboard ..  
echo ${s#h*o}
echo ${s##h*o}
echo ${s%o*4}
echo ${s%%o*4}

# upper/lower case
echo $(tr 'a-z' 'A-Z' <<< $s)

# comparation
[[ $s > "hello" ]] && echo "hello"

# number conversion
x="2"; y=3
echo $(($x + $y))
```

## Reference

* Advanced Bash Scripting Guide, http://tldp.org/LDP/abs/html/refcards.html
* PLEAC - Programming Language Examples Alike Cookbook, http://pleac.sourceforge.net/
* http://rosettacode.org/wiki/Category:Programming_Tasks
* http://langref.org/
* http://www.codecodex.com/wiki/Main_Page
