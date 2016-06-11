#!/bin/bash

source $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/env.sh
if [ -d "${TRIPAL_VM_WORKDIRPATH}" ]; then
    diskutil unmount force ${TRIPAL_VM_WORKDIRPATH}
    sudo rm -rf ${TRIPAL_VM_WORKDIRPATH}
fi
