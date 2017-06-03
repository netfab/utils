#!/bin/bash
#
# compressDir, semi-automatic archiver program.
# Copyright © 2011 - 2017 netfab <netbox253@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 3 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

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
programoptions='h,help p,pretend r,realrun'

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
## exports MY_CONFIG_HOME and MY_DESKTOP_DIR for regular users
## see fn_setup_environment() function
source "${libfuncdir}/core.sh"

### --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

if [ ${UID} -ne 0 ]; then

	umask 0027

	# root directory where tar archives will be created
	#declare -r outdir="${HOME}/archives"
	declare -r outdir="/tmp/archives"
	declare -ri maxarchives=3

# root is in da place
else

	# environment not setted up for root
	export MY_CONFIG_HOME='/etc'

	#declare -r outdir="/data/archives"
	declare -r outdir="/tmp/archives"
	declare -ri maxarchives=3
fi

### --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

# txt file containing list of targets
declare -r blacklist="${MY_CONFIG_HOME}/${programname}/targets.list"

# indexed array that will contain valid targets
# after fn_parse_blacklist run
declare -a whitelist

### --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

function fn_display_help() { # <<<
	local TXTLAG='\e[8C'
	fn_log "displaying help"

	printf "\n${BLDWHT}${programname} vers. ${programversion}${TXTRST}, using ${BLDWHT}libfunc vers. ${libfuncversion}${TXTRST}\n"
	printf "Semi-automatic archiver program\n"

	printf "\nUsage : ${programname} [options]\n"

	printf "\n  ${BLDGRN}Help:${TXTRST}\n"
	printf "    -h, --help       ${TXTLAG}Display help and exit.\n"
	printf "    -v, --version    ${TXTLAG}Display version and exit.\n\n"

	printf "  ${BLDGRN}Run backup:${TXTRST}\n"
	printf "    -p, --pretend    ${TXTLAG}Show what would be run.\n"
	printf "    -r, --realrun    ${TXTLAG}Here we go ! rm -rf * :)\n\n"

	printf " --pretend is the default behavior when no options are supplied.\n"
	printf " --realrun and --pretend are opposed. They can not be used simultaneously.\n"
	printf " --realrun is required to really create the archives.\n\n"

	fn_exit_with_status 0
} # >>>

function fn_parse_blacklist() { # <<<
	fn_print_msg "parsing configuration file : ${blacklist}"

	if [ ! -f "${blacklist}" ] || [ ! -r "${blacklist}" ]; then
		fn_exit_with_error 'configuration file unreadable or irregular'
	fi

	local HOMELENGTH=${#HOME}
	(( HOMELENGTH++ ))

	local parsingBar

	fn_print_msg "# = comment   . = skip   W = warning   T = valid target"

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

		# removing ending slashes
		while [ "${target:((-1))}" == "/" ]; do
			# TODO notify
			parsingBar+='W'
			fn_print_warn_msg "${target} : removing ending slash"
			target="${target:0:(${#target}-1)}"
			if [ ${#target} -eq 0 ]; then
				fn_print_warn_msg 'removing wrong entry'
				continue 2
			fi
		done

		# if target is not a directory, skipping it
		if [ ! -d "${target}" ]; then
			parsingBar+='W'
			# TODO notify
			fn_print_warn_msg "${target} is not a directory, skipping it"
			continue
		fi

		# skipping symlinks
		if [ -h "${target}" ]; then
			parsingBar+='W'
			# TODO notify
			fn_print_warn_msg "${target} is a symlink, skipping it"
			continue
		fi

		#printf "%s\n" "${target}"
		parsingBar+='T'
		whitelist[ ${#whitelist[@]} ]="${target}"
	done < "${blacklist}"

	parsingBar+=' done ! :)'
	fn_print_msg "${parsingBar}"
	fn_print_msg "${#whitelist[@]} valid targets"

	if [ ${#whitelist[@]} -eq 0 ]; then
		fn_print_warn_msg 'no target : please fix your configuration file'
		fn_exit_with_status 7
	fi
} # >>>

function fn_create_root_directory() { # <<<
	printf 'creating tar root directory ' >&2
	fn_run_command "mkdir -p \"${outdir}\""
	if [ $? -ne 0 ]; then
		fn_exit_with_error "mkdir failure"
	fi
	cd "${outdir}" || fn_exit_with_error 'change directory failure'
	fn_print_status_ok_eol
} # >>>

function fn_create_relative_directory() { # <<<
	printf 'creating relative directory ' >&2
	fn_run_command "mkdir -p \"${@}\""
	if [ $? -ne 0 ]; then
		fn_exit_with_error "relative mkdir failure"
	fi
	cd "${@}" || fn_exit_with_error 'change directory failure'
	fn_print_status_ok_eol
} # >>>

### --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

fn_option_enabled 'help' && fn_display_help

fn_print_msg "${programname}, vers. ${programversion}"

if fn_option_enabled 'pretend' && fn_option_enabled 'realrun'; then
	fn_print_info_msg "Please run ${BLDWHT}${programname} --help${TXTRST} for more information."
	fn_exit_with_error '--pretend and --realrun are incompatible.'
fi

if fn_option_disabled 'pretend' && fn_option_disabled 'realrun'; then
	fn_print_warn_msg 'Auto-appending --pretend to parameters.'
	fn_print_info_msg 'Since --realrun is not provided, --pretend is the default behavior.'
	fn_print_info_msg 'You should use --pretend yourself to avoid this message.'
	fn_print_info_msg "Please run ${BLDWHT}${programname} --help${TXTRST} for more information."
	fn_forced_option 'pretend'
fi

fn_parse_blacklist
unset -f fn_parse_blacklist


cd "${outdir}" 2> /dev/null || fn_create_root_directory
unset -f fn_create_root_directory

if [ ! -w . ]; then
	fn_exit_with_error "$PWD directory not writeable"
fi

declare -i i=0
declare -r DATERFC3339=$(date --rfc-3339=date)

# --- --- ---
#  main loop
# --- --- ---

fn_print_status_msg 'entering main loop ...'

while [ $i -lt ${#whitelist[@]} ]; do
	#printf "${whitelist[$i]}\n"

	f=$(basename "${whitelist[$i]}")
	f="${f// /_}"
	# if the target is hidden, don't hide the generated archive.
	[ "${f:0:1}" = '.' ] && f=${f/./DoT_}

	# tar gzipped filename
	outfile="${f}-${DATERFC3339}.tar.gz"

	relativeoutdir=$(dirname "${whitelist[$i]}")
	if [ ${UID} -ne 0 ]; then
		## after dirname run above we want to eliminate
		##	${HOME} to get a relative path XXX(1)
		# /home/user/path_to	--> path_to
		# /home/user			--> /home/user
		relativeoutdir="${relativeoutdir#${HOME}/}"
		if [ "${relativeoutdir}" == "${HOME}" ]; then
			unset -v relativeoutdir
		fi
	else
		relativeoutdir="${relativeoutdir#*/}"
	fi

	# see XXX(1) above
	if [ -v relativeoutdir ]; then
		cd "${relativeoutdir}" 2> /dev/null || fn_create_relative_directory "${relativeoutdir}"
	fi

	#printf "${whitelist[$i]} $relativeoutdir $outfile\n"

	fn_log "current directory : $PWD"

	if fn_option_enabled 'pretend'; then
		fn_print_msg "would run : tar -czf \"$outfile\" \"${whitelist[$i]}\""
	elif fn_option_enabled 'realrun'; then
		fn_run_command "tar -czf \"${outfile}\" \"${whitelist[$i]}\""
		declare -i ret=$?
		if [ $ret -ne 0 ]; then
			fn_print_warn_msg "previous tar command ended up with status : $ret"
		else
			fn_print_info_msg "created ${outfile} :-)"
		fi
	fi

	# --- --- --- --- --- --
	# remove oldest archives
	# --- --- --- --- --- --

	#printf "${f}"
	declare -a listing=( "${f}"-*.tar.gz )
	if [ "${listing[0]}" == "${f}-*.tar.gz" ]; then
		unset -v listing
	fi

	fn_print_info_msg "\t${#listing[@]} files in directory $PWD"
	fn_print_info_msg "\tkeeping at least ${maxarchives} files :"

	declare -i cnt=0
	declare -i j=${#listing[@]}

	while [ $j -gt 0 ]; do

		((j--))
		((cnt++))

		if [ $cnt -le ${maxarchives} ]; then
			fn_print_info_msg "\t\t[ keeped ] ${listing[$j]}"
			continue
		fi
		fn_print_info_msg "\t\t[ removed ] ${listing[$j]}"

		if fn_option_enabled 'pretend'; then
			fn_print_msg "would run : rm \"${listing[$j]}\""
		elif fn_option_enabled 'realrun'; then
			fn_run_command "rm \"${listing[$j]}\""
		fi

	done

	# --- --- --- ---
	#  next iteration
	# --- --- --- ---

	cd "${outdir}"

	(( i++ ))

	sleep 3
done

fn_print_status_msg "${programname} exiting ... :)"

# vim: set foldmethod=marker foldmarker=<<<,>>> foldlevel=0:
