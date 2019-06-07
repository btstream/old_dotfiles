#!/bin/bash
# author: Whizzzkid (me@nishantarora.in)

# Base URL.
bing="http://www.bing.com"

# API end point.
api="/HPImageArchive.aspx?"

# Response Format (json|xml).
format="&format=js"

# For day (0=current; 1=yesterday... so on).
day="&idx=0"

# Market for image.
market="&mkt=en-US"

# API Constant (fetch how many).
const="&n=1"

# Image extension.
extn=".jpg"

# Size.
size=$(xdpyinfo | grep dimensions | cut -d\  -f7)

# Collection Path.
path="$HOME/Pictures/Bing/"
if [[ ! -e $path ]]; then
    mkdir -pv $path
fi

wallpaperPath="$HOME/Pictures/Wallpapers"
if [[ ! -e $wallpaperPath ]]; then
    mkdir $wallpaperPath
fi
wallpaperName="i3wallpaper"

# Make it run just once (useful to run as a cron)
run_once=false
while getopts "1" opt; do
  case $opt in
    1 )
      run_once=true
      ;;
    \? )
      echo "Invalid option! usage: \"$0 -1\", to run once and exit"
      exit 1
      ;;
  esac
done

/usr/bin/feh --bg-scale $wallpaperPath/$wallpaperName 

# starting update after 5 minutes
# in case there are no internet connections
sleep 300

# Required Image Uri.
reqImg=$bing$api$format$day$market$const

while [ 1 ]
do

  # Logging.
  echo "Pinging Bing API..."

  # Fetching API response.
  apiResp=$(curl -s $reqImg)
  if [ $? -gt 0 ]; then
    echo "Ping failed!"
    exit 1
  fi
  
  # Default image URL in case the required is not available.
  defImgURL=$bing$(echo $apiResp | grep -oP "url\":\"[^\"]*" | cut -d "\"" -f 3)

  # Req image url (raw).
  reqImgURL=$bing$(echo $apiResp | grep -oP "urlbase\":\"[^\"]*" | cut -d "\"" -f 3)"_"$size$extn
  
  # Image copyright.
  copyright=$(echo $apiResp | grep -oP "copyright\":\"[^\"]*" | cut -d "\"" -f 3)
  
  # start date
  startDate=$(echo $apiResp | grep -oP "\"startdate\":\"[^\"]*" | cut -d "\"" -f 4)
  
  # only do next actions to 
  if [[ x$startDate != x ]]; then
    # Checking if reqImgURL exists.
    if [[ ! $(wget --quiet --spider --max-redirect 0 $reqImgURL) ]]; then
        reqImgURL=$defImgURL
    fi
    # Logging.
    echo "Bing Image of the day: $reqImgURL"
    
    # Getting Image Name.
    imgName=bing-wallpaper-$startDate$extn

    # Only for image
    if [[ ! -e $path$imgName ]]; then
      # Saving Image to collection.
      curl -L -s -o $path$imgName $reqImgURL
      # Logging.

      if [[ -e $path$imgName ]]; then 
          echo "Saving image to $path$imgName"
          # Writing copyright.
          echo "$copyright" > $path${imgName/%.jpg/.txt}
          ln -sf $path$imgName $wallpaperPath/$wallpaperName
          /usr/bin/feh --bg-scale $wallpaperPath/$wallpaperName 
          betterlockscreen -u $wallpaperPath/$wallpaperName &
      fi
    fi
  fi
  
  
  # If -1 option was passed just run once
  if [ $run_once == true ];then
    break
  fi

  # Re-checks for updates every 6 hours.
  sleep 21600
done
