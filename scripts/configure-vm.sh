#!/bin/bash
# shellcheck disable=SC2034,SC2148
#------------------------------------------------------------------------
# ${SELF} (${SELF_VERSION}) - Display a message on standard output
# Copyright © 2014 Pôle de compétences EOLE <eole@ac-dijon.fr>
#
# License CeCILL:
#  * in french: http://www.cecill.info/licences/Licence_CeCILL_V2-fr.html
#  * in english http://www.cecill.info/licences/Licence_CeCILL_V2-en.html

#------------------------------------------------------------------------
# Changes:
#    1.0.1  GG: ajout 'instance' + template
#    1.0.0  GG: skelectorize config-vm.sh
#    0.0.4  Add log utilities with a dedicated developper documentation
#    0.0.3  Add “--sources” option to write “${SELF}” code on standard output
#    0.0.2  Take care of DEBUG=yes environment variable
#    0.0.1  Initial release

#------------------------------------------------------------------------
# Usage: ${SELF}
#
# Configure la VM sans interaction 
#
# Options:
# --------
#
#     -C, --configuration <repertoire_conf>
#                         Set the configuration to be used
#                         Default: “default"
#     -M, --methode <m>   Set the methode to be used
#                         Default: “minimale"
#                         Value in : "minimale"     : set default ip, gw, route, inject ssh
#                                    "freshinstall" : sans conf
#                                    "daily"        : sans conf
#                                    "majauto"      : only monitor MajAuto with parameters from context
#                                    "updateDaily"  : do MajAuto Stable + MajAuto with parameters from context + GenConteneur 
#                                    "configeol"    : only copy config.eol from configuration to /etc/eole
#                                    "instance"     : copy config.eol and "instance"
#                                    "zephir"       : get configuration from zephir with id = configuration
#                                    "getbackup"    : récupere la sauvegarde dans /mnt/sauvegarde depuis le partage /mnt/eole-ci-tests   
#                                    "restauration" : execute restore-depuis-configuration with configuration "configuration" in "template"   
#                                    "bacula"       : do bacularestore.py
#     -T, --template <m>  Set the template to be used
#                         Default: extract from VM Context
#                         Sample: aca.sphynx23a
#     -d, --debug         Enable debug messages
#     -h, --help          Show this message
#     -v, --version       Display version and copyright information
#     -c, --copyright     Display copyright information
#     -l, --licence       Display licence information
#         --changes       Display ChangeLog information
#     -s, --sources       Output software sources on standard output.
#
# Variables Environnement:
# -----------------------
# DEBUG=true|all  : active debug
# LOG_FILE=<file> : envoie le log dans un fichier 
#
# Mandatory dependencies:
# -----------------------
# * “sh” like shell
# * “echo” with “-e” option
# * perl
#
# Optional dependencies:
# ----------------------
# None
#
# Bugs:
# ----
# Report bug to Équipe EOLE <eole@ac-dijon.fr>
# bugtracker: http://dev-eole.ac-dijon.fr/projects/<EOLE-SKELETOR>/issues

#------------------------------------------------------------------------
# Debug, first thing to do if something goes wrong, even in utilities
#
# “${DEBUG}” can be:
# - “all” to set “-x” option of the shell
# - “true” to enable the “debug()” function, set by “--debug” option
#set -e en commentaire car fait tout planter !!

if [ "${DEBUG}" = 'all' ]
then
    set -x
fi

#------------------------------------------------------------------------
# Utilities for developpers:
#
# log ($@): write all parameters on standard output and call “flog()” to
#           write them in a file named “${LOG_FILE}” if it's:
#           - defined
#           - not a symlink
#           - a file or a named pipe or a socket
#           - writable or its parent directory is writable to create
#             a regular file.
#
# warn($@): call “log()” with all parameters, output of log() is
#           redirected to standard error.
#
# die($@): call “warn()” with all parameters, exit with code stored in
#          “${EXIT_CODE}” or “1” if it does not exit.
#
# debug($@): call “warn()” with all parameters if “${DEBUG}" is
#            “true”, the message is prefixed by the script name stored
#            in “${SELF}”
#
# flog ($@): write all parameters prefixed by current date and time
#            in a file named “${LOG_FILE}" if the variable is not empty.
#            The caller is responsible of the writable check of “${LOG_FILE}”.

# Take care of “-e” option to echo
if type shopt >/dev/null
then
    ECHO="echo"
else
    ECHO=/bin/echo
fi

## Logger functions
# Check if “log()” could write to “${LOG_FILE}”
log_writable() {
    # First: check that filename is defined and not a symlink
    # Second: check that filename is a file, a named pipe or a socket
    # Thirt: if filename is writable or if its parent directory is writable
    local D
    D=$(dirname "${1}")
    # shellcheck disable=SC2166
    [ -n "${1}" -a ! -L "${1}" ] && [ -f "${1}" -o -p "${1}" -o -S "${1}" ] && [ -w "${1}" -o -w "$D" ]
}

