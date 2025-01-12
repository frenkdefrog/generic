#!/usr/bin/env bash
echo -n '{"data":['
first=1
while IFS= read -r line
do
  if [[ "$line" == UserParameter=* ]]; then
    key=$(echo $line | cut -d= -f2 | cut -d, -f1)
    if [ $first -ne 1 ]; then
      echo -n ","
    fi
    first=0
    echo -n "{\"{#KEY}\":\"$key\"}"
  fi
done < /etc/zabbix/zabbix_agentd.d/custom_webfolder_checksums.conf
echo -n ']}'
