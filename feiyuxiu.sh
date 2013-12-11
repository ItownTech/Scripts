#!/bin/bash
# 飞鱼秀节目下载
# */5 12-18 * * 1-5 /bin/bash /home/lukin/bin/feiyuxiu.sh
# 当前目录
cwd=$(cd "$(dirname "$0")"; pwd);
cd $cwd

if [ -n "$1" ]; then
	today=$1
else
	today=$(date +'%Y%m%d')
fi



# 定义访问的token
token="3839232&6834906d02c4504aff096tc0c73f63634dee"
entoken=$(echo ${token} | sed 's/&/%26/')
# 定义回放文件名
filename="${today:0:4}/ezm${today:2}.mp3"
# 判断回放的文件是否上传完毕
file_isok=$(curl -s -I "http://mod.cri.cn/eng/ez/morning/${filename}?v="$(date +'%s') | head -n 1 | grep -E 'HTTP\/1\.[0-9] 200 OK' | wc -l)
file_isok=$(echo $file_isok | sed 's/\s//g')

lock_file=${cwd}"/feiyuxiu_"$today".lock"
# 回放文件已经准备好
if [ "$file_isok" = "1" ]; then
	# 获取回放中文名称
	#audio_name=$(curl -s "http://english.cri.cn/4926/more/10679/more10679.htm" | iconv -f gb2312 -t utf-8 | grep '<div id="more" class="more" ><table width="100%">' | awk -F '>' '{print $6}' | sed 's/<\/a//' | sed 's/飞鱼秀-/飞鱼秀 /' | sed 's/-//g')
	audio_name=$(curl -s "http://english.cri.cn/4926/more/10679/more10679.htm" | iconv -f gb2312 -t utf-8 | grep -E "<tr><td valign=top>.*<a href='/.*\.htm'>飞鱼秀\-.*</a>" | grep -v '<div class="pad font1">' | sed 's/飞鱼秀-/飞鱼秀 /' | sed 's/-//g' | sed 's/            <div id="more" class="more" ><table width="100%">/<\/td><\/tr>/g' | grep $today | awk -F '>' '{print $6}' | sed 's/<\/a//')
	
	# 检查回放中文名称是否准备好
	name_isok=$(echo $audio_name | grep $today | wc -l)
	name_isok=$(echo $name_isok | sed 's/\s//g')
	# 声音文件不存在且中文名称已经准备好，可以下载
	if [ ! -f "${lock_file}" ] && [ "$name_isok" = "1" ]; then
		# 下载音频文件
		wget -c "http://mod.cri.cn/eng/ez/morning/${filename}?v="$(date +'%s') -O "${audio_name}.mp3" --limit-rate 1M
		# 上传音频文件
		result=$(curl -F "Filename=${audio_name}.mp3" --limit-rate 1M -F "Filedata=@${cwd}/${audio_name}.mp3" "http://upload.ximalaya.com/dtres/audio/upload?token=${entoken}&rememberMe=y")
		# 获取上传的音频ID
		fileid=$(echo $result | awk -F ',' '{print $8}' | awk -F ':' '{print $3}')
		# 启动转码
		curl -s -i -H "Cookie: 1&remember_me=y; 1&_token=${token}; " "http://www.ximalaya.com/dtres/transcoding/process?id=${fileid}"
		# 提交到专辑里
		curl -s -i -H "Cookie: 1&remember_me=y; 1&_token=${token}; " -d "categories=17&fileids[]=${fileid}&album_id=214736&is_public=1&tags=飞鱼秀,喻舟,小飞&title=${audio_name}&user_source=2&image[]=%7B%22status%22%3Atrue%2C%22data%22%3A%5B%7B%22processResult%22%3A%7B%22100%22%3A%22group3%2FM01%2F54%2F10%2FwKgDsVJmldbAAWeSAAFyxZd545o085_web_meduim.jpg%22%2C%22180%22%3A%22group3%2FM01%2F54%2F10%2FwKgDsVJmldbAAWeSAAFyxZd545o085_web_large.jpg%22%2C%22640%22%3A%22group3%2FM01%2F54%2F10%2FwKgDsVJmldbAAWeSAAFyxZd545o085_mobile_large.jpg%22%2C%22180n_width%22%3A%22180%22%2C%22origin%22%3A%22group3%2FM01%2F54%2F10%2FwKgDsVJmldbAAWeSAAFyxZd545o085.jpg%22%2C%22640_width%22%3A%22640%22%2C%22640_height%22%3A%22640%22%2C%22100_width%22%3A%22100%22%2C%22100_height%22%3A%22100%22%2C%22uploadId%22%3A1376263%2C%22180n%22%3A%22group3%2FM01%2F54%2F10%2FwKgDsVJmldbAAWeSAAFyxZd545o085_web_explore.jpg%22%2C%22180_height%22%3A%22180%22%2C%22180n_height%22%3A%22135%22%2C%22180_width%22%3A%22180%22%7D%2C%22uploadTrack%22%3A%7B%22id%22%3A1376263%2C%22uid%22%3A3048392%2C%22type%22%3A3%2C%22url%22%3A%22group3%2FM01%2F54%2F10%2FwKgDsVJmldbAAWeSAAFyxZd545o085.jpg%22%2C%22fileName%22%3A%221bc8858982f77762500b57a88f190faf.jpg%22%2C%22fileSize%22%3A94917%2C%22ip%22%3A%22222.65.181.203%22%2C%22isUsed%22%3Afalse%2C%22recordId%22%3Anull%2C%22createdAt%22%3A1382454742302%2C%22updatedAt%22%3A1382454742302%2C%22hasSendTopic%22%3Afalse%2C%22isFeed%22%3Atrue%2C%22topicType%22%3A1%2C%22waveform%22%3Anull%2C%22exploreHeight%22%3A135%2C%22limit%22%3Anull%2C%22shard%22%3Anull%7D%7D%5D%7D" "http://www.ximalaya.com/upload/create" 
		# 输出当前日期和时间
        echo $(date +'%F %T') > ${lock_file}
		
		# 启动转码
		for((i=1;i<=10;i++)); do
			sleep 1
                	curl -s -i -H "Cookie: 1&remember_me=y; 1&_token=${token}; " "http://www.ximalaya.com/dtres/transcoding/process?id=${fileid}"
		done
	fi
	
	# 删除文件
	if [ -f "${audio_name}.mp3" ]; then
		rm -fr "${audio_name}.mp3"
	fi
fi

