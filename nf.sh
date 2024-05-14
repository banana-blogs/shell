#!/bin/bash

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

NAME="$(hostname)正在解锁"
MODE=1
NETFLIX=0
GOOGLE=1
DISNEY=0
DNSMasq=0
AfterAPI=1
APIWait=30
WGName="wgcf"
awsinstance="Debian-1"
awsregion="ap-northeast-1"
awsip="temp-1"
API="10.43.97.5/change"
# AfterAPIURL="https://985.moe/api/ddns/hktxpon1.php?key=VqUwqMjFrxZC7zn&ip="
TG_BOT_TOKEN="5814110654:AAER1dY0EyNzhJk3OBoBOlb9kUnelCm1y5g"
TG_CHATID=1202863302

VERSION=3.2.4
COUNT=0
NetflixStatus=1
GoogleStatus=1
DisneyStatus=1
SESSION=/usr/local/bin/.netflix_session
UA_Browser="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36"

echo=echo
for cmd in echo /bin/echo; do
    $cmd >/dev/null 2>&1 || continue
    if ! $cmd -e "" | grep -qE '^-e'; then
        echo=$cmd
        break
    fi
done

CSI=$($echo -e "\033[")
CEND="${CSI}0m"
CDGREEN="${CSI}32m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"
CYELLOW="${CSI}1;33m"
CBLUE="${CSI}1;34m"
CMAGENTA="${CSI}1;35m"
CCYAN="${CSI}1;36m"

OUT_SUCCESS() {
    echo -e "${CGREEN}$1${CEND}"
}

OUT_ALERT() {
    echo -e "${CYELLOW}$1${CEND}"
}

OUT_ERROR() {
    echo -e "${CRED}$1${CEND}"
}

OUT_INFO() {
    echo -e "${CCYAN}$1${CEND}"
}

function Initialize {
    if [ -f $SESSION ]; then
        OUT_ERROR "[错误] 发现存在的 Session 文件！退出中"
        exit 0
    else
        echo "" > $SESSION
    fi
    PythonStatus=$(command -v python)
    if [ -n "$PythonStatus" ]; then
        sleep 0
    else
        OUT_ERROR "[错误] 没有安装 Python！正在安装"
        if [[ ${release} == "centos" ]]; then
            yum install python -y >/dev/null 2>&1
        else
            apt-get install python -y >/dev/null 2>&1
        fi
    fi
    OUT_INFO "欢迎使用印度佬手动换IP助手 v${VERSION}"
    if [[ $MODE -eq 1 ]]; then
        iface=$(ip -o -4 route show to default | awk '{print $5}' | head -n 1)
	useNIC="--interface $iface"
        OUT_INFO "[提示] 模式: DHCP 更换 IP"
    elif [[ $MODE -eq 2 ]]; then
        iface=$(ip -o -4 route show to default | awk '{print $5}' | head -n 1)
	useNIC="--interface $iface"
        OUT_INFO "[提示] 模式: API 多次更换 IP"
    elif [[ $MODE -eq 3 ]]; then
        iface=$(ip -o -4 route show to default | awk '{print $5}' | head -n 1)
	useNIC="--interface $iface"
        OUT_INFO "[提示] 模式: API 单次更换 IP"
    elif [[ $MODE -eq 4 ]]; then
        iface=$(ip -o -4 route show to default | awk '{print $5}' | head -n 1)
	useNIC="--interface $WGName"
        OUT_INFO "[提示] 模式: Cloudflare WARP 更换 IP"
    elif [[ $MODE -eq 5 ]]; then
        iface=$(ip -o -4 route show to default | awk '{print $5}' | head -n 1)
	useNIC="--interface $iface"
        OUT_INFO "[提示] 模式: AWS-CLI 更换 IP"
    else
        OUT_ERROR "[错误] 模式设置错误！退出中"
        Terminate
    fi
    Test
}

function Test {
    if [[ $NETFLIX -eq 1 ]]; then
        Test_Netflix
    fi
    if [[ $GOOGLE -eq 1 ]]; then
        Test_Google
    fi
    if [[ $DISNEY -eq 1 ]]; then
        Test_Disney
    fi
    Analyze
}

