---
layout: post
title: RPM Value Evaluation with Dummy Spec File
categories:
- post
---

I was once work on packaging things into rpm and sometimes I want to evaluate a rpm spec expression just as python has a shell ...

---

* We can first create a dummy spec file "x.spec"

```spec
Name:           dummy
Version:        0.0.0
Release:        1
License:        GPLv2
Group:          Dummy
Summary:        Dummy

%description
Dummy

%prep

%if  "1" == "1" && "0" != "0" || "0" == "0"
%define xxxx %(echo whatx)
%endif
%define yyyy %(echo whaty)

%if "$(uname -r)" == "2.6.9-89.EL"
echo %{xxxx}
%endif

```

* Then put any expression you want to test inside the `prep` section. Evaluate it with

```bash
rpmbuild -bp x.spec
```

### rpmrebuild ###

another very useful tool is [__rpmrebuild__](http://rpmrebuild.sourceforge.net/usage.html), which can be used to edit package spec file on the fly.
