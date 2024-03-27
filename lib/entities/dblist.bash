#!/usr/bin/bash
set -euo pipefail

# -- Host Class ---------------------------------------------------------------

dblist.__load__() {
    unset -v dblist

    options+='d:'
    arguments['d']="dblist"
}

dblist.__load__

# vim: ts=4:sw=4:sts=4:et
