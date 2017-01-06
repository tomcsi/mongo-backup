#!/bin/bash

export AZURE_STORAGE_ACCOUNT=
export AZURE_STORAGE_ACCESS_KEY=

MONGOUSER=
MONGOPASS=

MAX_BACKUPS=5
BACKUP_NAME=$(date +\%Y.\%m.\%d.\%H\%M\%S | sed 's/\./-/g')
CWD=$(pwd)

if mongodump -u $MONGOUSER -p $MONGOPASS --authenticationDatabase admin --out /backup/${BACKUP_NAME} --host localhost --port 27017; then
  cd /backup/${BACKUP_NAME}/
  azure storage container create ${BACKUP_NAME}
  find * -type f -exec azure storage blob upload --container ${BACKUP_NAME} -b {} -f {} \;
  cd ${CWD}
  rm -rf /backup/${BACKUP_NAME}
fi

if [ -n "${MAX_BACKUPS}" ]; then
  BACKUPS=$(azure storage container list --json | jq '.[].name' | sed 's/"//g')
  BACKUP_NUM=$(echo ${BACKUPS} | tr ' ' '\n' | wc -l)
  DELETE_BACKUP_NUM=$(expr ${BACKUP_NUM} - ${MAX_BACKUPS})
  i=0
  for BACKUP in $BACKUPS;
  do
    if [ ${i} -eq ${DELETE_BACKUP_NUM} ]; then
      continue
    fi
    azure storage container delete -q ${BACKUP} && i=$(expr ${i} + 1)
  done
fi

exit 0
