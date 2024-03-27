#!/usr/bin/bash
set -euo pipefail

# -- UI Class -----------------------------------------------------------------

ui.__load__() {
    # Default User Interface
    : ${ui:=cli}

    # Loads the UI
    source ${libdir}/ui/${ui}.bash
}

ui.__load__

# vim: ts=4:sw=4:sts=4:et