flog() { 
    [ -z "${LOG_FILE}" ] || ${ECHO} -e "$(date "+%Y-%m-%d %H:%M:%S"): $*" >> "${LOG_FILE}"; 
}
log() {
    ${ECHO} -e "$@"; 
    if log_writable "${LOG_FILE}" 
    then
        flog "$*" 
    else
        true
    fi
}
warn() { 
    log "$@" >&2; 
}

debug() { 
    if [ "${DEBUG}" = all ] || [ "${DEBUG}" = true ] 
    then
        warn "${SELF}: $*" 
    else
        true;
    fi 
}
die() { 
    warn "$@"; 
    exit "${EXIT_CODE:-1}"; 
}

## Common option functions
# Display list of changes
changes(){
    ${ECHO} -e "${SELF}\n"
    perl -lne "s<\\$\\{([^\\}]+)\\}><\$ENV{\$1}>gxms;
        print substr(\$_, 2) if (/^# Changes/ .. /^\$/) =~ /^\\d+\$/" < "${0}"
}

# Set SELF_VERSION variable
self_version() {
    [ -z "${SELF_VERSION}" ] || return
    SELF_VERSION=$(changes 2>&1 \
        | perl -lane 'if (m/^\s+\d+(?:\.\d+)*/) {print $F[0]; exit}')
    export SELF_VERSION
}

# Display usage
usage() {
    self_version
    perl -lne "s<\\$\\{([^\\}]+)\\}><\$ENV{\$1}>gxms;
        print substr(\$_, 2) if (/^# Usage/ .. /^\$/) =~ /^\\d+\$/" < "${0}"
}

# Display licence
licence() {
    self_version
    perl -lne "s<\\$\\{([^\\}]+)\\}><\$ENV{\$1}>gxms;
        print substr(\$_, 2) if (/^# ${SELF} \(${SELF_VERSION}\)/ .. /^\$/) =~ /^\\d+\$/" < "${0}"
}

# Display sources making the software AGPL-3 ready
sources() {
    cat < "${0}"
}

############################################################################################
#
# Start program
#
############################################################################################
#------------------------------------------------------------------------
# Global variables:
#
# Use “export” to make them available to subprocesses
#
# Empty log file by default
LOG_FILE=

# Used by common options functions, do not unexport or they fail
SELF_LINK=$(readlink -e "${0}")
SELF=$(basename "$SELF_LINK")
export SELF

# Set by function, here for reference
SELF_VERSION=
export SELF_VERSION

# Program specific variables, export to use it in “usage()”
export CONFIGURATION=default
export CONF_METHODE=minimale

# shellcheck disable=1091
source /root/getVMContext.sh

#------------------------------------------------------------------------
# Options
TEMP=$(getopt -o M:C:T:dhvcls --long configuration:,methode:,template:,debug,help,version,copyright,licence,changes,sources -- "$@")

test $? = 0 || exit 1
eval set -- "${TEMP}"

while true
do
    case "${1}" in
        # Default options for utilities
        -h|--help)
            usage
            exit 0
            ;;
        -v|--version)
            licence | head -n 2
            exit 0
            ;;
        -c|--copyright)
            licence | tail -n +2
            exit 0
            ;;
        -l|--licence)
            licence
            exit 0
            ;;
        --changes)
            changes
            exit 0
            ;;
        -s|--sources)
            sources
            exit 0
            ;;

        -d|--debug)
            DEBUG=true
            shift
            ;;

        # Program options
        -C|--configuration)
            [ -n "${2}" ] || die "Configuration must not be empty"
            export CONFIGURATION="${2}"
            shift 2
            ;;

        -M|--methode)
            [ -n "${2}" ] || die "Methode must not be empty"
            export CONF_METHODE="${2}"
            shift 2
            ;;

        -T|--template)
            [ -n "${2}" ] || die "Template must not be empty"
            export VM_MACHINE="${2}"
            #
            # ATTENTION : si Template définie , alors tous les parametres n'existe pas forcement ....
            #
            shift 2
            ;;

        # End of options
        --)
            shift
            break
            ;;
        *)
            die "Error: unknown argument '${1}'"
            ;;
    esac
done

if [ -z "$VM_MACHINE" ]
then
    ciPrintMsg "configure_vm.sh: VM_MACHINE non definie, stop"
    exit 1
fi

if [ "$CONF_METHODE" == "minimale" ]
then
    # impose la Configuration !
    CONFIGURATION=minimale
fi

ciPrintMsg "configuration='$CONFIGURATION' methode='$CONF_METHODE' template='$VM_MACHINE' versionmajeur='$VM_VERSIONMAJEUR'"

if [ "$VM_EST_MACHINE_EOLE" = oui ] 
then
    ciConfigurationEole "$CONF_METHODE" "$CONFIGURATION" 
else
    ciPrintMsg "Machine non EOLE ==> uniquement minimale"    
    ciConfigurationMinimale
fi

exit 0
