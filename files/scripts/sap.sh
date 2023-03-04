#! /usr/bin/env bash
#
# Author:       Thomas Bendler <code@thbe.org>
# Date:         Tue Feb 14 12:45:53 CET 2023
#
# Note:         To debug the script change the shebang to: /usr/bin/env bash -vx
#
# Prerequisite: This release needs a shell that could handle functions.
#               If shell is not able to handle functions, remove the
#               error section.
#
# Release:      0.9.0
#
# ChangeLog:    v0.9.0 - Initial release
#
# Purpose:      Control the local SAP instance
#

### Path of SAP services file ###
SAP_SERVICES="/usr/sap/sapservices"

### Determine if SAP services are runnning ###
if [ "$(ps aux | grep "[s]apstartsrv" | grep -v hostctrl | wc -l)" -eq 0 ]; then
  SAP_SERVICES_ACTIVE="O"
else
  SAP_SERVICES_ACTIVE="X"
fi

### Get instance variables ###
HDB_ACTIVE="O"; ASCS_ACTIVE="O"; DIALOG_ACTIVE="O"
if [ -f ${SAP_SERVICES} ]; then
  SAP_SERVICES_ITEM=$(cat ${SAP_SERVICES} | grep sapstartsrv | grep -v DAA)
  while read -r instance; do
    SAP_INSTANCE_ITEM=$(echo ${instance} | cut -d '/' -f 5)
    case ${SAP_INSTANCE_ITEM} in
      HDB*  ) SAP_INSTANCE_TYPE="DB";;
      ASCS* ) SAP_INSTANCE_TYPE="CI";;
      D*    ) SAP_INSTANCE_TYPE="APP";;
      *     ) echo "Can't determine instance type for ${SAP_INSTANCE_ITEM}, aborting"; exit 1;;
    esac

    ### Set SAP HANA database variables ###
    if [ ${SAP_INSTANCE_TYPE} == "DB" ]; then
      HDB_ACTIVE="X"
      HDB_SIDADM=$(echo ${instance} | grep sapstartsrv | cut -d ' ' -f 5)
      HDB_PATH=$(echo ${instance} | grep sapstartsrv | cut -d '/' -f 1,2,3,4,5)
      HDB_INSTANCE_STRING=$(echo ${instance} | grep sapstartsrv | cut -d '/' -f 5)
      HDB_INSTANCE_NR=${HDB_INSTANCE_STRING: -2}
    fi

    ### Set SAP ASCS instance variables ###
    if [ ${SAP_INSTANCE_TYPE} == "CI" ]; then
      ASCS_ACTIVE="X"
      ASCS_SIDADM=$(echo ${instance} | grep sapstartsrv | cut -d ' ' -f 5)
      ASCS_PATH=$(echo ${instance} | grep sapstartsrv | cut -d '/' -f 1,2,3,4,5)
      ASCS_INSTANCE_STRING=$(echo ${instance} | grep sapstartsrv | cut -d '/' -f 5)
      ASCS_INSTANCE_NR=${ASCS_INSTANCE_STRING: -2}
    fi

    ### Set SAP dialog instance variables ###
    if [ ${SAP_INSTANCE_TYPE} == "APP" ]; then
      DIALOG_ACTIVE="X"
      DIALOG_SIDADM=$(echo ${instance} | grep sapstartsrv | cut -d ' ' -f 5)
      DIALOG_PATH=$(echo ${instance} | grep sapstartsrv | cut -d '/' -f 1,2,3,4,5)
      DIALOG_INSTANCE_STRING=$(echo ${instance} | grep sapstartsrv | cut -d '/' -f 5)
      DIALOG_INSTANCE_NR=${DIALOG_INSTANCE_STRING: -2}
    fi
  done <<< "${SAP_SERVICES_ITEM}"
fi

### Determin script action ###
case $1 in
  start) SCRIPT_ACTION="start";;
  stop) SCRIPT_ACTION="stop";;
  status) SCRIPT_ACTION="status";;
  *) echo "Parameter ${1} is not supported, please use start/ stop/ status instead"; exit 1;;
esac

if [ ${SCRIPT_ACTION} == "start" ]; then
  echo "Check if SAP services are started"
  if [ ${SAP_SERVICES_ACTIVE} == "X" ]; then
    echo "Start SAP services"
    /usr/sap/sapservices
  fi
  if [ ${HDB_ACTIVE} == "X" ]; then
    echo "Start SAP HANA database"
    /usr/bin/su -c "${HDB_PATH}/HDB start" - ${HDB_SIDADM}
  fi
  if [ ${ASCS_ACTIVE} == "X" ]; then
    echo "Start SAP ASCS instance"
    /usr/bin/su -c "${ASCS_PATH}/exe/sapcontrol -prot NI_HTTP -nr ${ASCS_INSTANCE_NR} -function StartSystem ALL" - ${ASCS_SIDADM}
  fi
  if [ ${DIALOG_ACTIVE} == "X" ]; then
    echo "Start SAP dialog instance"
    /usr/bin/su -c "${DIALOG_PATH}/exe/sapcontrol -prot NI_HTTP -nr ${DIALOG_INSTANCE_NR} -function StartSystem ALL" - ${DIALOG_SIDADM}
  fi
fi

if [ ${SCRIPT_ACTION} == "stop" ]; then
  echo "Check if SAP services are started"
  if [ ${SAP_SERVICES_ACTIVE} == "O" ]; then
    echo "SAP services are not running, aborting!"
    exit 1
  fi
  if [ ${DIALOG_ACTIVE} == "X" ]; then
    echo "Stop SAP dialog instance"
  fi
    /usr/bin/su -c "${DIALOG_PATH}/exe/sapcontrol -prot NI_HTTP -nr ${DIALOG_INSTANCE_NR} -function StopSystem ALL" - ${DIALOG_SIDADM}
  if [ ${ASCS_ACTIVE} == "X" ]; then
    echo "Stop SAP ASCS instance"
    /usr/bin/su -c "${ASCS_PATH}/exe/sapcontrol -prot NI_HTTP -nr ${ASCS_INSTANCE_NR} -function StopSystem ALL" - ${ASCS_SIDADM}
  fi
  if [ ${HDB_ACTIVE} == "X" ]; then
    echo "Stop SAP HANA database"
    /usr/bin/su -c "${HDB_PATH}/HDB stop" - ${HDB_SIDADM}
  fi
fi

if [ ${SCRIPT_ACTION} == "status" ]; then
  echo "Check if SAP services are started"
  if [ ${SAP_SERVICES_ACTIVE} == "O" ]; then
    echo "SAP services are not running, aborting!"
    exit 1
  fi
  if [ ${HDB_ACTIVE} == "X" ]; then
    echo "SAP HANA database status"
    /usr/bin/su -c "${HDB_PATH}/exe/sapcontrol -nr ${HDB_INSTANCE_NR} -function GetSystemInstanceList" - ${HDB_SIDADM}
  fi
  if [ ${ASCS_ACTIVE} == "X" -o ${DIALOG_ACTIVE} == "X" ]; then
    echo "SAP ASCS and dialog status"
    /usr/bin/su -c "/${DIALOG_PATH}/exe/sapcontrol -prot NI_HTTP -nr ${DIALOG_INSTANCE_NR} -function GetSystemInstanceList" - ${DIALOG_SIDADM}
  fi
fi
