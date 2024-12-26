#!/usr/bin/env sh

. lib/ini_conf.sh

### Testing script commands below ###
#############
set -e ### debug
export CONFMAN_MGR
evaluate_pkgconf_selection test/unit/data/test.ini ### debug
#############

