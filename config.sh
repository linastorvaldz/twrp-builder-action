#!/bin/bash
# Copyright (c) https://github.com/UWU-TEAM 2025-present
# Copyright (c) https://github.com/linastorvaldz 2025-present

#########################
# Variables and Functions
#########################
DISTRO=$(source /etc/os-release && echo "${PRETTY_NAME}")

timeStart() {
    BUILD_START=$(date +"%s")
    DATE=$(date)
}

timeEnd() {
    BUILD_END=$(date +"%s")
    DIFF=$((BUILD_END - BUILD_START))
}

telegram_curl() {
    local ACTION=${1}
    shift
    local HTTP_REQUEST=${1}
    shift
    if [[ ${HTTP_REQUEST} != "POST_FILE" ]]; then
        curl -X "${HTTP_REQUEST}" "https://api.telegram.org/bot$TG_TOKEN/$ACTION" "$@" | jq .
    else
        curl "https://api.telegram.org/bot$TG_TOKEN/$ACTION" "$@" | jq .
    fi
}

telegram_main() {
    local ACTION=${1}
    local HTTP_REQUEST=${2}
    shift 2
    local CURL_ARGUMENTS=()

    while [[ $# -gt 0 ]]; do
        case "${1}" in
        --animation | --audio | --document | --video)
            CURL_ARGUMENTS+=(-F "$(echo "${1}" | sed 's/--//')=@${2}")
            shift
            ;;
        --*)
            if [[ $HTTP_REQUEST != "POST_FILE" ]]; then
                CURL_ARGUMENTS+=(-d "$(echo "${1}" | sed 's/--//')=${2}")
            else
                CURL_ARGUMENTS+=(-F "$(echo "${1}" | sed 's/--//')=${2}")
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
    if [[ -z $CI_MESSAGE_ID ]]; then
        CI_MESSAGE_ID=$(
            tg_send_message --chat_id "$TG_CHAT_ID" --parse_mode "html" --text "<b>=== 🦊 OrangeFox Recovery Builder ===</b>
<b>📜 Fox Manifest :</b> ${FOX_BRANCH}
<b>📱 Device :</b> ${DEVICE} (${CODENAME})
<b>📟 Jobs :</b> $(nproc --all)
<b>🗃 Storage :</b> $(df -h . | tail -n 1 | awk '{print $2}')
<b>📈 Used :</b> $(df -h . | tail -n 1 | awk '{print $3}')
<b>📉 Remaining :</b> $(df -h . | tail -n 1 | awk '{print $4}')
<b>🖥️ Running on :</b> $DISTRO
<b>📅 Started at :</b> $DATE

<b>⚙️ Status:</b> ${1}" | jq -r .result.message_id
        )
    else
        tg_edit_message_text --chat_id "$TG_CHAT_ID" --message_id "$CI_MESSAGE_ID" --parse_mode "html" --text "<b>=== 🦊 OrangeFox Recovery Builder ===</b>
<b>📜 Fox Manifest :</b> ${FOX_BRANCH}
<b>📱 Device :</b> ${DEVICE} (${CODENAME})
<b>📟 Jobs :</b> $(nproc --all)
<b>🗃 Storage :</b> $(df -h . | tail -n 1 | awk '{print $2}')
<b>📈 Used :</b> $(df -h . | tail -n 1 | awk '{print $3}')
<b>📉 Remaining :</b> $(df -h . | tail -n 1 | awk '{print $4}')
<b>🖥️ Running on :</b> $DISTRO
<b>📅 Started at :</b> $DATE

<b>⚙️ Status :</b> ${1}"
    fi
}

post_message() {
    tg_send_message --chat_id "$TG_CHAT_ID" --parse_mode "html" --reply_to_message_id "$CI_MESSAGE_ID" --text "<b>=== ✅ Build Completed ===</b>

<b>📱 Device :</b> ${DEVICE} (${CODENAME})
<b>📜 Fox Manifest :</b> ${FOX_BRANCH}
<b>📂 ZIP Size :</b> ${ORF_ZIP_SIZE}
<b>📂 Image Size :</b> ${ORF_IMG_SIZE}
<b>⏰ Build Timer :</b> ${ORF_TIME}
<b>📥 Download :</b> <a href=\"${ORF_GHREPO}/releases/tag/${ORF_TAG}\">here</a>

<b>📕 ZIP MD5 :</b> <code>${ORF_ZIP_MD5}</code>
<b>📘 ZIP SHA1 :</b> <code>${ORF_ZIP_SHA1}</code>
<b>📕 Image MD5 :</b> <code>${ORF_IMG_MD5}</code>
<b>📘 Image SHA1 :</b> <code>${ORF_IMG_SHA1}</code>"
}

buildStatus() {
    if [[ $retVal -ne 0 ]]; then
        build_message " ❌ Build Aborted after $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds."
        sleep 1
        tg_send_document --chat_id "$TG_CHAT_ID" --document "$BUILDLOG" --reply_to_message_id "$CI_MESSAGE_ID"
        exit $retVal
    fi
    build_message "Build success ✅"
}

