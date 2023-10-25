#!/bin/bash
pathbase="/var/lib/libvirt/images"
if (( "$#" != "4" ))
then
  echo -n "Missing argument : ./startvm.sh name core mem image"
  exit -1
fi

image=""
case $4 in
  "idle" | "stressng" | "dsb")
    image="${pathbase}/baseline-ubuntu20-04.qcow2"
    ;;

  "wordpress")
    image="${pathbase}/baseline-ubuntu20-04-wp.qcow2"
    ;;

  "tpcc")
    image="${pathbase}/baseline-ubuntu20-04-tpcc.qcow2"
    ;;

  "tpch")
    image="${pathbase}/baseline-ubuntu20-04-tpch.qcow2"
    ;;

  *)
    echo -n "Unknow image $4 for $1"
    exit -1
    ;;
esac

curl "http://127.0.0.1:8099/deploy?name=$1&cpu=$2&mem=$3&qcow2=$pathbase/$1.qcow2"
# We only leave this script when VM is operational
while sleep 15;
do
  vm_ip=$( virsh --connect=qemu:///system domifaddr "$1" | tail -n 2 | head -n 1 | awk '{ print $4 }' | sed 's/[/].*//' );
  if [ -n "$vm_ip" ]; then #VAR is set to a non-empty string
    break
  fi
done
# May not be fully initialized : test if ssh works (is ping enough?)
count=0
while true;
do
  ssh_test=$( ssh vmtornado@"${vm_ip}" -o StrictHostKeyChecking=no -o LogLevel=ERROR 'echo success' )
  if [[ $ssh_test == *"success"* ]]; then
    echo "Setup : vm $1 ready with ip $vm_ip"
    break
  fi
  count=$(( count + 1 ))
  echo "Start : unable to ssh test vm $1 with ip $vm_ip (trial $count)"
  sleep 15
done
# Post init step
# DSB
if [[ "$5" = "dsb" ]]; then
  ssh vmtornado@"${vm_ip}" -o StrictHostKeyChecking=no -o LogLevel=ERROR "cd /usr/local/src/DeathStarBench-master/socialNetwork/ && docker-compose down && docker-compose up -d"
fi
# Wordpress
if [[ "$5" = "wordpress" ]]; then
  payload="sleep 900 && ./changewpip.sh ${vm_ip}"
  if [[ ${fullip} != *":"* ]];
  then
    payload="$payload && sudo firewall-cmd --zone=public --add-port=80/tcp --permanent && sudo firewall-cmd --reload"
  fi
  ssh vmtornado@"${vm_ip}" -o StrictHostKeyChecking=no -o LogLevel=ERROR "$payload"
fi
