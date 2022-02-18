#!/bin/sh

if [ -z "$1" ] || [ -z "$2" ]; then
	echo "usage: $0 <nick> <output dir>"
	exit 1
fi
nick="$1"
output_dir="$2"

page="$(mktemp)"
page_info="$(mktemp)"
file_ids="$(mktemp)"

page_num="1"
while [ -n "$page_num" ]; do
	echo "fetching page $page_num"
	curl \
		-s \
		-d "search=$nick&page=$page_num" \
		"https://www.badplace.eu/Demos/SearchResults" >$page

	grep "data-matchid=" $page | cut -d'"' -f4 | while read id; do
		echo "fetching sub page for $page_num"
		curl \
			-s \
			-d "id=$id" \
			"https://www.badplace.eu/TournamentDialog/MatchPreviewDialog" >$page_info
		grep "\/Game\/Download\/" $page_info | cut -d'"' -f2 | cut -d'/' -f4 >>$file_ids
	done

	grep "\/Game\/Download\/" $page | cut -d'"' -f2 | cut -d'/' -f4 >>$file_ids

	page_num=$(grep 'aria-label="Next"' $page | cut -d'"' -f 6)
done

cat $file_ids | while read id; do
	if [ -f "$output_dir/$id.zip" ]; then
		echo "$output_dir/$id.zip exists, skipping"
	else
		echo "fetching demo $id"
		curl \
			-s \
			-L \
			https://www.badplace.eu/Game/Download/$id >"$output_dir/$id.zip"
	fi
done

rm -f $page $page_info $file_ids
