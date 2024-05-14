#!/bin/bash

containers=$(docker ps -q)

for container in $containers; do
    
    image=$(docker inspect --format '{{.Config.Image}}' $container)

    if [[ "$image" == "vaxilu/soga:2.10.2" ]]; then
        
        mounts=$(docker inspect --format '{{range .HostConfig.Binds}}{{println .}}{{end}}' $container)

        echo "容器 $container 的挂载信息：$mounts"

        mount=""

        
        while IFS= read -r line; do
            source=$(echo $line | cut -d':' -f1)
            destination=$(echo $line | cut -d':' -f2)

            if [[ "$destination" == "/etc/soga/" ]]; then
                mount=$source
                break
            fi
        done <<< "$mounts"
        mount=$(echo $mount | sed 's:/*$::')

        echo "容器 $container 的挂载目录：$mount"

        
        if [[ -n "$mount" ]]; then
            
            wget -O "$mount/geosite.dat" https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat
            wget -O "$mount/geoip.dat" https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat
            
            docker restart $container
        else
            echo "未找到容器 $container 的挂载目录"
        fi
    fi
done
