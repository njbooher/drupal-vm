#!/bin/bash

source $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/env.sh
vagrant destroy -f
rm -rf provisioning/roles