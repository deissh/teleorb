#!/bin/bash
#title          :send_msg.sh
#author         :deissh
#version        :0.1
#===============================
readonly API_URL=${TELEGRAM_API_URL:-"https://api.telegram.org/bot"}
readonly ORB_TEST_ENV="bats-core"

# default values
DEBUG=false
TOKEN=""
CHATS=()
CURL_OPTIONS="-s"
DISABLE_NOTIFICATION=false


function log {
	echo "DEBUG: $1"
}

function exec_request {
    # ARG1 - api key
    # ARG2 - chat_id
    # ARG3 - text
    # ARG4 - disable_notification

    curl -X POST \
        -H 'Content-Type: application/json' \
        -d "{\"chat_id\": \"$2\", \"text\": \"$3\", \"disable_notification\": false}" \
        https://api.telegram.org/bot$1/sendMessage
}


[ -z "$TOKEN" ] && TOKEN=$TELEGRAM_TOKEN
[ ${#CHATS[@]} -eq 0 ] && CHATS=($TELEGRAM_CHAT)

if [ -z "$TOKEN" ]; then
    echo "No bot token was given."
    exit 1
fi

if [ ${#CHATS[@]} -eq 0 ]; then
    echo "No chats given."
    exit 1
fi

[ -z "$TOKEN" ] && TOKEN=$TELEGRAM_TOKEN
[ ${#CHATS[@]} -eq 0 ] && CHATS=($TELEGRAM_CHAT)
[ -n "$TELEGRAM_DISABLE_NOTIFICATION" ] && DISABLE_NOTIFICATION="$TELEGRAM_DISABLE_NOTIFICATION"

log "TOKEN=$TOKEN"
log "CHATS=${CHATS[*]}"
log "DISABLE_WEB_PAGE_PREVIEW=$DISABLE_WEB_PAGE_PREVIEW"
log "DISABLE_NOTIFICATION=$DISABLE_NOTIFICATION"


shift $((OPTIND - 1))
TEXT="$1"
[ "$TEXT" = "" ] && TEXT=$(</dev/stdin)

log "Text: $TEXT"

CURL_OPTIONS="$CURL_OPTIONS --form text=<-"
[ "$DISABLE_NOTIFICATION" = true ] && CURL_OPTIONS="$CURL_OPTIONS --form-string disable_notification=true"

for CHAT_ID in "${CHATS[@]}"; do
	MY_CURL_OPTIONS="$CURL_OPTIONS --form-string chat_id=$CHAT_ID"

    # Entrypoint
    # Will not run if sourced for bats-core tests.
    if [ "${0#*$ORB_TEST_ENV}" == "$0" ]; then
        response=`curl $MY_CURL_OPTIONS $API_URL$TOKEN/sendMessage <<< $TEXT`
        status=$?
    else
        log "Executing: curl $MY_CURL_OPTIONS"
        status=0
        response='{"ok": true}'
    fi

    log "Response was: $response"
	if [ $status -ne 0 ]; then
		echo "curl reported an error. Exit code was: $status."
		echo "Response was: $response"
		echo "Quitting."
		exit $status
	fi
done
