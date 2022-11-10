#!/bin/sh

backup_path="/backup_client"
cd ${backup_path}

if [[ "$SLEEP_TIME" == "" ]];then SLEEP_TIME=86400;fi
if [[ "$EXPIRATION_DAY" == "" ]];then EXPIRATION_DAY=30;fi
if [[ "$MINIMUM_DISK" == "" ]];then MINIMUM_DISK=100;fi

backup(){
  echo ==========================================================
  echo ========================= `date` =========================
  echo ==========================================================
  cat rsync_list.txt |while read lines
  do
    if [ "$lines" == "" ]
    then
      echo No host need to backup
    else
      echo -------------------- backup $lines --------------------
      current_time=`date +%Y%m%d%H%M`
      ip=`echo $lines | awk -F '|' '{print $1}'`
      port=`echo $lines | awk -F '|' '{print $2}'`
      backup_name=$ip-$port
      max_reserve_count=`echo $lines | awk -F '|' '{print $3}'`                                                                            
      if [ "$max_reserve_count" == "" ];then max_reserve_count=15;fi
      echo "Max reserve count is $max_reserve_count"
      delete_limited_file 
      echo ip is $ip, port is $port,backup_path is ${backup_path}/$backup_name
      echo rsync -vzrtopg --progress root@$ip::backup --delete $backup_path/$backup_name --port $port
      rsync -vzrtopg --progress root@$ip::backup --delete $backup_path/$backup_name --port $port
      echo tar -zcvf ${backup_name}-${current_time}-rsyncbak.tgz $backup_name
      tar -zcvf ${backup_name}-${current_time}-rsyncbak.tgz $backup_name
      mkdir -p $backup_path/${backup_name}_rsyncbak/
      echo mv ${backup_name}-${current_time}-rsyncbak.tgz $backup_path/${backup_name}_rsyncbak/
      mv ${backup_name}-${current_time}-rsyncbak.tgz $backup_path/${backup_name}_rsyncbak/
    fi
  done
  echo -e "Backup done\n\n\n"
}

create_db_file(){
if [ -f rsync_list.txt ]
then
  echo "rsync_list.txt exists"
else
  echo "No rsync_list.txt file, create."
  touch rsync_list.txt
fi
}

delete_overdue_file(){
  echo Deleting file $EXPIRATION_DAY day ago
  find $backup_path -mtime +$EXPIRATION_DAY -name "*-rsyncbak.tgz" | xargs -I {} echo {} will be deleted 
  find $backup_path -mtime +$EXPIRATION_DAY -name "*-rsyncbak.tgz" | xargs rm -rf 
  echo Delete complete
}

delete_limited_file(){
  exist_file_count=`ls $backup_path/${backup_name}_rsyncbak| wc -l`
  echo Exist file count is $exist_file_count
  if [ $exist_file_count -ge $max_reserve_count ]
  then
    need_delete_count=`expr $exist_file_count - $max_reserve_count + 1`
    echo need_delete_count is $need_delete_count
    find $backup_path/${backup_name}_rsyncbak -name "*-rsyncbak.tgz" | sort | head -$need_delete_count | xargs echo rm -rf
    find $backup_path/${backup_name}_rsyncbak -name "*-rsyncbak.tgz" | sort | head -$need_delete_count | xargs rm -rf
  fi
}

delete_overdisk_file(){
  oldest_day=`find /backup_client -name "*-rsyncbak.tgz" | awk -F '-' '{print $4}' | grep  ^"[0-9]\{12\}"$ | sort | head -1 | cut -c 0-8`
  echo $oldest_day  
  for old_file in `find /backup_client -name "*-rsyncbak.tgz" | grep $oldest_day `
  do
    if [ `echo $old_file | awk -F '-' '{print $4}' | cut -c 0-8` == "$oldest_day" ]
    then
      echo $old_file will be delete to recycle resource
      rm -rf $old_file
    fi
  done 
}

check_disk(){
  echo Setting minimum disk is ${MINIMUM_DISK}G
  current_disk=`df -B 1g $backup_path | grep $backup_path | awk '{print $3}' `
  while [ $current_disk -le $MINIMUM_DISK ]
  do
    echo current_disk is $current_disk,MINIMUM_DISK is $MINIMUM_DISK
    delete_overdisk_file
    current_disk=`df -B 1g $backup_path | grep $backup_path | awk '{print $3}' `
    sleep 10
  done 
}

create_db_file
while true
do
  delete_overdue_file
  check_disk
  backup
  sleep $SLEEP_TIME
done