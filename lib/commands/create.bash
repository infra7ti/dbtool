#!/usr/bin/bash
set -euo pipefail

# -- Create Class --------------------------------------------------------------

create.run() {
    local _plugin=$(basename ${host[create_tool]})

    ${ui}.info && ${ui}.tab 2 && \
        ${ui}.subitem $"Loading plugin: "
    test -f ${libdir}/plugins/${_plugin}.bash && \
        ${ui}.emphasis $"%s " ${_plugin} && \
        source ${libdir}/plugins/${_plugin}.bash

    eval \${_plugin}.run
}

create.__load__() {
    unset -v cmd
    options+='c:'
    arguments['c']="cmd"
}

create.__load__

# vim: ts=4:sw=4:sts=4:et
