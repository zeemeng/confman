#!/usr/bin/env sh

. config_file.sh

### Testing script commands below ###
#############
set -eu ### debug
CONFMAN_MGR=apt evaluate_confmanconf "$@" ### debug
#############

