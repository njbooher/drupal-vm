#!/bin/bash

source $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/env.sh
diskutil erasevolume HFS+ ${TRIPAL_VM_WORKDIRNAME} `hdiutil attach -nomount ram://$(echo '16*1024^3/512' | bc)`
