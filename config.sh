#!/bin/bash
# Copyright (c) https://github.com/UWU-TEAM 2025-present
# Copyright (c) https://github.com/linastorvaldz 2025-present

export TERM=xterm-256color
TZ=Asia/Makassar
LOGO="https://i.imgur.com/KYD94sP.png"

# Don't change this line
#===========================================
DISTRO=$(source /etc/os-release && echo "${PRETTY_NAME}")

red=$(tput setaf 1)             #  red
grn=$(tput setaf 2)             #  green
blu=$(tput setaf 4)             #  blue
cya=$(tput setaf 6)             #  cyan
txtrst=$(tput sgr0)             #  Reset

timeStart() {
    #DATELOG=$(TZ=$TZ date +"%H%M-%d%m%Y")
    BUILD_START=$(date +"%s")
    DATE=$(TZ=$TZ date)
}

timeEnd() {
	BUILD_END=$(date +"%s")
	DIFF=$(($BUILD_END - $BUILD_START))
}

telegram_curl() {
    local ACTION=${1}
    shift
    local HTTP_REQUEST=${1}
    shift
    if [[ "${HTTP_REQUEST}" != "POST_FILE" ]]; then
        curl -X "${HTTP_REQUEST}" "https://api.telegram.org/bot$TG_TOKEN/$ACTION" "$@" | jq .
    else
        curl "https://api.telegram.org/bot$TG_TOKEN/$ACTION" "$@" | jq .
    fi
}

telegram_main() {
    local ACTION=${1}
    local HTTP_REQUEST=${2}
    local CURL_ARGUMENTS=()
    while [[ "${#}" -gt 0 ]]; do
        case "${1}" in
            --animation | --audio | --document | --video )
                local CURL_ARGUMENTS+=(-F $(echo "${1}" | sed 's/--//')=@"${2}")
                shift
                ;;
            --* )
                if [[ "$HTTP_REQUEST" != "POST_FILE" ]]; then
                    local CURL_ARGUMENTS+=(-d $(echo "${1}" | sed 's/--//')="${2}")
                else
                    local CURL_ARGUMENTS+=(-F $(echo "${1}" | sed 's/--//')="${2}")
                fi
                shift
                ;;
        esac
        shift
    done
    telegram_curl "${ACTION}" "${HTTP_REQUEST}" "${CURL_ARGUMENTS[@]}"
}

tg_send_message() {
    telegram_main sendMessage POST "$@"
}

tg_edit_message_text() {
    telegram_main editMessageText POST "$@"
}

tg_edit_message_caption() {
    telegram_main editMessageCaption POST "$@"
}

tg_send_document() {
    telegram_main sendDocument POST_FILE "$@"
}

tg_send_photo() {
    telegram_main sendPhoto POST "$@"
}

