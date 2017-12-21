#!/bin/sh

set -e

# get date
# $1: date
get_date () {
	if [ -z "$1" ]; then
		date +%Y-%m-%d
	elif echo "$1" | grep -q "^[0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\}$"; then
		echo "$1"
	else
		echo "error: -t expects format to be YYYY-mm-dd, got $1" 1>&2
		exit 1
	fi
}

# find log file
# $1: log dir
# $2: channel
# $3: optional date
get_log_file () {
	t=$(get_date "$3")

	for f in $(find "$1" | grep "$2.*$t"); do
		r="$f"
	done

	if [ "$r" = "" ]; then
		echo "error: can't find log file on $t for $2 in $1" 1>&2
		exit 1
	fi

	echo "$r"
}

# first message of the day
# $1: log file
first_seen () {
	o=$(for n in $(awk -F '[<>]' '{print $2}' "$1" | sed 's/^.//' | sed '/^\s*$/d' | sort | uniq); do
		t=$(grep "<.$n>" "$1" | head -n 1 | awk '{ print $1 }')
		echo "$t: $n"
	done)
	echo "$o" | sort -n
}

# count lines
# $1: log file
count_lines () {
	awk -F '[<>]' '{ print $2 }' "$1" |\
		sed 's/^.//' |\
		sed '/^\s*$/d' |\
		sort |\
		uniq -c |\
		sort -n -r
}

# usage
usage () {
	echo "usage: $0 -c <channel> -d <log directory> [-f] [-l] [-t date]" 1>&2
}

# short help
short_help () {
	usage
	exit 1
}

# help
help () {
	usage
	echo "  -c <channel>    channel" 1>&2
	echo "  -d <directory>  log directory" 1>&2
	echo "  -f              first seen" 1>&2
	echo "  -l              number of lines for each nick in the channel" 1>&2
	echo "  -t <date>       date" 1>&2
	exit 1
}


# main
main () {
	while getopts "c:d:fhlt:" o; do
		case "$o" in
		c)
			c="$OPTARG"
			;;
		d)
			d="$OPTARG"
			;;
		f)
			f="1"
			;;
		h)
			h="1"
			;;
		l)
			l="1"
			;;
		t)
			t="$OPTARG"
			;;
		*)
			short_help
			;;
		esac
	done

	if [ "$h" ]; then
		help
	elif [ ! "$c" ]; then
		echo "error: -c <channel> is required" 1>&2
		exit 1
	elif [ ! "$d" ]; then
		echo "error: -d <log directory> is required" 1>&2
		exit 1
	fi

	if [ "$f" ]; then
		first_seen "$(get_log_file "$d" "$c" "$t")"
	elif [ "$l" ]; then
		count_lines "$(get_log_file "$d" "$c" "$t")"
	else
		echo "error: no action has been specified, see -h" 1>&2
		exit 1
	fi
}

main "$@"
