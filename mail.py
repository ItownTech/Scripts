#!/usr/bin/env python
# -*- coding: UTF-8 -*-
 
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email.mime.text import MIMEText

# python 2.3.*: email.Utils email.Encoders
from email.utils import COMMASPACE,formatdate
from email import encoders

import os,sys


server = {'host':'smtp.163.com','user':'qdlxs2001','passwd':'Lukin262865'}
fro = 'qdlxs2001@163.com'
# 收件人
to = sys.argv[1].split(',')
# 抄送
cc = []
try:
    if sys.argv[2] != '' :
        cc = sys.argv[2].split(',')
except IndexError:
    pass

# 标题
subject = sys.argv[3]
# 内容
text = sys.argv[4]
# 附件
files = []
try:
    if sys.argv[5] != '' :
        files = sys.argv[5].split(',')
except IndexError:
    pass

# 密送
bcc = []
try:
    if sys.argv[6] != '' :
        bcc = sys.argv[6].split(',')
except IndexError:
    pass

assert type(server) == dict
assert type(to) == list
assert type(cc) == list
assert type(bcc) == list
assert type(files) == list



msg = MIMEMultipart()
msg['From'] = fro
msg['Subject'] = subject
msg['To'] = COMMASPACE.join(to) #COMMASPACE==', '
msg['Cc'] = COMMASPACE.join(cc) #COMMASPACE==', '
msg['Bcc'] = COMMASPACE.join(bcc) #COMMASPACE==', '
msg['Date'] = formatdate(localtime=True)
msg.attach(MIMEText(text))

for file in files:
    part = MIMEBase('application', 'octet-stream') #'octet-stream': binary data
    part.set_payload(open(file, 'rb'.read()))
    encoders.encode_base64(part)
    part.add_header('Content-Disposition', 'attachment; filename="%s"' % os.path.basename(file))
    msg.attach(part)

import smtplib
smtp = smtplib.SMTP(server['host'])
smtp.login(server['user'], server['passwd'])
smtp.sendmail(fro, to+cc+bcc, msg.as_string())
smtp.close()
