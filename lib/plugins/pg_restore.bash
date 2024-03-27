#!/usr/bin/bash
set -euo pipefail

# -- PGDump Class -------------------------------------------------------------

pg_restore.__load__() {
    return 0
}

pg_restore.run() {
    local _restoredir=$(pwd)/import/${host[name]}
    local _logdir=$(pwd)/logs
    local _pgpassfile=~/.pgpass
    declare -A pids=()

    function __write_pgpass() {
        if [[ ! -z "${host[name]}" ]]; then
            touch ${_pgpassfile} && \
            chmod 0600 ${_pgpassfile}
            printf "%s:%s:*:%s:%s" \
                ${host[db_host]} \
                ${host[db_port]} \
                ${host[db_user]} \
                ${host[db_pass]} \
            > ${_pgpassfile}
        fi
    }

    function __pre() {
        ${ui}.debug 'text' '\n'
        mkdir -p ${_restoredir} ${_logdir}
        dbs="${dblist}"
        test -f ${cfgdir}/databases/${dblist}.txt && \
            dbs=$(< ${cfgdir}/databases/${dblist}.txt);
        for db in ${dbs}; do
            # Check if dump file exists
            [ ! -f ${_restoredir}/${db}.${host[restore_ext]} ] && \
                ${ui}.error && \
                ${ui}.print $"Dump file not found: %s\n" \
                    ${db}.${host[restore_ext]} && \
                exit -1
        done
        __write_pgpass
        echo
    }

    function __post() {
        rm -rf ${_pgpassfile}
    }

    function __wait_processes() {
        ${ui}.info && \
        ${ui}.item $"Waiting for processes to complete\n"
        ${ui}.line 'compact'
        while true; do
            alive_pids=()
            for _pid in "${!pids[@]}"; do
                _db=${pids[${_pid}]}
                kill -0 "${_pid}" 2>/dev/null \
                    && _etime[${_pid}]=$(ps -o etimes= -p ${_pid} || :) \
                    && alive_pids+="${_pid} "
                ${ui}.info && \
                    ${ui}.print '%s ' $(${ui}.color green; echo "[pg_restore]")
                ${ui}.color && \
                    ${ui}.subitem $"process still running "
                ${ui}.print '%s ' \
                    $(${ui}.color gold; ${ui}.arrow right; ${ui}.color)
                ${ui}.print "[db=${_db}, pid=${_pid}, etime=%ss]\n" \
                    ${_etime[${_pid}]}
            done
            [ ${#alive_pids[@]} -eq 0 ] && break
            sleep 5
        done
        ${ui}.print '\n'
        ${ui}.info && \
        ${ui}.print '%s ' $(${ui}.color green; echo "[pg_restore]")
        ${ui}.color && ${ui}.subitem $"all processes terminated\n"
        ${ui}.line 'compact'
    }

    function __pg_restore()  {
        local _pg_restore=$(which pg_restore || exit -1)
        local _ext=${host[restore_ext]:-pgc}
        local _restorefile=${db}.${_ext}
        local _logfile=import-${db}-$(date +"%Y%m%d%H%M%S").${_ext}.log
        local _cmd="${_pg_restore} \
            -h ${host[db_host]} \
            -p ${host[db_port]} \
            -U ${host[db_user]} \
            -F ${host[restore_format]:0:1} \
            ${host[restore_extraopts]:-} \
            -O -v -d ${db} \
            ${_restoredir}/${_restorefile}"
        _cmd=$(echo -ne ${_cmd})
        ${ui}.debug 'line' 'compact'
        ${ui}.debug && ${ui}.tab 2
        ${ui}.debug 'subitem' $"Running command:\n"
        ${ui}.debug 'text' "$(${ui}.color gold)${_cmd//${_restoredir}\//} \
            $(${ui}.color)" \
                | fold -sw 60 \
                | sed "s/^/$(printf '%14s' ' ')/g"
        ${ui}.debug 'text' '\n'
        ${ui}.debug && ${ui}.tab 2
        ${ui}.debug 'subitem' $"Process will run in backgroud [logfile=%s]\n" \
            ${_logfile}
        ${_cmd} > ${_logdir}/${_logfile} 2>&1 &
        pids+=([$!]=${db})
    }

    function __run() {
        ${ui}.debug 'text' '\n'
        dbs="${dblist}"
        test -f ${cfgdir}/databases/${dblist}.txt && \
            dbs=$(< ${cfgdir}/databases/${dblist}.txt);
        for db in ${dbs}; do
        ${ui}.info && \
            ${ui}.item $"Starting %s %s [host=%s, db=%s]\n" \
                "pg_restore" \
                $(${ui}.color gold; ${ui}.arrow right; ${ui}.color) \
                ${host[name]} \
                ${db}
            __pg_restore
            ${ui}.debug 'text' '\n'
        done
        __wait_processes
    }

    __pre
    __run
    __post
}

pg_restore.__load__

# vim: ts=4:sw=4:sts=4:et