build_message() {
	if [ "$CI_MESSAGE_ID" = "" ]; then
CI_MESSAGE_ID=$(tg_send_photo --chat_id "$TG_CHAT_ID" --photo "$LOGO" --parse_mode "html" --caption "<b>=== 🦊 OrangeFox Recovery Builder ===</b>
<b>📜 Fox Manifest :</b> ${FOX_BRANCH}
<b>📱 Device :</b> ${DEVICE} | ${CODENAME}
<b>📟 Jobs :</b> $(nproc --all)
<b>🗃 Storage :</b> $(df -h . | tail -n 1 | awk '{print $2}')
<b>📈 Used :</b> $(df -h . | tail -n 1 | awk '{print $3}')
<b>📉 Remaining :</b> $(df -h . | tail -n 1 | awk '{print $4}')
<b>🖥️ Running on :</b> $DISTRO
<b>📅 Started at :</b> $DATE

<b>⚙️ Status:</b> ${1}
${2}" | jq .result.message_id)
	else
tg_edit_message_caption --chat_id "$TG_CHAT_ID" --message_id "$CI_MESSAGE_ID" --parse_mode "html" --caption "<b>=== 🦊 OrangeFox Recovery Builder ===</b>
<b>📜 Fox Manifest :</b> ${FOX_BRANCH}
<b>📱 Device :</b> ${DEVICE} | ${CODENAME}
<b>📟 Jobs :</b> $(nproc --all)
<b>🗃 Storage :</b> $(df -h . | tail -n 1 | awk '{print $2}')
<b>📈 Used :</b> $(df -h . | tail -n 1 | awk '{print $3}')
<b>📉 Remaining :</b> $(df -h . | tail -n 1 | awk '{print $4}')
<b>🖥️ Running on :</b> $DISTRO
<b>📅 Started at :</b> $DATE

<b>⚙️ Status :</b> <code>${1}</code>
<code>${2}</code>"
	fi
}

post_message() {
    tg_send_photo --chat_id "$TG_CHAT_ID" --photo "$LOGO" --parse_mode "html" --reply_to_message_id "$CI_MESSAGE_ID" --caption "<b>=== 🦊 OrangeFox Recovery Builder ===</b>
==========================
<b>✅ Build Completed Successfully</b>

<b>📱 Device :</b> ${DEVICE} | ${CODENAME}
<b>📜 Fox Manifest :</b> ${FOX_BRANCH}
<b>👩‍💻 Top Commit :</b> ${DT_COMMIT}
<b>📂 ZIP Size :</b> ${ORF_ZIP_SIZE}
<b>📂 Image Size :</b> ${ORF_IMG_SIZE}
<b>⏰ Build Timer :</b> ${ORF_TIME}
<b>📥 Download :</b> <a href=\"${ORF_GHREPO}/releases/tag/${ORF_TAG}\">here</a>
<b>📅 Date :</b> $(TZ=$TZ date +%d\ %B\ %Y)
<b>🕔 Time :</b> $(TZ=$TZ date +%T)

<b>📕 ZIP MD5 :-</b> <code>${ORF_ZIP_MD5}</code>
<b>📘 ZIP SHA1 :-</b> <code>${ORF_ZIP_SHA1}</code>
<b>📕 Image MD5 :-</b> <code>${ORF_IMG_MD5}</code>
<b>📘 Image SHA1 :-</b> <code>${ORF_IMG_SHA1}</code>
==========================
"
}

progress() {
    echo -e ${blu} "BOTLOG: Build tracker process is running..."
    sleep 5;
    while [ 1 ]; do
        if [[ ${retVal} -ne 0 ]]; then
            exit ${retVal}
        fi
        # Get latest percentage
        PERCENTAGE=$(cat $BUILDLOG | tail -n 1 | awk '{ print $2 }')
        NUMBER=$(echo ${PERCENTAGE} | sed 's/[^0-9]*//g')
        # Report percentage to the $TG_CHAT_ID
        if [[ "${NUMBER}" != "" ]]; then
            if [[ "${NUMBER}" -le  "99" ]]; then
                if [[ "${NUMBER}" != "${NUMBER_OLD}" ]] && [[ "$NUMBER" != "" ]] && ! cat $BUILDLOG | tail  -n 1 | grep "glob" > /dev/null && ! cat $BUILDLOG | tail  -n 1 | grep "including" > /dev/null && ! cat $BUILDLOG | tail  -n 1 | grep "soong" > /dev/null && ! cat $BUILDLOG | tail  -n 1 | grep "finishing" > /dev/null; then
                echo -e ${blu} "BOTLOG: Percentage changed to ${NUMBER}%"
                    if [[ "$NUMBER" == "1" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▱▱▱▱▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "2" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▱▱▱▱▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "3" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▱▱▱▱▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "4" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▱▱▱▱▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "5" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▱▱▱▱▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "6" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▱▱▱▱▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "7" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▱▱▱▱▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "8" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▱▱▱▱▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "9" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▱▱▱▱▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "10" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▱▱▱▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "11" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▱▱▱▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "12" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▱▱▱▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "13" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▱▱▱▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "14" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▱▱▱▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "15" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▱▱▱▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "16" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▱▱▱▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "17" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▱▱▱▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "18" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▱▱▱▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "19" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▱▱▱▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "20" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▱▱▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "21" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▱▱▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "22" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▱▱▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "23" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▱▱▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "24" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▱▱▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "25" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▱▱▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "26" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▱▱▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "27" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▱▱▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "28" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▱▱▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "29" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▱▱▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "30" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▱▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "31" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▱▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "32" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▱▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "33" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▱▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "34" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▱▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "35" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▱▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "36" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▱▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "37" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▱▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "38" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▱▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "39" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▱▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "40" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "41" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "42" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "43" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "44" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "45" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "46" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "47" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "48" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "49" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▱▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "50" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "51" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "52" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "53" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "54" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "55" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "56" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "57" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "58" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "59" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▱▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "60" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▰▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "61" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▰▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "62" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▰▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "63" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▰▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "64" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▰▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "65" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▰▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "66" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▰▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "67" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▰▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "68" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▰▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "69" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▰▱▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "70" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▰▰▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "71" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▰▰▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "72" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▰▰▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "73" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▰▰▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "74" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▰▰▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "75" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▰▰▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "76" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▰▰▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "77" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▰▰▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "78" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▰▰▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "79" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▰▰▱▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "80" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▰▰▰▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "81" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▰▰▰▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "82" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▰▰▰▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "83" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▰▰▰▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "84" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▰▰▰▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "85" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▰▰▰▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "86" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▰▰▰▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "87" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▰▰▰▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "88" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▰▰▰▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "89" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▰▰▰▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "90" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▰▰▰▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "91" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▰▰▰▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "92" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▰▰▰▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "93" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▰▰▰▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "94" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▰▰▰▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "95" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▰▰▰▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "96" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▰▰▰▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "97" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▰▰▰▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "98" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▰▰▰▱」 ${NUMBER}% 💨" > /dev/null
                    elif [[ "$NUMBER" == "99" ]]; then
                       build_message "Building... 🛠️" "🚀 「▰▰▰▰▰▰▰▰▰▰」 ${NUMBER}% 💨" > /dev/null
                    fi
                fi
            NUMBER_OLD=${NUMBER}
            fi
            if [[ "$NUMBER" -eq "99" ]] && [[ "$NUMBER" != "" ]] && ! cat $BUILDLOG | tail  -n 1 | grep "glob" > /dev/null && ! cat $BUILDLOG | tail  -n 1 | grep "including" > /dev/null && ! cat $BUILDLOG | tail  -n 1 | grep "soong" > /dev/null && ! cat $BUILDLOG | tail -n 1 | grep "finishing" > /dev/null; then
                echo -e ${grn} "BOTLOG: Build tracker process ended"
                break
            fi
        fi
        sleep 5
    done
    return 0
}

statusBuild() {
    if [[ $retVal -ne 0 ]]; then
        build_message "Build Error ❌ with Code Exit ${retVal}, See log.

Total time elapsed: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
        tg_send_document --chat_id "$TG_CHAT_ID" --document "$BUILDLOG" --reply_to_message_id "$CI_MESSAGE_ID"
        exit $retVal
    fi
    build_message "Build success ✅" "🚀 「▰▰▰▰▰▰▰▰▰▰」 100% 💨"
}
