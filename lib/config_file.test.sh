#!/usr/bin/env sh

. config_file.sh

### Testing script commands below ###
#############
set -e ### debug
export CONFMAN_MGR
evaluate_confmanconf "$@" ### debug
#############

