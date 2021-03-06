#!/bin/sh
#
# portstools.sh <global|jail> <check|update|install|remove> <port|all>
#

checkArgs() {
  if [ "$#" -lt 2 ];
  then
    usage
    return 1
  fi
}

usage() {
  echo "$0 <global|jail> <check|update|install|remove> <port_name|all>"
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

cleanExit () {
  if [ "${JNAME}" != "global" ];
  then
    umountPortsInJail || return 1
    umountSrcBaseInJail || return 1
    echo "Umounting ports & src then leaving"
  fi
  exit $1
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
    echo "Updating all ports for ${JNAME}"
    CMD="portmaster -m DISABLE_VULNERABILITIES=yes -aydbg --no-confirm"
  else
    CMD="portmaster -m DISABLE_VULNERABILITIES=yes --no-confirm $@"
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

installPorts () {
  echo "ports to install $@"
  for i in $@
  do
    installPort $i || {
      echo "Failed to install port $i"
      return 1
    }
  done
}

makePort () {
  PORT=$1
  if [ "${JNAME}" != "global" ] ; then
    mountPortsInJail || return 1
    mountSrcBaseInJail || return 1
    CMD_PREFIX="jexec ${JNAME}"
  fi
  findPortInTree $PORT || {
    echo "Failed to find port in tree"
    return 1
  }
  PORT_PATH=$(findPortInTree $PORT)
  echo "Installing $PORT_PATH"
  $CMD_PREFIX make -C $PORT_PATH $ACTION clean
  if [ "${JNAME}" != "global" ];
  then
    umountPortsInJail || return 1
    umountSrcBaseInJail || return 1
  fi
}

installPort () {
  PORT=$1
  if [ "${JNAME}" != "global" ] ; then
    mountPortsInJail || return 1
    mountSrcBaseInJail || return 1
    CMD_PREFIX="jexec ${JNAME}"
  fi
  findPortInTree $PORT || {
    echo "Failed to find port in tree"
    return 1
  }
  PORT_PATH=$(findPortInTree $PORT)
  echo "Installing $PORT_PATH"
  $CMD_PREFIX make -C $PORT_PATH install clean
  if [ "${JNAME}" != "global" ];
  then
    umountPortsInJail || return 1
    umountSrcBaseInJail || return 1
  fi
}

findPortInTree () {
  PORT=$1
  PORT_PATH=$(whereis $PORT| awk '{if ($2 != "") { print $NF }}')
  [ -z "$PORT_PATH" ] && {
    echo "Failed to find port path"
    return 1
  }
  echo $PORT_PATH
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
      exit 1
      cleanExit 1
    }
    ;;
  update)
    shift
    updatePorts "$@" || {
      echo "Failed to perform port(s) update(s) for ${JNAME}"
      cleanExit 1
    }
    ;;
  install)
    shift
    ACTION="$1"
    installPorts "$@" || {
      echo "Faileds to install port(s)"
      cleanExit 1
    }
    ;;
  reinstall)
    shift
    ACTION="$1"
    makePort "$@" || {
      echo "Failed to reinstall port(s) $@"
      cleanExit 1
    }
    ;;
  remove)
    shift
    ACTION="deinstall"
    runRemove "$@"
    cleanExit 1
    ;;
  *)
    usage
    exit 1
    ;;
esac

