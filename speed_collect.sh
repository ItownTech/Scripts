#!/bin/bash --login
# 部署在：app10-045 /home/evans/bin/speed_collect.sh
# crontab -e
#   01 3 * * * /home/evans/bin/speed_collect.sh >> /home/evans/bin/speed_collect.log

# 当前目录
cwd=$(cd "$(dirname "$0")"; pwd);

d_date=`date +'%Y%m%d' -d '1 day ago'`

echo $d_date

# 分析大于200ms的url
cat /data1/logs/lb10-002/access.log-$d_date \
	| awk '{if ($1>=0.3 && $8=="my.anjuke.com"){ print $0 }}' \
	| awk '{print $10}' \
	| awk -F '?' '{print $1}' \
	| awk -F 'W0QQ' '{print $1}' \
	| awk -F 'w0qq' '{print $1}' \
	| grep -Ev '(\/listptab\-|\/(res|tools|v2|duankou|tycoon|community)\/)' \
	| grep -Ev '\.(php|js|css|png|jpg|gif|tar|rar|zip|html|bmp|ico|csv)' \
	| sed 's/\/\([0-9]\+\)//' | sed 's/\/$//' | sed 's/\/\([0-9]\+\)//' \
	| sort | uniq -c| sort -rn -k 1 > $cwd"/myspeed_"$d_date".log"

# 分析所有url请求次数
cat /data1/logs/lb10-002/access.log-$d_date \
	| awk '{if ($8=="my.anjuke.com"){ print $0 }}' \
	| awk '{print $10}' \
	| awk -F '?' '{print $1}' \
	| awk -F 'W0QQ' '{print $1}' \
	| awk -F 'w0qq' '{print $1}' \
	| grep -Ev '(\/listptab\-|\/(res|tools|v2|duankou|tycoon|community)\/)' \
	| grep -Ev '\.(php|js|css|png|jpg|gif|tar|rar|zip|html|bmp|ico|csv)' \
	| sed 's/\/\([0-9]\+\)//' | sed 's/\/$//' | sed 's/\/\([0-9]\+\)//' \
	| sort | uniq -c| sort -rn -k 1 > $cwd"/mypv_"$d_date".log"

# 拷贝文件到本地
scp $cwd"/myspeed_"$d_date".log" lukin@192.168.191.89:~/Projects/dh.corp.anjuke.com/logs/
scp $cwd"/mypv_"$d_date".log" lukin@192.168.191.89:~/Projects/dh.corp.anjuke.com/logs/

ssh lukin@192.168.191.89 "/usr/bin/php /home/lukin/Projects/dh.corp.anjuke.com/jobs/run.php ParseSpeed ${d_date} > /home/lukin/Projects/dh.corp.anjuke.com/ParseSpeed.log"
