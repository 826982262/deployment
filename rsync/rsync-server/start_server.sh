#!/bin/sh
get_rsync_list(){
sshpass -p aicmp@123_ ssh -p $REMOTE_HOST_PORT -o StrictHostKeyChecking=no root@$REMOTE_HOST_IP "cat /backup_client/rsync_list.txt | grep ${RSYNC_IP}\|${RSYNC_PORT}"
}

register(){
  if [ "$MAX_RESERVER_COUNT" == "" ];then MAX_RESERVER_COUNT=15;fi
  echo MAX_RESERVER_COUNT is $MAX_RESERVER_COUNT
  registerd_host=`get_rsync_list`
  echo $registerd_host
  if [ `get_rsync_list | grep "${RSYNC_IP}|${RSYNC_PORT}" | wc -l ` -eq 1 ]
  then
    echo "$RSYNC_IP:$RSYNC_PORT is registerd"
    current_reserver_count=`echo $registerd_host | grep "${RSYNC_IP}\|${RSYNC_PORT}" | awk -F '|' '{print $3}'`
    host_info=`echo $registerd_host | grep "${RSYNC_IP}\|${RSYNC_PORT}"`
    echo host_info is $host_info
    if [ "$current_reserver_count" != "$MAX_RESERVER_COUNT" ]
    then
      echo current_reserver_count is $current_reserver_count
      sshpass -p aicmp@123_ ssh -p $REMOTE_HOST_PORT -o StrictHostKeyChecking=no root@$REMOTE_HOST_IP "sed -i s/\"$host_info\"/\"${RSYNC_IP}|${RSYNC_PORT}|$MAX_RESERVER_COUNT\"/g /backup_client/rsync_list.txt"
      echo "change ${RSYNC_IP}|${RSYNC_PORT}|$current_reserver_count to ${RSYNC_IP}|${RSYNC_PORT}|$MAX_RESERVER_COUNT"
    fi
  else
    echo "Registering $RSYNC_IP:$RSYNC_PORT to $REMOTE_HOST_IP:$REMOTE_HOST_PORT"
    sshpass -p aicmp@123_ ssh -p $REMOTE_HOST_PORT -o StrictHostKeyChecking=no root@$REMOTE_HOST_IP "echo ${RSYNC_IP}\|${RSYNC_PORT}\|${MAX_RESERVER_COUNT} >> /backup_client/rsync_list.txt "
    if [ `get_rsync_list | grep "${RSYNC_IP}|${RSYNC_PORT}" | wc -l` -eq 1 ]
    then
      echo "$RSYNC_IP:$RSYNC_PORT  register success ."
    else
      echo "$RSYNC_IP:$RSYNC_PORT  register failed ."
      exit 1
    fi
  fi
}

register