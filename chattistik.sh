#!/bin/sh

# get date
# $1: date
get_date () {
	if [ -z "$1" ]; then
		date +%Y-%m-%d
	elif echo "$1" | grep -q "^[0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\}$"; then
		echo "$1"
	else
		echo "error: -t expects format to be YYYY-mm-dd, got $1" 1>&2
		return 1
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
		return 1
	fi

	echo "$r"
}

# get available nicks from log file
# $1: log file
get_nicks () {
	for n in $(awk -F '[<>]' '{print $2}' "$1" | sed 's/^.//' | sed '/^\s*$/d' | sort | uniq); do
		echo "$n"
	done
}

# first message of the day
# $1: log file
first_seen () {
	o=$(for n in $(get_nicks "$1"); do
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

# count words for each nick
# $1: log file
count_words () {
	o=$(for n in $(get_nicks "$1"); do
		w=$(grep "<.$n>" "$1" | sed 's/[^>]*>//' | wc -w | awk '{ print $1 }')
		echo "$n: $w"
	done)

	echo "$o" | sort -n -r -k 2
}

# count word for each nick
# $1: log file
# $2: word
count_word () {
	o=$(for n in $(get_nicks "$1"); do
		c=$(grep "<.$n>" "$1" | grep -i -o "$2" | wc -l | awk '{ print $1 }')
		echo "$n: $c"
	done)

	echo "$o" | sort -n -r -k 2
}

# usage
usage () {
	echo "usage: $0 -c <channel> -d <log directory> [-f] [-l] [-t date]" 1>&2
	echo "          [-w] [-W <word>]" 1>&2
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
	echo "  -w              number of words for each nick in the channel" 1>&2
	echo "  -W <word>       number of times a specific word has been said by each nick" 1>&2
	exit 1
}


# main
main () {
	while getopts "c:d:fhlt:wW:" o; do
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
		w)
			w="1"
			;;
		W)
			W="$OPTARG"
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

	log_file=$(get_log_file "$d" "$c" "$t")
	if [ $? -eq 1 ]; then
		exit 1
	fi

	if [ "$f" ]; then
		first_seen "$log_file"
	elif [ "$l" ]; then
		count_lines "$log_file"
	elif [ "$w" ]; then
		count_words "$log_file"
	elif [ "$W" ]; then
		count_word "$log_file" "$W"
	else
		echo "error: no action has been specified, see -h" 1>&2
		exit 1
	fi
}

main "$@"
