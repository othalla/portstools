#!/bin/sh
#
# portstools.sh <jail> <check|update|install|remove> <port|all>
#

checkArgs() {
  if [ "$#" -lt 3 ];
  then
    usage
    return 1
  fi
}

usage() {
  echo "$0 <jail> <check|update|install|remove> <port_name|all>"
}

mountSrcBaseInJail() {
  mount -t nullfs -o ro /usr/src /jails/${JNAME}/usr/src || {
    echo "Failed to mount SRC_BASE for jail ${JNAME}"
    return 1
  }
}

umountSrcBaseInJail() {
  umount /jails/${JNAME}/usr/src || {
    echo "Failed to umount SRC_BASE for jail ${JNAME}"
    return 1
  }
}

mountPortsInJail() {
  mount -t nullfs /usr/ports /jails/${JNAME}/usr/ports || {
    echo "Failed to mount ports tree for jail ${JNAME}"
    return 1
  }
}

umountPortsInJail() {
  umount /jails/${JNAME}/usr/ports || {
    echo "Failed to umount ports tree for jail ${JNAME}"
    return 1
  }
}

updateAllPorts () {
  if [ "${JNAME}" == "global" ];
  then
    portmaster -a --no-confirm || {
      echo "failed to update all ports for global jail"
      return 1
    }
  else
    mountPortsInJail || return 1
    mountSrcBaseInJail || return 1
    jexec ${JNAME} portmaster -a --no-confirm || {
      echo "failed to update all ports for global jail"
      return 1
    }
  fi
}

updatePorts () {
  CMD_PREFIX=""
  if [ "${JNAME}" != "global" ];
  then
    mountPortsInJail || return 1
    mountSrcBaseInJail || return 1
    CMD_PREFIX="jexec ${JNAME}"
  fi
  if [ "$1" == "all" ];
  then
    CMD="portmaster --no-confirm -a"
  else
    CMD="portmaster --no-confirm $@"
  fi
  $CMD_PREFIX $CMD || {
    echo "failed to update ports"
    return 1
  }
  if [ "${JNAME}" != "global" ];
  then
    umountPortsInJail || return 1
    umountSrcBaseInJail || return 1
  fi
}

checkPorts() {
  if [ "${JNAME}" != "global" ];
  then
    mountPortsInJail || return 1
    mountSrcBaseInJail || return 1
    OPTS="-j ${JNAME}"
  fi
  pkg $OPTS version -vIL= || {
    echo "failed to get port(s) status"
    return 1
  }
  if [ "${JNAME}" != "global" ];
  then
    umountPortsInJail || return 1
    umountSrcBaseInJail || return 1
  fi
}

runInstall () {
  echo "TODO!"
}

runRemove () {
  echo "TODO!"
}

checkArgs "$@" || exit 1
JNAME=$1
shift

case $1 in
  check)
    shift
    checkPorts || {
      echo "Failed to get ports states"
      return 1
    }
    ;;
  update)
    shift
    updatePorts "$@" || {
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

