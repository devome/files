#!/usr/bin/env bash

set -o pipefail

## 目录
dir_operator=$(dirname $(readlink -f "$0"))
file_db=$dir_operator/zxipv6wry.db
file_ipv6_all=$(mktemp)
china=中国
file_ipv6_china=$dir_operator/${china}.txt
operators=(${china}电信 ${china}联通_${china}网通 ${china}移动_${china}铁通 长城宽带_鹏博士)

## 省份
provinces=(
    北京
    天津
    河北
    山西
    内蒙古
    辽宁
    吉林
    黑龙江
    上海
    江苏
    浙江
    安徽
    福建
    江西
    山东
    河南
    湖北
    湖南
    广东
    广西
    海南
    重庆
    四川
    贵州
    云南
    西藏
    陕西
    甘肃
    青海
    宁夏
    新疆
    台湾
    香港
    澳门
)


## 检查文件是否变化
if [[ $(sha256sum $file_db) == $(cat $dir_shell/zxipv6wry.db.sha256sum 2>/dev/null) ]]; then
    echo "$file_db 的 sha256 未变化，与上一次一致"
    exit 0
fi

## 输出中国IPv6
ips scan "$file_db" -o "$file_ipv6_all"
grep -P "${china}" $file_ipv6_all > $file_ipv6_china
rm "$file_ipv6_all"

## 输出分省数据
for operator in ${operators[@]}; do
    if [[ ! -d "${dir_operator}/${operator}" ]]; then
        mkdir -p "${dir_operator}/${operator}"
    fi
    for province in ${provinces[@]}; do
        grep -P "\t${china}\t${province}.+(${operator/_/|})" $file_ipv6_china | awk '{print $1}' | cidr-merger > "${dir_operator}/${operator}/${province}.txt"
    done
    grep -P "\t${china},(${operator/_/|})" $file_ipv6_china | awk '{print $1}' | cidr-merger > "${dir_operator}/${operator}/未知省份.txt"
done

## 删除空文件
find $dir_operator -type f | while read file; do
    if [[ ! -s "$file" ]]; then
        rm "$file"
    fi
done

## 记录sha256
sha256sum $file_db > $dir_operator/zxipv6wry.db.sha256sum
