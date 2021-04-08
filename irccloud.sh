#!/bin/sh

if [ -z "$1" ] || [ -z "$2" ]; then
	echo "usage: $0 <email> <password>"
	exit 1
fi

ua="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.114 Safari/537.36"

form_token=$(curl \
	-s \
	-X "POST" \
	-H "Content-Length: 0" \
	-H "User-Agent: $ua" \
	https://www.irccloud.com/chat/auth-formtoken |
	jq -r .token)

session=$(curl \
	-s \
	-d "email=$1" \
	-d "password=$2" \
	-d "token=$form_token" \
	-H "Content-Type: application/x-www-form-urlencoded" \
	-H "User-Agent: $ua" \
	-H "X-Auth-FormToken: $form_token" \
	https://www.irccloud.com/chat/login |
	jq -r .session)

curl \
	-s \
	-b "session=$session" \
	-H "User-Agent: $ua" \
	https://www.irccloud.com/chat/stream >/dev/null 2>&1
