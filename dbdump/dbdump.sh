#!/bin/bash
#
# dbdump - wrapper to mysqldump
# Copyright © 2017 netfab <netbox253@gmail.com>
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

programname='dbdump'
programversion='0.1.0'

### programoptions - space separated list of options definitions
### that the program will recognize
##
## format : (shortopt),(longopt)[:] (shortopt),(longopt)[:]
##
## (shortopt) - short option
## (longopt)  - long option
## [:]        - optional : character meaning that the option
##							is requiring an argument
##
programoptions='d,database: h,help'

### --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

### log system - four values :
## off		- disable logging
## own		- libfunc will create and use its own log directories and files
##					(using ${logrootdir} and ${logfile} below)
## system	- use system log, with logger
## systemd  - use system log, with logger --journald [FIXME NOT implemented]
logsystem='system'

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

declare -r libfuncrootdir=${LIBFUNCROOTDIR:-'/usr/local/lib'}
libfuncdir="${libfuncrootdir}/libfunc"

###
## exports MY_CONFIG_HOME and MY_DESKTOP_DIR for regular users
## see fn_setup_environment() function
source "${libfuncdir}/core.sh" || exit 128

### --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

# File containing login and password for database access
declare -r CREDENTIAL_FILE="/etc/${programname}/credential.txt"

# root backup directory
# gzipped sql dump will be saved to directory :
# 		{ROOT_BACKUP_DIR}/${sql_database}/
declare -r ROOT_BACKUP_DIR='/data/backup.1/db'

# number of files keeped when removing oldest archives
declare -ri MAX_FILES=15


### --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

function fn_display_help() { # <<<
	local TXTLAG='\e[8C'
	fn_log "displaying help"

	printf "\n${BLDWHT}${programname} vers. ${programversion}${TXTRST}, using ${BLDWHT}libfunc vers. ${libfuncversion}${TXTRST}\n"
	printf "Wrapper to mysqldump. Creates gzipped dumps (one par day) of a SQL database.\n"
	
	printf "\nUsage : ${programname} [options]\n"

	printf "\n  ${BLDGRN}Help:${TXTRST}\n"
	printf "    -h, --help       ${TXTLAG}Display help and exit.\n\n"

	printf "  ${BLDGRN}Create sql dump:${TXTRST}\n"
	printf "    -d, --database   ${TXTLAG}database to dump\n\n"

	printf "User and password for mysql access are read from ${CREDENTIAL_FILE}\n\n"

	fn_exit_with_status 0
} # >>>

function fn_get_credential() { # <<<
	if [ ! -f "${CREDENTIAL_FILE}" ] || [ ! -r "${CREDENTIAL_FILE}" ]; then
		fn_exit_with_error 'credential file unreadable or irregular'
	fi

	local -r perms=$(find "${CREDENTIAL_FILE}" -prune -printf '%M\n')
	if [ "${perms:(-3)}" != '---' ]; then
		fn_print_error_msg "unsafe credential file permissions : ${perms}"
		fn_exit_with_error 'credential file should only be readable by owner or group'
	fi

	local c=0
	while read line; do
		# skip comments
		if [ "${line:0:1}" = '#' ]; then
			continue
		fi

		# skip empty lines
		if [ ${#line} -eq 0 ]; then
			continue
		fi

		((c++))
		case ${c} in
			1)
				declare -gr sql_user="${line}"
			;;
			2)
				declare -gr sql_password="${line}"
			;;
			*) return ;;
		esac
	done < "${CREDENTIAL_FILE}"
} # >>>

function fn_warn_on_wrong_ret() { # <<<
	local -ir ret=$1
	shift
	if [ $ret -ne 0 ]; then
		fn_print_warn_msg "$@"
	fi
} # >>>

function fn_do_db_dump() { # <<<
	local -r TMPDIR=$(mktemp -d)
	local -r OUTFILE="${TMPDIR}/${sql_database}-$(date --rfc-3339=date).sql.gz"

	fn_print_status_msg "doing dump for ${sql_database} database"

	fn_log "running command : mysqldump --user=*** --password=*** ${sql_database} | gzip > \"${OUTFILE}\""
	fn_run_command "mysqldump --user=${sql_user} --password=${sql_password} ${sql_database} | gzip > \"${OUTFILE}\""
	
	local -ir ret=$?
	if [ $ret -ne 0 ]; then
		fn_exit_with_error "mysqldump failure, return status : $ret"
	fi

	fn_log_and_run_command "cp \"${OUTFILE}\" \"${ROOT_BACKUP_DIR}/${sql_database}/\""
	fn_warn_on_wrong_ret $? "copying file failed with status : $?"

	fn_print_status_msg "cleaning temp directory"

	fn_log_and_run_command "rm \"${OUTFILE}\""
	fn_warn_on_wrong_ret $? "removing dump file failed with status : $?"

	fn_log_and_run_command "rmdir \"${TMPDIR}\""
	fn_warn_on_wrong_ret $? "removing TMPDIR failed with status : $?"
} # >>>

function fn_remove_oldest_archives() { # <<<
	cd "${ROOT_BACKUP_DIR}/${sql_database}/" || fn_exit_with_error "change directory failure !"

	local -a listing=( "${sql_database}"-*.sql.gz )
	if [ "${listing[0]}" == "${sql_database}-*.tar.gz" ]; then
		unset -v listing
	fi

	local -i cnt=0
	local -i j=${#listing[@]}
	local -i ret=255

	while [ $j -gt 0 ]; do

		((j--))
		((cnt++))

		if [ ${cnt} -le ${MAX_FILES} ]; then
			continue
		fi

		fn_log_and_run_command "rm \"${listing[$j]}\""

		ret=$?
		if [ $ret -ne 0 ]; then
			fn_print_warn_msg "removing ${listing[$j]} failed with status : $ret"
		else
			fn_print_status_msg "\t[ removed ] ${listing[$j]}"
		fi
	done
} # >>>

### --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

fn_option_enabled 'help' && fn_display_help

declare -gr sql_database=$(fn_option_value 'database')

if [ "${sql_database}" == 'off' ]; then
	fn_exit_with_error 'You should set the db you want to dump with the --database option.'
fi

fn_get_credential
unset -f fn_get_credential

fn_do_db_dump
unset -f fn_do_db_dump

fn_remove_oldest_archives

# vim: set foldmethod=marker foldmarker=<<<,>>> foldlevel=0:
