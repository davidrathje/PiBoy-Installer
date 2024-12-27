#!/bin/bash
# Multi Switch Shutdown
# based on ES shutdown codes posted by @cyperghost and @meleu
# v0.05 Initial version here in this repo Jan.2018 // cyperghost
# v0.07 added kill -9 switch to get rid off all emulators // julenvitoria
# v0.10 version for NESPi case // Yahmez, Semper-5
# v0.20 Added possibilty for regular shutoff (commented now!)
# v0.30 Added commandline parameters uncommented device shutdowns
# v0.32 Added privileges check and packages check
# v0.41 Added NESPi+ safe shutdown, corrected GPIO numbering
# v0.42 Added NESPi+ fan control shutoff // thx cloudlink & gollumer
# v0.50 Added support for generic Button connected to any GPIO
# v0.51 NESPi+ fan control is 100% working - place a script to systemd service like Pimoroni OnOffShim
# v0.70 Parameter control, added extended help pages
# v0.75 Parameter --CLOSEEMU is called --ES-CLOSEEMU (both can be used for backward compatibility!)
# v0.80 Introduced --ES-SYSTEMD parameter, now the ES gracefully shutdown service by @meleu can be used
# v0.85 Code cleanup, added watchdog to kill only persistent emulators with sig -9, added more helppages

# V0.90 Modified by NScherdin for use with Piboy OSD

# ---------------------------------------------------------------------------------------------
# --------------------------------- P I D   D E T E C T I O N ---------------------------------
# ---------------------------------------------------------------------------------------------

# This function is called still all childPIDs are found
function get_childpids() {
    local CPIDS="$(pgrep -P $1)"
    for cpid in $CPIDS; do
        pidarray+=($cpid)
        get_childpids $CPIDS
    done
}

# Abolish sleep timer! This one is much better!
# I added watchdog to kill emu-processes with sig 9 level after 2.0s
# If emulator PID ist active after 5.0s, return to call
# I will prevent ES from being termed with level 9 for sake of safe shutdown
function wait_forpid() {
    local PID=$1
    [[ -z $PID ]] && return 1

    local RC_PID=$(check_emurun)
    local watchdog=0

    while [[ -e /proc/$PID ]]; do
        sleep 0.10
        watchdog=$((watchdog+1))
        [[ $watchdog -eq 20 ]] && [[ $RC_PID -gt 0 ]] && kill -9 $PID
        [[ $watchdog -eq 50 ]] && [[ $RC_PID -gt 0 ]] && return
    done
}

# This will reverse ${pidarray} and close all emulators
# This function needs a valid pidarray
function close_emulators() {
    for ((z=${#pidarray[*]}-1; z>-1; z--)); do
        kill ${pidarray[z]}
        wait_forpid ${pidarray[z]}
    done
    unset pidarray
}

# Emulator currently running?
# If yes return PID from runcommand.sh
# due caller funtion
function check_emurun() {
    local RC_PID="$(pgrep -f -n runcommand.sh)"
    echo $RC_PID
}

# Emulationstation currently running?
# If yes return PID from ES binary
# due caller funtion
function check_esrun() {
    local ES_PID="$(pgrep -f "/opt/retropie/supplementary/.*/emulationstation([^.]|$)")"
    echo $ES_PID
}

# ---------------------------------------------------------------------------------------------
# ------------------------------------ E S - A C T I O N S ------------------------------------
# ---------------------------------------------------------------------------------------------

# Helppage

function help--ES-SYSTEMCALLS () {

    echo -e "Multi Switch ES-Commands: Detailed Help\n"
    echo "--ES-PID:      This parameter obtains the Process ID of the running ES binary."
    echo "               If running ES instance isn't found, then 0 is returned."
    echo "               You may directly use this ID to quit ES's running instance!"
    echo "--RC-PID:      This parameter obtains the PID of runcommand.sh only!"
    echo "               You may find this usefull to detect if emulators are running."
    echo
    echo "--ES-CLOSEEMU: This parameter tries to close all running emulators. The code"
    echo "               is trying to determinine all child PIDs of runcommand.sh"
    echo "--ES-SYSTEMD:  This is special. It will just terminate ES binary and ES will not"
    echo "               initiate any further system actions like shutdown or reboots!"
    echo "               This is a hook to use with ES-gracfully-shutdown service by meleu"
    echo
    echo "--ES-RESTART:  This just restarts ES-binary and keeps Multi Switch active in BG"
    echo "--ES-REBOOT:   This reboots the whole system, this is initiated by ES itself!"
    echo "--ES-POWEROFF: This shutdowns the system, also initiated by ES itself!"
    echo
    echo "All this commands can be used to control the behaviour of EmulationStation with"
    echo "external written programms. Multi Switch just provides a kind of interface for"
    echo "simple control. So you are not stick to bash, feel free to take python!"
    echo "I made a quick coding example to read PIDs of ES. Please respect my work!"
    echo "It can be found here: https://retropie.org.uk/forum/topic/17506"

}

# This function can be called with several parameters
# ES itself evaluates entries in /tmp directory
# es-shutdown, will close ES and force an poweroff
# es-sysrestart, will close ES and force an reboot
# es-restart, will close ES and restart it

function es_action() {

    local CASE_SEL="$1"
    case "$CASE_SEL" in

        "--ES-CLOSEEMU")
            # Closes running Emulators (if available)
            RC_PID=$(check_emurun)
            if [[ -n $RC_PID ]]; then
                get_childpids $RC_PID
                close_emulators
                wait_forpid $RC_PID
            fi
        ;;

        "--ES-REBOOT")
            # Initiate system reboot and give control back to ES
            ES_PID=$(check_esrun)
            if [[ -n $ES_PID ]]; then
                touch /tmp/es-sysrestart
                chown pi:pi /tmp/es-sysrestart
                kill $ES_PID
                wait_forpid $ES_PID
                exit
            fi
        ;;

        "--ES-POWEROFF")
            # Initiate system shutdown and give control back to ES
            ES_PID=$(check_esrun)
            if [[ -n $ES_PID ]]; then
                touch /tmp/es-shutdown
                chown pi:pi /tmp/es-shutdown
                kill $ES_PID
                wait_forpid $ES_PID
                exit
            fi
        ;;

        "--ES-RESTART")
            # Initiate restart of ES
            ES_PID=$(check_esrun)
            if [[ -n $ES_PID ]]; then
                touch /tmp/es-restart
                chown pi:pi /tmp/es-restart
                kill $ES_PID
                wait_forpid $ES_PID
            fi
        ;;

        "--ES-SYSTEMD")
            # Just terminate ES binary and let other services do their job
            ES_PID=$(check_esrun)
            if [[ -n $ES_PID ]]; then
                kill $ES_PID
                wait_forpid $ES_PID
                exit
            fi
        ;;

        *)
            echo "Please parse argument to function es_action() - Error!" >&2
        ;;

    esac

}

