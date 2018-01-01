#!/bin/sh
#
# portstools.sh <jail> <update|install|remove> <port|all>
#

checkArgs() {
  if [ "$#" -lt 3 ];
  then
    usage
    return 1
  fi
}

usage() {
  echo "$0 <jail> <update|install|remove> <port_name|all>"
}

mountSrcBaseInJail() {
  mount -t nullfs -o ro /usr/src /jail/${JNAME}/usr/src || {
    echo "Failed to mount SRC_BASE for jail ${JNAME}"
    return 1
  }
}

umountSrcBaseInJail() {
  umount /jail/${JNAME}/usr/src || {
    echo "Failed to umount SRC_BASE for jail ${JNAME}"
    return 1
  }
}

mountPortsInJail() {
  mount -t nullfs /usr/ports /jail/${JNAME}/usr/ports || {
    echo "Failed to mount ports tree for jail ${JNAME}"
    return 1
  }
}

umountPortsInJail() {
  umount /jail/${JNAME}/usr/ports || {
    echo "Failed to umount ports tree for jail ${JNAME}"
    return 1
  }
}

updateAllPorts () {
  portmaster -a -j ${JNAME} || {
    echo "Failed to update ports for ${JNAME}"
  return 1
}
}

runUpdate () {
  if [ $1 == "all" ];
  then
    updateAllPorts || return 1
  else
    checkIfPorstExists
    #(whereis lsof netdata KO |awk 'if($2!=""){print $2}')
    updatePorts
  fi
}

runInstall () {
  echo "TODO!"
}

runRemove () {
  echo "TODO!"
}

checkArgs || exit 1
JNAME=$1
shift

case $1 in
  update)
    shift
    runUpdate "$@" || {
      echo "Failed to perform port(s) update(s) for ${JNAME}"
    exit 1
  }
  ;;
install)
  shift
  runInstall "$@"
  ;;
remove)
  shift
  runRemove "$@"
  ;;
*)
  usage
  exit 1
  ;;
esac

