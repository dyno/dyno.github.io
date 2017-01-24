---
layout: post
title: Python - Working With Time
categories:
- post
---

## Time String <=> Seconds Since Epoc

```python
from time import (tzset,
    strptime, strftime,
    mktime,
    localtime, gmtime)
from calendar import timegm

format = "%Y-%m-%dT%H:%M:%S%p"

#os.environ['TZ'] = "US/Pacific"
#tzset()

ts = "2017-01-23T11:43:40PM"
st = strptime(ts, format)

# as local time
print("%s => %d" % (ts, mktime(st)))
# 2017-01-23T11:43:40PM => 1485200620

# as utc time
print("%s => %d" % (ts, timegm(st)))
# 2017-01-23T11:43:40PM => 1485171820

epoc = 1485200620

# to local time
t = localtime(epoc)
print("%d => %s" % (epoc, strftime(format, t)))
# 1485200620 => 2017-01-23T11:43:40AM

# to utc time
t = gmtime(epoc)
print("%d => %s" % (epoc, strftime(format, t)))
# 1485200620 => 2017-01-23T19:43:40PM
```

## Working With Timezone (without 3rd party lib)

```python
from time import localtime, tzset, gmtime, strptime
from calendar import timegm

timezones = ["Asia/Shanghai", "America/Los_Angeles", "GMT"]
for tz in timezones:
    os.environ['TZ'] = tz
    tzset()

    for time_str in (
            "2017-01-23T11:43:40PM", # daylight saving time
            "2017-04-23T11:43:40PM"
            ):
        st = strptime(time_str, "%Y-%m-%dT%H:%M:%S%p")
        as_local = mktime(st)
        as_utc = timegm(st)
        offset = as_utc - as_local

        print("%s => UTC %+03d%02d" % (tz, offset/60/60, offset/60%30))

#Asia/Shanghai => UTC +0800
#Asia/Shanghai => UTC +0800
#America/Los_Angeles => UTC -0800
#America/Los_Angeles => UTC -0700
#GMT => UTC +0000
#GMT => UTC +0000
```

## Reference

* <https://wiki.python.org/moin/WorkingWithTime>
* <https://docs.python.org/3/library/time.html>
* <https://docs.python.org/3/library/datetime.html>
* <https://pypi.python.org/pypi/pytz>

