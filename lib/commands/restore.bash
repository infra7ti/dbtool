#!/usr/bin/bash
set -euo pipefail

# -- Restore Class ------------------------------------------------------------

restore.run() {
    local _plugin=$(basename ${host[restore_tool]})

    ${ui}.info && ${ui}.tab 2 && \
        ${ui}.subitem $"Loading plugin: "
    test -f ${libdir}/plugins/${_plugin}.bash && \
        ${ui}.emphasis $"%s " ${_plugin} && \
        source ${libdir}/plugins/${_plugin}.bash

    eval \${_plugin}.run
}

restore.__load__() {
    unset -v cmd
    options+='c:'
    arguments['c']="cmd"
}

restore.__load__

# vim: ts=4:sw=4:sts=4:et
