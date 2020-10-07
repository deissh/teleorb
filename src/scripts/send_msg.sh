#title          :send_msg.sh
#author         :deissh
#version        :0.1
#===============================
readonly API_URL=${TELEGRAM_API_URL:-"https://api.telegram.org/bot"}
readonly ORB_TEST_ENV="bats-core"

# default values
TOKEN=""
CHATS=()
CURL_OPTIONS="-s"
DISABLE_NOTIFICATION=false


[ -z "$TOKEN" ] && TOKEN=$TELEGRAM_TOKEN
[ ${#CHATS[@]} -eq 0 ] && CHATS=( "$TELEGRAM_CHAT" )
[ -n "$TELEGRAM_DISABLE_NOTIFICATION" ] && DISABLE_NOTIFICATION="$TELEGRAM_DISABLE_NOTIFICATION"

if [ -z "$TOKEN" ]; then
    echo "No bot token was given."
    exit 1
fi

if [ ${#CHATS[@]} -eq 0 ]; then
    echo "No chats given."
    exit 1
fi


shift $((OPTIND - 1))
TEXT="$1"
[ -z "$TEXT" ] && [ -n "$TELEGRAM_TEXT" ] && TEXT="$TELEGRAM_TEXT"

CURL_OPTIONS="$CURL_OPTIONS --form text=<-"
[ "$DISABLE_NOTIFICATION" = true ] && CURL_OPTIONS="$CURL_OPTIONS --form-string disable_notification=true"

for CHAT_ID in "${CHATS[@]}"; do
    MY_CURL_OPTIONS="$CURL_OPTIONS --form-string chat_id=$CHAT_ID"

    echo "Executing: curl $MY_CURL_OPTIONS"
    
    # Entrypoint
    # Will not run if sourced for bats-core tests.
    if [ "${0#*$ORB_TEST_ENV}" == "$0" ]; then
        # shellcheck disable=SC2086
        response=$(curl $MY_CURL_OPTIONS "$API_URL$TOKEN/sendMessage" <<< "$TEXT")
        status=$?
    else
        status=0
        response='{"ok": true}'
    fi

    echo "Response was: $response"
    if [ $status -ne 0 ]; then
        echo "curl reported an error. Exit code was: $status."
        echo "Response was: $response"
        echo "Quitting."
        exit $status
    fi

    if [[ "$response" != '{"ok":true'* ]]; then
        echo "Telegram reported an error:"
        echo "$response"
        echo "Quitting."
        exit 1
    fi
done
