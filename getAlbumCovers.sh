#!/bin/bash

# Check if the $LASTFMAPIKEY variable exists
test -z "$LASTFMAPIKEY" && echo "No API Key in environement" && exit

# Create cache folder
cache='/tmp/albumcoverscache'
mkdir -p $cache

# Get metadata
metadata=$(exiftool -json "$1")

artist=$(echo $metadata | jq -r '.[].AlbumArtist' | sed 's/ /%20/g')
album=$(echo $metadata | jq -r '.[].Album' | sed 's/ /%20/g')

# Generate id
id=$(echo "$artist $album" | md5sum | awk '{print $1}')

# If AlbumArtist doesn't exist use Artist
test "$artist" = "null" &&
    artist=$(echo $metadata | jq -r '.[].Artist' | sed 's/ /%20/g')

# Check if we have them
test "$artist" = "null" && echo "Missing informations, $1" && exit
test "$album" = "null" && echo "Missing informations, $1" && exit

# Check if there's already an album cover

test "$(echo $metadata | jq -r '.[].Picture')" != "null" && echo "There's already a cover" && exit

# Test if cover is already downloaded
if [ ! -e "$cache/$id.jpg" ]; then
    request="http://ws.audioscrobbler.com/2.0/?method=album.getinfo&api_key=$LASTFMAPIKEY&artist=$artist&album=$album&format=json"

    coverurl=$(curl --silent $request |
		   jq .album.image.\[4\] |
		   grep text |
		   awk '{ print $2}' |
		   sed 's/\"//g'
    )

    curl --silent "$coverurl" -o "$cache/$id.jpg"
fi

opustags -i --set-cover "$cache/$id.jpg" "$1"
