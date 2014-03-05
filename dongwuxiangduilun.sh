#!/bin/bash

# 当前目录
cwd=$(cd "$(dirname "$0")"; pwd);
cd $cwd

# 定义访问的token
limit_rate="10M"
token="1000577&595255ba04ea40444408a66055dff7d991fe"
entoken=$(echo ${token} | sed 's/&/%26/')
album_id="215922"
categories="8"
tags="冬吴相对论,梁冬,吴伯凡,脱口秀,商业经济"
image='{"status":true,"data":[{"processResult":{"100":"group3/M00/5B/AB/wKgDsVJv2BSx05h1AAJQbO-QVCs998_web_meduim.jpg","180":"group3/M00/5B/AB/wKgDsVJv2BSx05h1AAJQbO-QVCs998_web_large.jpg","640":"group3/M00/5B/AB/wKgDsVJv2BSx05h1AAJQbO-QVCs998_mobile_large.jpg","180n_width":"180","origin":"group3/M00/5B/AB/wKgDsVJv2BSx05h1AAJQbO-QVCs998.jpg","640_width":"640","640_height":"640","100_width":"100","100_height":"100","uploadId":1430930,"180n":"group3/M00/5B/AB/wKgDsVJv2BSx05h1AAJQbO-QVCs998_web_explore.jpg","180_height":"180","180n_height":"180","180_width":"180"},"uploadTrack":{"id":1430930,"uid":1000577,"type":3,"url":"group3/M00/5B/AB/wKgDsVJv2BSx05h1AAJQbO-QVCs998.jpg","fileName":"wKgDslJuE9XQXcldAAJQbO-QVCs682.jpg","fileSize":151660,"ip":"101.80.140.131","isUsed":false,"recordId":null,"createdAt":1383061524159,"updatedAt":1383061524159,"hasSendTopic":false,"isFeed":true,"topicType":1,"waveform":null,"exploreHeight":180,"limit":null,"shard":null}}]}'

last_num_pk_file=${cwd}"/last_num.pk"
if [ -f "${last_num_pk_file}" ]; then
	last_num=$(cat ${last_num_pk_file})
else
	last_num="411"
fi


last_num=$(expr ${last_num} + 2)
last_num_pk=$last_num

line_num=1
audio_name=""
intro=""
down_url=""
curl -s -i "http://dongwu.21cbr.com/" | iconv -f gb2312 -t utf-8 -c | grep -E '<div id="(mainContent_dongwu_mid_left_top_title|mainContent_dongwu_mid_left_top_info)">|soundPlayer\("' | sed 's/<[^>]*>//g' | while read -r line; do	
	node_num=$(expr ${line_num} % 3)
	#echo $line
	if [ "$node_num" = "1" ]; then
		audio_name=$(echo $line | sed 's/冬吴相对论//' | sed 's/《//' | sed 's/》//' | sed 's/:/ - /' | sed 's/\s//g')
	elif [ "$node_num" = "2" ]; then
		intro=$line
	elif [ "$node_num" = "0" ]; then
		down_url=$(echo $line | awk -F '"' '{print $2}')
		file_isok=$(curl -s -I "${down_url}?v="$(date +'%s') | head -n 1 | grep -E 'HTTP\/1\.[0-9] 200 OK' | wc -l)
		file_isok=$(echo $file_isok | sed 's/\s//g')
		lock_file=${cwd}"/dwxdl_"${last_num}".lock"
		# 检查回放中文名称是否准备好
		name_isok=$(echo $audio_name | grep ${last_num} | wc -l)
		name_isok=$(echo $name_isok | sed 's/\s//g')
		
		echo audio_name: $audio_name
		echo intro: $intro
		echo name_isok: $name_isok
		echo down_url: $down_url
		
		# 声音文件不存在且中文名称已经准备好，可以下载
		if [ ! -f "${lock_file}" ] && [ "$name_isok" = "1" ] && [ "$file_isok" = "1" ]; then
			# 下载音频文件
			wget -c "$down_url" -O "${audio_name}.mp3" --limit-rate ${limit_rate}
			# 上传音频文件
			result=$(curl -F "Filename=${audio_name}.mp3" --limit-rate ${limit_rate} -F "Filedata=@${cwd}/${audio_name}.mp3" "http://upload.ximalaya.com/dtres/audio/upload?token=${entoken}&rememberMe=y")
			# 获取上传的音频ID
			fileid=$(echo $result | awk -F ',' '{print $8}' | awk -F ':' '{print $3}')
			# 启动转码
			curl -s -i -H "Cookie: 1&remember_me=y; 1&_token=${token}; " "http://www.ximalaya.com/dtres/transcoding/process?id=${fileid}"
			# 提交到专辑里
			curl -s -i -H "Cookie: 1&remember_me=y; 1&_token=${token}; " -d "categories=${categories}&fileids[]=${fileid}&album_id=${album_id}&is_public=1&tags=${tags}&title=${audio_name}&user_source=2&rich_intro=${intro}&intro=${intro}&image[]=${image}" "http://www.ximalaya.com/upload/create" 
			# 输出当前日期和时间
	        echo $(date +'%F %T') > ${lock_file}			
		
			# 启动转码
	        for((i=1;i<=10;i++)); do
	        	sleep 1
	            curl -s -i -H "Cookie: 1&remember_me=y; 1&_token=${token}; " "http://www.ximalaya.com/dtres/transcoding/process?id=${fileid}"
	        done
		
		echo ${last_num_pk} > ${last_num_pk_file}
		
		fi
		last_num=$(expr ${last_num} - 1)
		
		
		# 删除文件
		if [ -f "${audio_name}.mp3" ]; then
			rm -fr "${audio_name}.mp3"
		fi
	fi
	line_num=$(expr ${line_num} + 1)
done
