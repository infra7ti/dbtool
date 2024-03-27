#!/usr/bin/bash

declare -g options=':'
declare -Ag arguments=()

function _requires_opt() {
    set +u
    local _opt=${1:-}
    local _var=$(eval echo ${2:-})

    if [[ -z "${_var}" ]] && [[ ! -z "${_opt}" ]]; then
        ${ui}.error && \
        ${ui}.print \
            $"Required option missing: '-%s'. You must provide it.\n\n" \
            ${_opt}
        exit -1
    fi
    set -u
}
