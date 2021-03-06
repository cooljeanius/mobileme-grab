#!/bin/bash
#
# Upload complete files to batcave.
#
# This script will look in your data/ directory to find
# users that are finished. It will upload the data for
# these users to the repository using rsync.
#
# You can run this while you're still downloading,
# since it will only upload data that is done.
# After the upload of an account finishes, the files are
# moved to the data/uploaded/ directory.
#
# Usage:
#   ./upload-finished.sh $YOURNICK
#
# You can set a bwlimit for rsync, e.g.:
#   ./upload-finished.sh $YOURNICK 300
#

destname=$1
target=fos
dest=${target}.textfiles.com::mobileme/$1/
if [ -z "$destname" ]
then
  echo "Usage:  $0 [yournick] [bwlimit]"
  exit
fi
if [[ ! $destname =~ ^[-A-Za-z0-9_]+$ ]]
then
  echo "$dest does not look like a proper nickname."
  echo "Usage:  $0 [yournick] [bwlimit]"
  exit
fi

bwlimit=$2
if [ -n "$bwlimit" ]
then
  bwlimit="--bwlimit=${bwlimit}"
fi

if [ -z $DATA_DIR ]
then
  DATA_DIR=data
fi

cd $DATA_DIR/
for d in ?/*/*/*
do
  if [ -d "${d}/web.me.com" ] && \
     [ -d "${d}/homepage.mac.com" ] && \
     [ -d "${d}/public.me.com" ] && \
     [ -d "${d}/gallery.me.com" ] && \
     [ ! -f "${d}/"*"/.incomplete" ]
  then
    user_dir="${d}/"
    user=$( basename $user_dir )
    echo "Uploading $user"

    echo "${user_dir}" | \
    rsync -avz --partial \
          --compress-level=9 \
          --progress \
          ${bwlimit} \
          --exclude=".incomplete" \
          --exclude="files" \
          --exclude="unique-urls.txt" \
          --recursive \
          --files-from="-" \
          ./ ${dest}
    if [ $? -eq 0 ]
    then
      echo -n "Upload complete. Notifying tracker... "

      success_str="{\"uploader\":\"${destname}\",\"user\":\"${user}\",\"server\":\"${target}\"}"
      tracker_no=$(( RANDOM % 3 ))
      tracker_host="memac-${tracker_no}.heroku.com"
      resp=$( curl -s -f -d "$success_str" http://${tracker_host}/uploaded )
      
      mkdir -p "uploaded/"$( dirname $user_dir )
      mv $user_dir "uploaded/"$user_dir

      echo "done."
    else
      echo "An rsync error. Scary!"
      exit 1
    fi
  fi
done

exit 0

