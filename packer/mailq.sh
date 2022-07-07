#!/bin/bash

PLUGIN_NAME="postfix-queue"
HOSTNAME="${COLLECTD_HOSTNAME:-localhost}"
INTERVAL="${COLLECTD_INTERVAL:-60}"

POSTQUEUE_CMD="postqueue -p"

function get_mailq(){
  ret_postqueue=$($POSTQUEUE_CMD | grep -v -P "^\-Queue ID" | perl -00 -wnl -e '/^[A-Z0-9]{11}(\s|\*|\!)/ or print;' | sed -e '/^$/d')
  if [ -z "$ret_postqueue" ]; then
    echo -1
  elif [ "x$ret_postqueue" = "xMail queue is empty" ]; then
    echo 0
  else
    num_queue=$(echo $ret_postqueue | perl -wnl -e '/^\-\- \d+ Kbytes in (\d+) Request/ and print $1;')
    echo $num_queue
  fi
}

while sleep "$INTERVAL"
do
  NOW=$(date +%s)
  VALUE=$(get_mailq)
  echo "PUTVAL \"${HOSTNAME}/${PLUGIN_NAME}/email_count\" interval=${INTERVAL} N:${VALUE}"
done
