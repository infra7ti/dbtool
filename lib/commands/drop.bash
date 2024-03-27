#!/usr/bin/bash
set -euo pipefail

# -- Create Class --------------------------------------------------------------

drop.run() {
    local _plugin=$(basename ${host[drop_tool]})

    ${ui}.info && ${ui}.tab 2 && \
        ${ui}.subitem $"Loading plugin: "
    test -f ${libdir}/plugins/${_plugin}.bash && \
        ${ui}.emphasis $"%s " ${_plugin} && \
        source ${libdir}/plugins/${_plugin}.bash

    eval \${_plugin}.run
}

drop.__load__() {
    unset -v cmd
    options+='c:'
    arguments['c']="cmd"
}

drop.__load__

# vim: ts=4:sw=4:sts=4:et
