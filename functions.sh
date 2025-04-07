#!/usr/bin/env bash
# Copyright (c) https://github.com/UWU-TEAM 2025-present
# Copyright (c) https://github.com/linastorvaldz 2025-present

############
# Functions
############

timeStart() {
    export BUILD_START=$(date +"%s")
    export DATE=$(date)
    export BUILD_DATE=$(date -d "$DATE" +"%Y%m%d-%H%M")
}

timeEnd() {
    export BUILD_END=$(date +"%s")
    export DIFF=$((BUILD_END - BUILD_START))
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
            tg_send_message --chat_id "$TG_CHAT_ID" --parse_mode "markdown" --text "*=== TWRP Builder ===*
*TWRP Branch :* twrp-${TWRP_BRANCH}
*Device :* ${DEVICE} (${CODENAME})
*Date :* $DATE

*⚙️ Status :* ${1}" | jq -r .result.message_id
        )
    else
        tg_edit_message_text --chat_id "$TG_CHAT_ID" --message_id "$CI_MESSAGE_ID" --parse_mode "markdown" --text "*=== TWRP Builder ===*
*TWRP Branch :* twrp-${TWRP_BRANCH}
*Device :* ${DEVICE} (${CODENAME})
*Date :* $DATE

*⚙️ Status :* ${1}"
    fi
}

build_success_msg() {
    tg_send_message --chat_id "$TG_CHAT_ID" --parse_mode "markdown" --reply_to_message_id "$CI_MESSAGE_ID" --text "*=== ✅ Build Succeeded ===*
📦 Download: [here](${LINK})"
}

buildStatus() {
    if [[ $retVal -ne 0 ]]; then
        build_message "❌ Build Failed after $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds."
        sleep 1
        tg_send_document --chat_id "$TG_CHAT_ID" --document "$BUILDLOG" --reply_to_message_id "$CI_MESSAGE_ID"
        exit $retVal
    fi
    build_message "Build success ✅"
}

create_release_notes() {
    echo "## TWRP Build - Unofficial
TWRP Branch: ${TWRP_BRANCH}
Device: ${DEVICE} (${CODENAME})

- SHA1: \`${SHA1}\`
- MD5: \`${MD5}\`" >${GITHUB_ACTION_PATH}/release-notes.md
}
