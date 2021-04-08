#!/bin/sh

echo -n "irccloud email: "
read email </dev/tty
if [ -z "$email" ]; then
	echo "invalid email"
	exit 1
fi

echo -n "irccloud password: "
read password </dev/tty
if [ -z "$password" ]; then
	echo "invalid password"
	exit 1
fi

curl -s https://raw.githubusercontent.com/osm/scripts/master/irccloud.sh >/storage/irccloud.sh
chmod 755 /storage/irccloud.sh

crontab -l | grep -v irccloud.sh >/tmp/crontab
echo "0 * * * * /storage/irccloud.sh $email $password" >>/tmp/crontab
cat /tmp/crontab | crontab -
rm /tmp/crontab