# ---------------------------------------------------------------------------------------------
# ------------------------------------------ M A I N ------------------------------------------
# ---------------------------------------------------------------------------------------------

# -------------------------------- M A I N - F U N C T I O N ----------------------------------

# Parameter processing
# only integers from 0-99 are valid!
# Unvalid entries are assigned as -1
function cli_parameter() {
    unset call
    local PARAMETER=$@
    for i in ${PARAMETER[@]}; do
        value="${CLI#*$i}"
        [[ $value != $PARAMETER ]] && value="${value%% *}" || value="-1"
        [[ $value =~ ^[0-9]{1,2}$ ]] || value="-1"
        call+=("$value")
    done
}

# -------------------------------- M A I N - P R O G R A M M ----------------------------------

CASE_SEL="${1^^}"
[[ ${2^^} == "HELP" ]] && HELP_ITEM="$CASE_SEL" && CASE_SEL="help"
shift
CLI="${*,,}"

case "$CASE_SEL" in

    "--ES-PID")
        # Display ES PID to stdout
        ES_PID=$(check_esrun)
        [[ -n $ES_PID ]] && echo $ES_PID || echo 0
    ;;

    "--RC-PID")
        # Display runcommand.sh PID to stdout
        # This helps to detect emulator is running or not
        RC_PID=$(check_emurun)
        [[ -n $RC_PID ]] && echo $RC_PID || echo 0
    ;;

    "--ES-POWEROFF")
        # Closes running Emulators (if available)
        # Closes ES
        # Perform poweroff
	wall "Closing Emulators"
        es_action --ES-CLOSEEMU
	wall "Closing Emulation Station"
        es_action --ES-POWEROFF
        # If ES isn't running use regular shutoff
	wall "Shutting down  now!!!"
        sudo shutdown now #poweroff
    ;;

    "--ES-RESTART")
        # Closes running Emulators (if available)
        # Closes ES
        # Perform restart of ES only
        es_action --ES-CLOSEEMU
        es_action --ES-RESTART
    ;;

    "--ES-REBOOT")
        # Closes running Emulators (if available)
        # Closes ES
        # Perform system reboot
        es_action --ES-CLOSEEMU
        es_action --ES-REBOOT
    ;;

    "--SYSTEMD"|"--ES-SYSTEMD")
        # Closes running Emulators (if available)
        # Closes ES
        # Wait for service to finish
        es_action --ES-CLOSEEMU
        es_action --ES-SYSTEMD
    ;;

    "--CLOSEEMU"|"--ES-CLOSEEMU")
        # Only closes running emulators
        es_action --ES-CLOSEEMU
    ;;

    "help")
        # Callfunction with name help--DEVICE, help--MAUSBERRY for ex.
        # This call suspresses errors and redirects stderr to /dev/null
        [[ -z ${HELP_ITEM%--ES-*} || $HELP_ITEM == "--RC-PID" ]] && HELP_ITEM="--ES-SYSTEMCALLS"
        help$HELP_ITEM 2>/dev/null
        exit 1
    ;;

     "-H"|"--HELP")
        echo "Help Screen:"
        echo -e "\nSystemcommands:"
        echo "--es-pid        Shows PID of ES, if ES is not found it outputs 0"
        echo "--rc-pid        Shows PID of runcommand.sh, if not found it outputs 0"
        echo "--es-closeemu   Tries to shutdown emulators with cyperghosts method"
        echo "--es-systemd    This can invoke the shutdown service by meleu"
        echo "--es-poweroff   Shutdown emulators (if running), Closes ES, performs poweroff"
        echo "--es-reboot     Shutdown emulators, Closes ES, performs system reboot"
        echo "--es-restart    Shutdown emulators (if running), Restart ES"
        echo -e "\nHints:"
        echo "For detailed description of each command use: --command help"
        echo "Please visit: https://retropie.org.uk/forum/ for questions // cyperghost 2018"
    ;;

    *)
        echo "--COMMAND help for detailed help pages!"
        echo "--help or -h for overview of options available!"
    ;;

esac