function Test_Netflix {
    local result=$(curl $useNIC -4 --user-agent "${UA_Browser}" -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://www.netflix.com/title/70143836" 2>&1)
    if [[ "$result" == "404" ]]; then
        NetflixResult="Originals Only"
        NetflixStatus=0
        OUT_ERROR "[错误] Netflix 解锁: $NetflixResult"
    elif [[ "$result" == "403" ]]; then
        NetflixResult="No"
        NetflixStatus=0
        OUT_ERROR "[错误] Netflix 解锁: $NetflixResult"
    elif [[ "$result" == "200" ]]; then
	local region=`tr [:lower:] [:upper:] <<< $(curl $useNIC -4 --user-agent "${UA_Browser}" -fs --max-time 10 --write-out %{redirect_url} --output /dev/null "https://www.netflix.com/title/80018499" | cut -d '/' -f4 | cut -d '-' -f1)` ;
	if [[ ! -n "$region" ]]; then
	    region="US";
        fi
	NetflixResult="Yes (Region: ${region})"
        NetflixStatus=1
	OUT_SUCCESS "[提示] Netflix 解锁: $NetflixResult"
    elif [[ "$result" == "000" ]]; then
        if [[ $MODE -eq 4 ]]; then
            NetflixStatus=0
        fi
	NetflixResult="Failed (Network Connection)"
        OUT_ERROR "[错误] Netflix 解锁: $NetflixResult"
    fi
}

function Test_Google {
    local tmpresult=$(curl $useNIC --user-agent "${UA_Browser}" -4 --max-time 10 -sSL -H "Accept-Language: en" -b "YSC=BiCUU3-5Gdk; CONSENT=YES+cb.20220301-11-p0.en+FX+700; GPS=1; VISITOR_INFO1_LIVE=4VwPMkB7W5A; PREF=tz=Asia.Shanghai; _gcl_au=1.1.1809531354.1646633279" "https://www.youtube.com/premium" 2>&1)
    local isCN=$(echo $tmpresult | grep 'www.google.cn')
    local isNotAvailable=$(echo $tmpresult | grep 'Premium is not available in your country')
    if [ -n "$isCN" ] || [ -n "$isNotAvailable" ]; then
        GoogleResult="送中"
        GoogleStatus=0
        OUT_ERROR "[错误] Google 定位: $GoogleResult"
    else
        GoogleResult="没有送中"
        GoogleStatus=1
        OUT_SUCCESS "[提示] Google 定位: $GoogleResult"
    fi
}

function Test_Disney {
    local PreAssertion=$(curl $useNIC -4 --user-agent "${UA_Browser}" -s --max-time 10 -X POST "https://global.edge.bamgrid.com/devices" -H "authorization: Bearer ZGlzbmV5JmJyb3dzZXImMS4wLjA.Cu56AgSfBTDag5NiRA81oLHkDZfu5L3CKadnefEAY84" -H "content-type: application/json; charset=UTF-8" -d '{"deviceFamily":"browser","applicationRuntime":"chrome","deviceProfile":"windows","attributes":{}}' 2>&1)
    local assertion=$(echo $PreAssertion | python -m json.tool 2> /dev/null | grep assertion | cut -f4 -d'"')
    local PreDisneyCookie=$(curl -s --max-time 10 "https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/cookies" | sed -n '1p')
    local disneycookie=$(echo $PreDisneyCookie | sed "s/DISNEYASSERTION/${assertion}/g")
    local TokenContent=$(curl $useNIC -4 --user-agent "${UA_Browser}" -s --max-time 10 -X POST "https://global.edge.bamgrid.com/token" -H "authorization: Bearer ZGlzbmV5JmJyb3dzZXImMS4wLjA.Cu56AgSfBTDag5NiRA81oLHkDZfu5L3CKadnefEAY84" -d "$disneycookie")
    local isBanned=$(echo $TokenContent | python -m json.tool 2> /dev/null | grep 'forbidden-location')
    local is403=$(echo $TokenContent | grep '403 ERROR')
    if [ -n "$isBanned" ] || [ -n "$is403" ];then
	DisneyResult="No"
        DisneyStatus=0
        OUT_ERROR "[错误] Disney 解锁: $DisneyResult"
	return;
    fi
    local fakecontent=$(curl -s --max-time 10 "https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/cookies" | sed -n '8p')
    local refreshToken=$(echo $TokenContent | python -m json.tool 2> /dev/null | grep 'refresh_token' | awk '{print $2}' | cut -f2 -d'"')
    local disneycontent=$(echo $fakecontent | sed "s/ILOVEDISNEY/${refreshToken}/g")
    local tmpresult=$(curl $useNIC -4 --user-agent "${UA_Browser}" -X POST -sSL --max-time 10 "https://disney.api.edge.bamgrid.com/graph/v1/device/graphql" -H "authorization: ZGlzbmV5JmJyb3dzZXImMS4wLjA.Cu56AgSfBTDag5NiRA81oLHkDZfu5L3CKadnefEAY84" -d "$disneycontent" 2>&1)
    local previewcheck=$(curl $useNIC -4 -s -o /dev/null -L --max-time 10 -w '%{url_effective}\n' "https://disneyplus.com" | grep preview)
    local isUnabailable=$(echo $previewcheck | grep 'unavailable')
    local region=$(echo $tmpresult | python -m json.tool 2> /dev/null | grep 'countryCode' | cut -f4 -d'"')
    local inSupportedLocation=$(echo $tmpresult | python -m json.tool 2> /dev/null | grep 'inSupportedLocation' | awk '{print $2}' | cut -f1 -d',')
    if [[ "$region" == "JP" ]];then
        DisneyResult="Yes (Region: $region)"
        DisneyStatus=1
        OUT_SUCCESS "[提示] Disney 解锁: $DisneyResult"
    elif [ -n "$region" ] && [[ "$inSupportedLocation" == "false" ]] && [ -z "$isUnabailable" ];then
        DisneyResult="Available For [Disney+ $region] Soon"
        DisneyStatus=1
        OUT_SUCCESS "[提示] Disney 解锁: $DisneyResult"
    elif [ -n "$region" ] && [ -n "$isUnavailable" ];then
	DisneyResult="No"
        DisneyStatus=0
        OUT_ERROR "[错误] Disney 解锁: $DisneyResult"
    elif [ -n "$region" ] && [[ "$inSupportedLocation" == "true" ]];then
	DisneyResult="Yes (Region: $region)"
        DisneyStatus=1
        OUT_SUCCESS "[提示] Disney 解锁: $DisneyResult"
    elif [ -z "$region" ];then
	DisneyResult="No"
        DisneyStatus=0
        OUT_ERROR "[错误] Disney 解锁: $DisneyResult"
    else
	DisneyResult="Failed"
        OUT_ERROR "[错误] Disney 解锁: $DisneyResult"
    fi
}

function Analyze {
    if [[ $NetflixStatus -eq 0 ]] || [[ $GoogleStatus -eq 0 ]] || [[ $DisneyStatus -eq 0 ]]; then
        ChangeIP
    else
        AfterCheck
    fi
}

function ChangeIP {
    if [[ $COUNT -eq 0 ]]; then
        SendStartMsg
    fi
    let COUNT++
    OUT_ALERT "[提示] 正在尝试第 $COUNT 次更换 IP 地址"
    if [[ $MODE -eq 1 ]]; then
        dhclient -r -v >/dev/null 2>&1
        rm -rf /var/lib/dhcp/dhclient*
        ps aux | grep dhclient | grep -v grep | awk -F ' ' '{print $2}' | xargs kill -9 2>/dev/null
        sleep 5s
        dhclient -v >/dev/null 2>&1
        sleep 5s
        Test
    elif [[ $MODE -eq 2 ]]; then
        curl -fsSL $API > /dev/null 2>&1
        sleep ${APIWait}s
        Test
    elif [[ $MODE -eq 3 ]]; then
        rm -rf $SESSION
        curl $API > /dev/null 2>&1
    elif [[ $MODE -eq 4 ]]; then
        wg-quick down $WGName >/dev/null 2>&1
        sleep 2s
        wg-quick up $WGName >/dev/null 2>&1
        Test
    elif [[ $MODE -eq 5 ]]; then
        aws lightsail allocate-static-ip --static-ip-name ${awsip} --region ${awsregion} >/dev/null 2>&1
        aws lightsail attach-static-ip --static-ip-name ${awsip} --instance-name ${awsinstance} --region ${awsregion} >/dev/null 2>&1
        aws lightsail release-static-ip --static-ip-name ${awsip} --region ${awsregion} >/dev/null 2>&1
        Test
    fi
}

function AfterCheck {
    if [[ $COUNT -eq 0 ]]; then
        OUT_SUCCESS "[提示] 无发现错误！退出中"
        Terminate
    else
        SendEndMsg
        if [[ $DNSMasq -eq 1 ]]; then
            ChangeDNS
        fi
        if [[ $AfterAPI -eq 1 ]]; then
            AfterAPI
        fi
        OUT_SUCCESS "[提示] 更换 IP 地址成功！退出中"
        Terminate
    fi
}

function ChangeDNS {
    PresentIP=$(curl -4 -fsL http://ip.sb)
    sed -ri "s/\/[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/\/$PresentIP/g" /etc/dnsmasq.d/custom_netflix.conf
    systemctl restart dnsmasq
    OUT_SUCCESS "[提示] 修改 DNS 解锁 IP 地址成功！"
}

function AfterAPI {
    # PresentIP=$(curl -4 -fsL http://ip.sb)
    # AfterAPIURL+="${PresentIP}"
     /usr/sbin/AliDDNS-v2.0.sh run
}

function SendStartMsg {
    TIME1=$(date +%Y-%m-%d)
    TIME2=$(date +%H:%M:%S)
    TIME=$TIME1+$TIME2+"[UTC %2B8]"
    STARTTIME=$(date +%s)
    ResultMsg="<b>详细信息</b>"
    if [[ $MODE -eq 3 ]]; then
        ResultMsg="${ResultMsg}%0A备注：单次 API 更换 IP 将不会推送修复成功提醒"
    fi
    if [[ $NETFLIX -eq 1 ]]; then
        ResultMsg="${ResultMsg}%0ANetflix：$NetflixResult"
    fi
    if [[ $GOOGLE -eq 1 ]]; then
        ResultMsg="${ResultMsg}%0AGoogle：$GoogleResult"
    fi
    if [[ $DISNEY -eq 1 ]]; then
        ResultMsg="${ResultMsg}%0ADisney+：$DisneyResult"
    fi
    ResultMsg=$(echo $ResultMsg | sed -e 's/+/%2B/g')
    MAINIP=$(curl -4 -fsL http://ip.sb)
    TGStartMessage="<b>印度佬手动换IP助手 v${VERSION}</b>%0A%0A服务器：$NAME%0A%0A<b>$TIME</b>%0A流媒体解锁挂掉了，正在修复%0A%0A${ResultMsg}%0A当前ip:${MAINIP}"
    MessageID=$(curl -fsSL -X POST "https://api.telegram.org/bot$TG_BOT_TOKEN/sendMessage" -d chat_id=$TG_CHATID -d text="$TGStartMessage" -d parse_mode="HTML" | python -m json.tool | grep message_id | awk '{print $2}' | cut -d ',' -f1)
}

function SendEndMsg {
    TIME1=$(date +%Y-%m-%d)
    TIME2=$(date +%H:%M:%S)
    TIME=$TIME1+$TIME2+"[UTC %2B8]"
    ENDTIME=$(date +%s)
    TIMEUSED=$(expr $ENDTIME - $STARTTIME)
    MAINIP=$(curl -4 -fsL http://ip.sb)
    ResultMsg="<b>详细信息</b>%0A耗时：${TIMEUSED} 秒%0A尝试次数：${COUNT}%0A当前ip:${MAINIP}"
    if [[ $NETFLIX -eq 1 ]]; then
        ResultMsg="${ResultMsg}%0ANetflix：$NetflixResult"
    fi
    if [[ $GOOGLE -eq 1 ]]; then
        ResultMsg="${ResultMsg}%0AGoogle：$GoogleResult"
    fi
    if [[ $DISNEY -eq 1 ]]; then
        ResultMsg="${ResultMsg}%0ADisney：$DisneyResult"
    fi
    ResultMsg=$(echo $ResultMsg | sed -e 's/+/%2B/g')
    TGEndMessage="${TGStartMessage}%0A%0A<b>$TIME</b>%0A流媒体解锁修复完成%0A%0A${ResultMsg}"
    curl -fsSL -X POST "https://api.telegram.org/bot$TG_BOT_TOKEN/editMessageText" -d chat_id=$TG_CHATID -d message_id=$MessageID -d text="$TGEndMessage" -d parse_mode="HTML" >/dev/null 2>&1
}

function Terminate {
    rm -rf $SESSION
    exit 0
}

if [ "$1" == "1" ]; then
    OUT_ALERT "[手动模式] 欢迎使用印度佬手动换IP助手 v${VERSION}"
    NetflixResult="Mannual"
    GoogleResult="Mannual"
    DisneyResult="Mannual"
    COUNT=1
    SendStartMsg
    ChangeIP
else
    Initialize
fi