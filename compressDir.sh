#!/bin/bash

libfuncrootdir='/home/netfab/dev/bash'

programname='compressDir'

### log type - three values :
## own		- libfunc will create and use its own log directories and files
##					(using ${logrootdir} and ${logfile} below)
## system	- use system log, with : logger
## systemd  - use system log, with : logger --journald [FIXME NOT implemented]
logtype='own'

### root log directory - used only with logtype="own"
## used to build the log directory path
## if commented out or unset, default to : '/var/tmp'
## log directory will be : "${logrootdir}/${programname}"
logrootdir='/tmp'

### log file name - used only with logtype="own"
## if commented out or unset, default to "${programname}-script.log"
logfile="${programname}-script.log"

daterun=$(date '+%Y-%m-%d-%H:%M:%S')


libfuncdir="${libfuncrootdir}/libfunc"

source "${libfuncdir}/core.sh"

fn_log "test"
fn_log 'ok'
