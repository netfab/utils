#!/bin/bash

### --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

programname='compressDir'

### programoptions - space separated list of options definitions
### that the program will recognize
##
## format : (shortopt),(longopt)[:] (shortopt),(longopt)[:]
##
## (shortopt) - short option
## (longopt)  - long option
## [:]        -  optional : character meaning that the option
##					is requiring an argument
##
programoptions='p,pretend r,realrun'

### log system - four values :
## off		- disable logging
## own		- libfunc will create and use its own log directories and files
##					(using ${logrootdir} and ${logfile} below)
## system	- use system log, with logger
## systemd  - use system log, with logger --journald [FIXME NOT implemented]
logsystem='own'

### root log directory - used only with logsystem="own"
## used to build the log directory path
## if commented out or unset, default to : '/var/tmp'
## log directory will be : "${logrootdir}/${programname}"
logrootdir='/tmp'

### log file name - used only with logsystem="own"
## if commented out or unset, default to "${programname}-script.log"
logfile="${programname}-script.log"

### --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

libfuncrootdir='/home/netfab/dev/bash'
libfuncdir="${libfuncrootdir}/libfunc"

###
## exports MY_CONFIG_HOME and MY_DESKTOP_DIR
## see fn_setup_environment() function
source "${libfuncdir}/core.sh"

### --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

fn_log "test"
fn_log 'ok'

if fn_option_enabled 'realrun' ; then
	ok=$(fn_option_value 'realrun')
	printf "$ok\n"
	fn_run_command 'ls -l /tmp/root'
	printf "%d\n" $?
fi
printf "$MY_CONFIG_HOME\n"


#fn_exit_with_fatal_error "that's another test ! :)"

