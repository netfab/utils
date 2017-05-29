#!/bin/bash

### --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

programname='compressDir'
programversion='0.3.0'

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

### --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

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
#	EDIT WITH CARE	#

libfuncrootdir='/home/netfab/dev/bash'
libfuncdir="${libfuncrootdir}/libfunc"

###
## exports MY_CONFIG_HOME and MY_DESKTOP_DIR
## see fn_setup_environment() function
source "${libfuncdir}/core.sh"

### --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

if [ ${UID} -ne 0 ]; then

	umask 0027

# root is in da place
else
	export MY_CONFIG_HOME='/etc'
fi

### --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

# txt file containing list of targets
declare -r blacklist="${MY_CONFIG_HOME}/${programname}/targets.list"

### --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

function fn_parse_blacklist() {
	fn_print_msg "parsing configuration file : ${blacklist}"

	if [ ! -f "${blacklist}" ] || [ ! -r "${blacklist}" ]; then
		fn_exit_with_fatal_error 'configuration file unreadable or irregular'
	fi

	local HOMELENGTH=${#HOME}
	(( HOMELENGTH++ ))

	local parsingBar

	fn_print_msg "# = comment   . = skip   W = warning"

	while read target; do
		# skip comments
		if [ "${target:0:1}" = '#' ]; then
			parsingBar+='#'
			continue
		fi

		# skip empty lines
		if [ ${#target} -eq 0 ]; then
			parsingBar+='.'
			continue
		fi

		# don't allow relative paths
		if [ "${target:0:1}" != "/" ]; then
			parsingBar+='W'
			# TODO notify
			fn_print_warn_msg "skipping relative path : ${target}"
			continue
		fi

		# if not root, target must be in the user home
		if [ ${UID} -ne 0 ]; then
			if [ "${target:0:$HOMELENGTH}" != "${HOME}/" ]; then
				parsingBar+='W'
				# TODO notify
				fn_print_warn_msg "skipping ${target}. You are not root, backup targets must be in your home."
				continue
			fi
		fi
		#printf "%s\n" "${target}"
	done < "${blacklist}"

	parsingBar+=' done ! :)'
	fn_print_msg "${parsingBar}"
}

### --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

fn_print_msg "${programname}, vers. ${programversion}"

fn_parse_blacklist
unset -f fn_parse_blacklist

#fn_log "test"
#fn_log 'ok'

#if fn_option_enabled 'realrun' ; then
#	ok=$(fn_option_value 'realrun')
#	printf "$ok\n"
#	fn_run_command 'ls -l /tmp/root'
#	printf "%d\n" $?
#fi


#fn_exit_with_fatal_error "that's another test ! :)"

