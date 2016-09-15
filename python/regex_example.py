# -*- coding: utf-8 -*-
import re

t = "\"productId\":\"111111\""
m = re.match("\W*productId[^:]*:\D*(\d+)", t)
if m:
    print m.group(1)

t = u"学历认证：（毕业学校：海南政法职业学院，学历：专科，学习形式：普通）"
m = re.match(u".*(学历认证：（毕业学校：)([^，]*)", t)
if m:
    print m.group(2)

t = "学历认证：（毕业学校：渤海大学，学历：本科，学习形式：普通）"
m = re.match(".*学历认证：（毕业学校：([^，]*)，", t)
if m:
    print m.group(1)

t = "学历认证：（毕业学校：渤海大学，学历：本科，学习形式：普通）"
m = re.match(".*学历：([^，]*)，", t)
if m:
    print m.group(1)



print "ab" in "abcd"

t = u"正常还清：8 次，逾期还清(1-15)：9 次，逾期还清(>15)：10 次"
m = re.match(u".*逾期还清\(1-15\)：(\d+).*次，", t)
if m:
    print m.group(1)