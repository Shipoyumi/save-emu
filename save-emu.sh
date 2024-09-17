#!/bin/bash

#####################################################################
#                                                                   #
#  ░██████╗░█████╗░██╗░░░██╗███████╗  ███████╗███╗░░░███╗██╗░░░██╗  #
#  ██╔════╝██╔══██╗██║░░░██║██╔════╝  ██╔════╝████╗░████║██║░░░██║  #
#  ╚█████╗░███████║╚██╗░██╔╝█████╗░░  █████╗░░██╔████╔██║██║░░░██║  #
#  ░╚═══██╗██╔══██║░╚████╔╝░██╔══╝░░  ██╔══╝░░██║╚██╔╝██║██║░░░██║  #
#  ██████╔╝██║░░██║░░╚██╔╝░░███████╗  ███████╗██║░╚═╝░██║╚██████╔╝  #
#  ╚═════╝░╚═╝░░╚═╝░░░╚═╝░░░╚══════╝  ╚══════╝╚═╝░░░░░╚═╝░╚═════╝░  #
#                                                                   #
#####################################################################
#                                                                   #
#         Date: 06.09.2024 | Author: Yuminda | Version: 0.7.1       #
#                                                                   #
#####################################################################

# NOTE: Please always use absolute paths in this script.            #
# NOTE: Please always use '<space>###' behind every user variable,  #
#       because they are used by the change_var_value function.     #

# Comment out for debug information:
#set -x

WD="$PWD"; cd ~; HOME_DIR="$PWD/"; cd ${WD} #Get home directory automatically

# User variables ----------------------------------- User variables #
DEACTIVATE_UPLOAD_BY_DEFAULT="false" ### If u never want to upload/cloud-save your savegames change to true
DEACTIVATE_DOWNLOAD_BY_DEFAULT="false" ### If u never want to download/cloud-save your savegames change to true

REMOTE_SSH="user@remote_ip_address:/backup/" ### e.g. "user@REMOTEIP:/backup/"
SSH_KEY_PATH="~/.ssh/key" ### e.g. "~/.ssh/mykey"

TAR_COMPRESSION="z" ### "z" for gzip | "j" for bzip2 | "J" for xz

MAX_NUMBER_OF_ADDITIONAL_BACKUPS="1" ### 0 equals no additional backup, 1 equals 1 backup (aka. hold 1 old offline backup), etc.

LOCAL_SAVEGAME_DIRECTORY="${HOME_DIR}EMU_SAVEGAMES/" ### Local savegame directory for compressed savegame files and synchronization.txt | Default: "~/EMU_SAVEGAMES/"

PLATFORM="Laptop" ### For the synchronization file (.info), e.g. "Laptop" or "PC" or your hostname

# Change the associative array as u wish (aka. turn off the emulators you don't use)
declare -A EMULATORS
EMULATORS[pcsx2]="true" ###
EMULATORS[ppsspp]="true" ###
EMULATORS[dolphin_gc]="true" ###
EMULATORS[dolphin_wii]="true" ###
EMULATORS[citra]="true" ###

declare -A SAVEGAME_PATH
SAVEGAME_PATH[pcsx2]="${HOME_DIR}.config/PCSX2/memcards/" ### MEMCARD-DIRECTORY
SAVEGAME_PATH[ppsspp]="${HOME_DIR}.config/ppsspp/PSP/SAVEDATA/" ### MEMCARD/SAVEDATA-DIRECTORY
SAVEGAME_PATH[dolphin_gc]="${HOME_DIR}.local/share/dolphin-emu/GC/" ### GAMECUBE-DIRECTORY
SAVEGAME_PATH[dolphin_wii]="${HOME_DIR}.local/share/dolphin-emu/Wii/title/" ### WII-DIRECTORY
SAVEGAME_PATH[citra]="${HOME_DIR}.local/share/citra-emu/sdmc/" ### CITRA-MICROSD-DIRECTORY, but it also contains installed games!

# Script variables ------------------------------- Script variables #
VERSION="0.7.1"
DATE="2024-09-06"
ALL_EMULATORS_PURE=("PCSX2" "PPSSPP" "Dolphin_GC" "Dolphin_Wii" "Citra") #List of all emulators
HELP_VERSION_LINE="${C_NORMAL}Author: Yuminda | Version: ${VERSION}"
NO_CLOUD=false
EXPORT=false
IMPORT=false
FILE_ENDING=""
INFO_PATH="${LOCAL_SAVEGAME_DIRECTORY}.info"
SYNCHRONIZATION_PATH="${LOCAL_SAVEGAME_DIRECTORY}.synchronization"
declare -a OPTION #Array for knowing
declare -A ALL_EMULATORS #all emulators in lower case
declare -A ALL_EMULATORS_DISPLAY #all emulators in user letter cases (like PURE, but associative)
declare -A ALL_EMULATORS_CAPS #@ .info file
declare -A ALL_EMULATORS_CAPS_S #@ .synchronization file
declare -A ACTIVE_EMULATORS #all active emulators
for i in ${ALL_EMULATORS_PURE[@]}; do
	LOWER_CASE_EMU="$(echo ${i} | tr '[:upper:]' '[:lower:]')"
	ALL_EMULATORS[${LOWER_CASE_EMU}]="${LOWER_CASE_EMU}"
	ALL_EMULATORS_DISPLAY[${LOWER_CASE_EMU}]="$(echo ${i})"
	ALL_EMULATORS_CAPS[${LOWER_CASE_EMU}]="$(echo ${ALL_EMULATORS[${LOWER_CASE_EMU}]} | tr '[:lower:]' '[:upper:]')"
	ALL_EMULATORS_CAPS_S[${LOWER_CASE_EMU}]="S_$(echo ${ALL_EMULATORS[${LOWER_CASE_EMU}]} | tr '[:lower:]' '[:upper:]')"
	if ${EMULATORS[${LOWER_CASE_EMU}]}; then
		ACTIVE_EMULATORS[${LOWER_CASE_EMU}]="${LOWER_CASE_EMU}"
	fi
done
declare -A STATUS_COLOR_ARRAY
STATUS=""
MARK=""
IMPORT_NEEDED=false
EXPORT_NEEDED=false
INFO_ARRAY=("Date" "Platform" "Filename" "Size")
VAR_ARRAY=("DEACTIVATE_UPLOAD_BY_DEFAULT" "DEACTIVATE_DOWNLOAD_BY_DEFAULT" "REMOTE_SSH" "SSH_KEY_PATH" "TAR_COMPRESSION" "MAX_NUMBER_OF_ADDITIONAL_BACKUPS" "LOCAL_SAVEGAME_DIRECTORY" "PLATFORM" "EMULATORS\[pcsx2\]" "EMULATORS\[ppsspp\]" "EMULATORS\[dolphin_gc\]" "EMULATORS\[dolphin_wii\]" "EMULATORS\[citra\]" "SAVEGAME_PATH\[pcsx2\]" "SAVEGAME_PATH\[ppsspp\]" "SAVEGAME_PATH\[dolphin_gc\]" "SAVEGAME_PATH\[dolphin_wii\]" "SAVEGAME_PATH\[citra\]")
VAR_STRING=""
VAR_NUMBER=-1
NEW_VAR_VALUE=""

# Colors --------------------------------------------------- Colors #
RED="\e[38;5;196m"
GREEN="\e[38;5;190m"
YELLOW="\e[38;5;166m"
GRAY='\e[38;5;245m'
MAGENTA='\e[38;5;162m'
ROSE='\e[38;5;211m'
CYAN='\e[38;5;50m'
WHITE='\e[38;5;15m'
ENDCOLOR='\e[38;5;15m'

# Color groups --------------------------------------- Color groups #
C_SUCCESS="${GREEN}"
C_ERROR="${RED}"
C_HEADLINES="${GRAY}"
C_HIGHLIGHTS="${CYAN}"
C_SHINY="${ROSE}"
C_NORMAL="${WHITE}"

# Symbols ------------------------------------------------- Symbols #
HEART=$(echo -e '\u2665')
CHECKMARK=$(echo -e '\u2611')
XMARK=$(echo -e '\u2612')
CAT1=$(echo -e '\u269E')
CAT2=$(echo -e '\u269F')
CAT="${CAT1}°^°${CAT2}"
SBRACE1=$(echo -e '\u300C')
SBRACE2=$(echo -e '\u300D')
FBRACE1=$(echo -e '\u3018')
FBRACE2=$(echo -e '\u3019')
JPTIME=$(echo -e '\u6642\u9593')

# Functions --------------------------------------------- Functions #
# This function is used by the show_help function to print
function print_help_version_line {
	local width=57 # Line width without the border blocks
	local x2=${#HELP_VERSION_LINE}+2
	local x1=(${width}-${x2})/2
	local x3=${width}-${x1}-${x2}

	# Actually print the version line as follows
	echo -en "${C_HEADLINES}█${C_NORMAL}"
	for ((i=0; i<${x1}; i++)); do echo -en " "; done
	echo -en " ${HELP_VERSION_LINE} "
	for ((i=0; i<${x3}; i++)); do echo -en " "; done
	echo -e "${C_HEADLINES}█${C_NORMAL}"
}

# This function only prints the help page
function show_help {
	echo -e "${C_HEADLINES}████████████████████ ${C_HIGHLIGHTS}save-emu.sh help page${C_HEADLINES} ████████████████████
${C_HEADLINES}█                                                             █
${C_HEADLINES}█---------------------- [ ${C_HIGHLIGHTS}Information${C_HEADLINES} ] ----------------------█
${C_HEADLINES}█                                                             █"
print_help_version_line
echo -e "${C_HEADLINES}█                                                             █
${C_HEADLINES}█  ${C_NORMAL}A bash script for a quick and easy creation of compressed  ${C_HEADLINES}█
${C_HEADLINES}█  ${C_NORMAL}savegames for emulators on linux with a cloud-synchro-     ${C_HEADLINES}█
${C_HEADLINES}█  ${C_NORMAL}nization and restoring feature. (For multiple devices)     ${C_HEADLINES}█
${C_HEADLINES}█                                                             █
${C_HEADLINES}█  ${C_NORMAL}You may need to change the user variables on top of this   ${C_HEADLINES}█
${C_HEADLINES}█  ${C_NORMAL}script or by using the -/ and -! command options to your   ${C_HEADLINES}█
${C_HEADLINES}█  ${C_NORMAL}directories, etc. (And make this program executable)       ${C_HEADLINES}█
${C_HEADLINES}█                                                             █
${C_HEADLINES}█------------------------- [ ${C_HIGHLIGHTS}Usage${C_HEADLINES} ] -------------------------█
${C_HEADLINES}█                                                             █
${C_HEADLINES}█  ${C_SHINY}Command structure:                                         ${C_HEADLINES}█
${C_HEADLINES}█                                                             █
${C_HEADLINES}█      ${C_NORMAL}./save-emu.sh [export|import] [option]                 ${C_HEADLINES}█
${C_HEADLINES}█                                                             █
${C_HEADLINES}█      ${C_NORMAL}./save-emu.sh [export|import] [-n|--no] [option]       ${C_HEADLINES}█
${C_HEADLINES}█                                                             █
${C_HEADLINES}█      ${C_NORMAL}./save-emu.sh -! [var_number] [new_variable_value]     ${C_HEADLINES}█
${C_HEADLINES}█                                                             █
${C_HEADLINES}█  ${C_SHINY}The following options are available:                       ${C_HEADLINES}█
${C_HEADLINES}█                                                             █
${C_HEADLINES}█      ${C_NORMAL}-a|--all                save all savegames             ${C_HEADLINES}█
${C_HEADLINES}█                                                             █
${C_HEADLINES}█      ${C_NORMAL}-2|-ps2|--pcsx2         save all PCSX2 savegames       ${C_HEADLINES}█
${C_HEADLINES}█                                                             █
${C_HEADLINES}█      ${C_NORMAL}-p|-psp|--ppsspp        save all PPSSPP savegames      ${C_HEADLINES}█
${C_HEADLINES}█                                                             █
${C_HEADLINES}█      ${C_NORMAL}-d|--dolphin            save all Dolphin savegames     ${C_HEADLINES}█
${C_HEADLINES}█                                                             █
${C_HEADLINES}█      ${C_NORMAL}-g|--gamecube           save all D-Gamecube savegames  ${C_HEADLINES}█
${C_HEADLINES}█                                                             █
${C_HEADLINES}█      ${C_NORMAL}-w|--wii                save all D-Wii savegames       ${C_HEADLINES}█
${C_HEADLINES}█                                                             █
${C_HEADLINES}█      ${C_NORMAL}-c|-3ds|--citra         save all Citra savegames       ${C_HEADLINES}█
${C_HEADLINES}█                                                             █
${C_HEADLINES}█      ${C_NORMAL}-s|--status             show status                    ${C_HEADLINES}█
${C_HEADLINES}█                                                             █
${C_HEADLINES}█      ${C_NORMAL}-/|--path|--var         show (path) variables          ${C_HEADLINES}█
${C_HEADLINES}█                                                             █
${C_HEADLINES}█      ${C_NORMAL}-!|--change_var         change a (path) variable       ${C_HEADLINES}█
${C_HEADLINES}█                                                             █
${C_HEADLINES}█      ${C_NORMAL}-v|--version            show version                   ${C_HEADLINES}█
${C_HEADLINES}█                                                             █
${C_HEADLINES}█      ${C_NORMAL}-h|--help               show this help page            ${C_HEADLINES}█
${C_HEADLINES}█                                                             █
${C_HEADLINES}█  ${C_SHINY}Explanation of the other arguments:                        ${C_HEADLINES}█
${C_HEADLINES}█                                                             █
${C_HEADLINES}█      ${C_NORMAL}export                  export/save savegames          ${C_HEADLINES}█
${C_HEADLINES}█                                                             █
${C_HEADLINES}█      ${C_NORMAL}import                  import/restore savegames       ${C_HEADLINES}█
${C_HEADLINES}█                                                             █
${C_HEADLINES}█      ${C_NORMAL}-n|--no                 no online/cloud backup         ${C_HEADLINES}█
${C_HEADLINES}█                                                             █
${C_HEADLINES}███████████████████████████████████████████████████████████████${C_NORMAL}"
}

# Compare the dates of .synchronization and .info and change the STATUS VARIABLE:
# GREEN = .info is newer or up to date (equal) | RED = .synchronization is newer
function compare_info_dates {
	source ${INFO_PATH}
	source ${SYNCHRONIZATION_PATH}
	local current_emu="${ALL_EMULATORS_CAPS[${1}]}"
	local info_date_string="${current_emu}[Date]" #Reminder: with ! later
	local synchronization_date_string="S_${current_emu}[Date]"
	local info_date=$(echo "${!info_date_string}" | sed 's/\(...\)@.*/\1/') #e.g. 2023-10-28
	local info_time=$(echo "${!info_date_string}" | sed 's/.*@\(...\)/\1/') #e.g. 21:07
	local synchronization_date=$(echo "${!synchronization_date_string}" | sed 's/\(...\)@.*/\1/')
	local synchronization_time=$(echo "${!synchronization_date_string}" | sed 's/.*@\(...\)/\1/')
	if [[ ${info_date} == ${synchronization_date} ]]; then #Time comparison, same day
		if [[ ${info_time} < ${synchronization_time} ]]; then STATUS=${RED}; else STATUS=${GREEN}; fi
	elif [[ ${info_date} > ${synchronization_date} ]]; then #NEWER
		STATUS=${GREEN};
	else # ${info_date} < ${synchronization_date} #OLDER
		STATUS=${RED};
	fi
}

# Compare a specific emu between .info and .synchronization
# Parameter 1 is the emu in lower case letters
function compare_specific_emu_info_files {
	source ${INFO_PATH}
	source ${SYNCHRONIZATION_PATH}
	STATUS=${GREEN} #${GREEN} for savegames match .synchro, otherwise ${RED}
	local current_emu="${ALL_EMULATORS_CAPS[${1}]}"
	local current_entry=""
	local current_S_entry=""
	for y in ${INFO_ARRAY[@]}; do
		current_entry="${current_emu}[${y}]"
		current_S_entry="S_${current_emu}[${y}]"
		if [[ ${!current_entry} == ${!current_S_entry} ]]; then STATUS_COLOR_ARRAY[${y}]="${GREEN}"; else STATUS_COLOR_ARRAY[${y}]="${YELLOW}"; fi
	done
	compare_info_dates ${1} #Update STATUS variable
	if [ ${STATUS} == ${RED} ]; then MARK=${XMARK}; else MARK=${CHECKMARK}; fi
}

function create_empty_info_file {
	[[ $2 == "info" ]] && local which_path=${INFO_PATH} || local which_path=${SYNCHRONIZATION_PATH}
	echo -e "#!/bin/bash \n" > ${which_path}
	for i in ${ALL_EMULATORS_CAPS[@]}; do
		local current_emu="${1}${i}"
		local lower_case_emu=$(echo ${current_emu} | tr '[:upper:]' '[:lower:]')
		echo "declare -A ${current_emu}" >> ${which_path}
		echo "${current_emu}[Date]=" >> ${which_path}
		echo "${current_emu}[Platform]=" >> ${which_path}
		echo "${current_emu}[Filename]=" >> ${which_path}
		echo "${current_emu}[Size]=" >> ${which_path}
		echo "" >> ${which_path}
	done
}

# Parameter 1 is: Emulator in CAPSLOCK
# Get specific emu information from .synchronization and update it in .info or the other way
function import_specific_emu_in_file {
	echo -en "${1} "
	for i in ${INFO_ARRAY[@]}; do
		if [[ ${2} == "s2i" ]]; then sed -i "s/${1}\[${i}\]=.*$/${1}\[${i}\]=$(sed -n "s/S_${1}\[${i}\]=\(...\)/\1/p" ${SYNCHRONIZATION_PATH})/" ${INFO_PATH}; fi #.synchronization -> .info
		if [[ ${2} == "i2s" ]]; then sed -i "s/S_${1}\[${i}\]=.*$/S_${1}\[${i}\]=$(sed -n "s/${1}\[${i}\]=\(...\)/\1/p" ${INFO_PATH})/" ${SYNCHRONIZATION_PATH}; fi #.info -> .synchronization
	done
}

function export_specific_emu_in_file {
	if [[ ${2} == "i" ]]; then						#.info
		local emu=${ALL_EMULATORS_CAPS[${1}]}
		local which_path=${INFO_PATH}
	else											# .synchronization
		local emu=${ALL_EMULATORS_CAPS_S[${1}]}
		local which_path=${SYNCHRONIZATION_PATH}
	fi

	echo -en "${emu} "								# Echo current emu

	sed -i "s/${emu}\[Date\]=.*$/${emu}\[Date\]=$(date '+%Y-%m-%d')@$(date '+%H:%M')/" ${which_path}
	sed -i "s/${emu}\[Platform\]=.*$/${emu}\[Platform\]=${PLATFORM}/" ${which_path}
	sed -i "s/${emu}\[Filename\]=.*$/${emu}\[Filename\]=${1}${FILE_ENDING}/" ${which_path}
	sed -i "s/${emu}\[Size\]=.*$/${emu}\[Size\]=$(cd ${LOCAL_SAVEGAME_DIRECTORY}; ls -lh | grep "${1}${FILE_ENDING}" | sed -e 's/\s\{2,\}/ /' | cut -d " " -f 5)/" ${which_path}
}

# Checks if .info is empty. If empty, then create empty array definitions
function check_empty_info_file {
	[[ $(cat ${INFO_PATH}) == "" ]] && create_empty_info_file "" "info" #If .info is empty, create empty arrays
}

# Uploads .synchronization file ONLY
function upload_synchronization {
	echo -e "Uploading .synchronization file ... " && scp -i ${SSH_KEY_PATH} ${SYNCHRONIZATION_PATH} ${REMOTE_SSH} && echo -e "${GREEN}successful.${C_NORMAL}" || echo -e "${RED}failed.${C_NORMAL}"
}

# Downloads .synchronization file ONLY
function download_synchronization {
	echo -e "Downloading .synchronization file ... " && scp -i ${SSH_KEY_PATH} "${REMOTE_SSH}.synchronization" ${LOCAL_SAVEGAME_DIRECTORY} && echo -e "${GREEN}successful.${C_NORMAL}" || echo -e "${RED}failed.${C_NORMAL}"
}

# Uploads specific emu savegames AND .synchronization file
function upload_savegame {
	upload_synchronization
	source ${INFO_PATH}
	source ${SYNCHRONIZATION_PATH}
	echo -e "Uploading savegame file(s) ... "
	for w in ${OPTION[@]}; do
		local current_emu="${ALL_EMULATORS_CAPS[${w}]}"
		local emu_filename_string="${current_emu}[Filename]"
		scp -i ${SSH_KEY_PATH} "${LOCAL_SAVEGAME_DIRECTORY}${!emu_filename_string}" ${REMOTE_SSH} #Upload specific emu savegame file (archive)
	done
	echo -e "Done."
}

# Downloads specific emu savegames IF needed AND .synchronization + copy it to .info
function download_savegame {
	source ${INFO_PATH}
	source ${SYNCHRONIZATION_PATH}
	echo -e "Downloading savegame file ... "
	local current_emu="${ALL_EMULATORS_CAPS_S[${z}]}"
	local emu_filename_string="${current_emu}[Filename]"
	scp -i ${SSH_KEY_PATH} "${REMOTE_SSH}${!emu_filename_string}" ${LOCAL_SAVEGAME_DIRECTORY}; #Download specific emu savegame file (archive)
	echo -e "Done."
}

# This function allows the user to see the variables and their respective values easily without looking into the source code
function show_path_variables {
	BLOCK=${C_HEADLINES}█${C_HIGHLIGHTS}
	echo -e "${C_HEADLINES}██ ${C_HIGHLIGHTS}General option variables${C_HEADLINES} ███████████████
${BLOCK}
${BLOCK} [0]${C_NORMAL} DEACTIVATE_UPLOAD_BY_DEFAULT=${C_SHINY}${DEACTIVATE_UPLOAD_BY_DEFAULT}${C_HEADLINES} If u never want to upload/cloud-save your savegames change to true
${BLOCK} [1]${C_NORMAL} DEACTIVATE_DOWNLOAD_BY_DEFAULT=${C_SHINY}${DEACTIVATE_DOWNLOAD_BY_DEFAULT}${C_HEADLINES} If u never want to download/cloud-save your savegames change to true
${BLOCK}
${BLOCK} [2]${C_NORMAL} REMOTE_SSH=${C_SHINY}\"${REMOTE_SSH}\"${C_HEADLINES} e.g. \"user@REMOTEIP:/backup/\"
${BLOCK} [3]${C_NORMAL} SSH_KEY_PATH=${C_SHINY}\"${SSH_KEY_PATH}\"${C_HEADLINES} e.g. \"~/.ssh/mykey\"
${BLOCK}
${BLOCK} [4]${C_NORMAL} TAR_COMPRESSION=${C_SHINY}\"${TAR_COMPRESSION}\"${C_HEADLINES} \"z\" for gzip | \"j\" for bzip2 | \"J\" for xz
${BLOCK}
${BLOCK} [5]${C_NORMAL} MAX_NUMBER_OF_ADDITIONAL_BACKUPS=${C_SHINY}${MAX_NUMBER_OF_ADDITIONAL_BACKUPS}${C_HEADLINES} 0 equals no additional backup, 1 equals 1 backup (aka. hold 1 old offline backup), etc.
${BLOCK}
${BLOCK} [6]${C_NORMAL} LOCAL_SAVEGAME_DIRECTORY=${C_SHINY}\"${LOCAL_SAVEGAME_DIRECTORY}\"${C_HEADLINES} Local savegame directory for compressed savegame files and synchronization.txt | Default: \"~/EMU_SAVEGAMES/\"
${BLOCK}
${BLOCK} [7]${C_NORMAL} PLATFORM=${C_SHINY}\"${PLATFORM}\"${C_HEADLINES} For the synchronization file (.info), e.g. \"Laptop\" or \"PC\" or your hostname
${BLOCK}
${C_HEADLINES}██ ${C_HIGHLIGHTS}Active emulators${C_HEADLINES} ███████████████████████
${BLOCK}
${BLOCK} [8]${C_NORMAL}  EMULATORS[pcsx2]=${C_SHINY}${EMULATORS[pcsx2]}
${BLOCK} [9]${C_NORMAL}  EMULATORS[ppsspp]=${C_SHINY}${EMULATORS[ppsspp]}
${BLOCK} [10]${C_NORMAL} EMULATORS[dolphin_gc]=${C_SHINY}${EMULATORS[dolphin_gc]}
${BLOCK} [11]${C_NORMAL} EMULATORS[dolphin_wii]=${C_SHINY}${EMULATORS[dolphin_wii]}
${BLOCK} [12]${C_NORMAL} EMULATORS[citra]=${C_SHINY}${EMULATORS[citra]}
${BLOCK}
${C_HEADLINES}██ ${C_HIGHLIGHTS}Savegame path variables${C_HEADLINES} ████████████████
${BLOCK}
${BLOCK} [13]${C_NORMAL} SAVEGAME_PATH[pcsx2]=${C_SHINY}\"${SAVEGAME_PATH[pcsx2]}\"${C_HEADLINES} MEMCARD-DIRECTORY
${BLOCK} [14]${C_NORMAL} SAVEGAME_PATH[ppsspp]=${C_SHINY}\"${SAVEGAME_PATH[ppsspp]}\"${C_HEADLINES} MEMCARD/SAVEDATA-DIRECTORY
${BLOCK} [15]${C_NORMAL} SAVEGAME_PATH[dolphin_gc]=${C_SHINY}\"${SAVEGAME_PATH[dolphin_gc]}\"${C_HEADLINES} GAMECUBE-DIRECTORY
${BLOCK} [16]${C_NORMAL} SAVEGAME_PATH[dolphin_wii]=${C_SHINY}\"${SAVEGAME_PATH[dolphin_wii]}\"${C_HEADLINES} WII-DIRECTORY
${BLOCK} [17]${C_NORMAL} SAVEGAME_PATH[citra]=${C_SHINY}\"${SAVEGAME_PATH[citra]}\"${C_HEADLINES} CITRA-MICROSD-DIRECTORY, but it may also contain installed games!
${BLOCK}
${C_HEADLINES}███████████████████████████████████████████${C_NORMAL}"
}

# This function allows the user to change the values of variables easily without looking into the source code
function change_var_value {
	VAR_STRING=${VAR_ARRAY[${VAR_NUMBER}]}
	sed -i -e "s/^${VAR_STRING}=.* ###/${VAR_STRING}=\"${NEW_VAR_VALUE}\" ###/" ${WD}/save-emu.sh && echo -e "Changed the value of variable ${C_HIGHLIGHTS}${VAR_STRING}${C_NORMAL} to ${C_HIGHLIGHTS}${NEW_VAR_VALUE} ${C_SUCCESS}successfully${C_NORMAL}!" || echo -e "Changing the value of variable ${C_HIGHLIGHTS}${VAR_STRING}${C_NORMAL} to ${C_HIGHLIGHTS}${NEW_VAR_VALUE} ${C_ERROR}failed${C_NORMAL}!"
	exit 0
}

# This function prints the current status page
function show_status {
	source ${INFO_PATH}
	source ${SYNCHRONIZATION_PATH}
	echo -e "${C_HEADLINES}███████████████████ ${C_HIGHLIGHTS}save-emu.sh status page${C_HEADLINES} ████████████████████"
	echo -e "${C_HEADLINES}█                                                              █"
	printf "${C_HEADLINES}█${C_HIGHLIGHTS}   %-10s  %-21s  %-21s   ${C_HEADLINES}█\n" "Type" "Offline" "Online"
	printf "${C_HEADLINES}█   %-10s  %-21s  %-21s   █\n" " " "(Savegames: .info)" "(.synchronization)"
	echo -e "${C_HEADLINES}█                                                              █"
	for i in ${ACTIVE_EMULATORS[@]}; do
		local current_emu="${ALL_EMULATORS_CAPS[${i}]}"
		local str="${ALL_EMULATORS_DISPLAY[${i}]}"
		compare_specific_emu_info_files ${i}
		printf "${C_HEADLINES}█ ------------------- [${C_HIGHLIGHTS} %8s%-8s ${C_HEADLINES}] ----------------- ${STATUS}${MARK}${C_HEADLINES} █\n" `echo $str | cut -c 1-$((${#str}/2))` `echo $str | cut -c $((${#str}/2+1))-${#str}`
		echo -e "${C_HEADLINES}█                                                              █"
		for j in ${INFO_ARRAY[@]}; do
			local current_entry="${current_emu}[${j}]"
			local current_S_entry="S_${current_emu}[${j}]"
			[[ ${!current_entry} == "" ]] && printf "${C_HEADLINES}█${C_NORMAL}   %-10s  %-21s  %-21s   ${C_HEADLINES}█\n" ${j} " " ${!current_S_entry} || printf "${C_HEADLINES}█${C_NORMAL}   %-10s  ${STATUS_COLOR_ARRAY[${j}]}%-21s  %-21s${C_NORMAL}   ${C_HEADLINES}█\n" ${j} ${!current_entry} ${!current_S_entry}
		done
		echo -e "${C_HEADLINES}█                                                              █"
	done
	echo -e "${C_HEADLINES}████████████████████████████████████████████████████████████████"
}

# This function is EXPORT ONLY!
function export_info_file {
	for v in ${OPTION[@]}; do
		if [[ ${1} == "i" ]]; then export_specific_emu_in_file ${v} "i"; fi
		if [[ ${1} == "s" ]]; then export_specific_emu_in_file ${v} "s"; fi
	done
}

# This function is IMPORT ONLY!
function import_info_file {
	for v in ${OPTION[@]}; do
		import_specific_emu_in_file ${ALL_EMULATORS_CAPS[${v}]} "s2i"
	done
}

function backup_old_savegame {
	for (( i=1; i<=${MAX_NUMBER_OF_ADDITIONAL_BACKUPS}; i++ )); do
		let j=i-1
		# Check if file exists:
		if [[ -f "${LOCAL_SAVEGAME_DIRECTORY}$1${FILE_ENDING}" && ${i} == 1 ]]; then
			mv -v "${LOCAL_SAVEGAME_DIRECTORY}$1${FILE_ENDING}" "${LOCAL_SAVEGAME_DIRECTORY}$1_${i}${FILE_ENDING}"
		elif [[ -f "${LOCAL_SAVEGAME_DIRECTORY}$1_${j}${FILE_ENDING}" && ${i} > 1 ]]; then
			mv -v "${LOCAL_SAVEGAME_DIRECTORY}$1_${j}${FILE_ENDING}" "${LOCAL_SAVEGAME_DIRECTORY}$1_${i}${FILE_ENDING}"
		fi
	done
	echo -e "${C_HEADLINES}Info: Shifting done!${ENDCOLOR}"
}

function get_file_ending {
	[[ ${TAR_COMPRESSION} == "z" ]] && FILE_ENDING=".tar.gz"
	[[ ${TAR_COMPRESSION} == "j" ]] && FILE_ENDING=".tar.bz2"
	[[ ${TAR_COMPRESSION} == "J" ]] && FILE_ENDING=".tar.xz"
}

function exit_msg {
	echo -e "${C_ERROR}failed${C_NORMAL}!${ENDCOLOR}"
	echo -e "${C_ERROR}Process stopped, because an error occured! Reason: $1 ${ENDCOLOR}"
	exit 1
}

function show_msg {
	echo -e "${C_HEADLINES}Info: ${1} is${C_HIGHLIGHTS} ${2} ${ENDCOLOR}"
}

function create_savegame {
	echo -en "Creating $1${FILE_ENDING} ... "
	tar $(echo "-c${TAR_COMPRESSION}f") "${LOCAL_SAVEGAME_DIRECTORY}$1${FILE_ENDING}" -C $2 . && echo -e "${C_SUCCESS}successful${C_NORMAL}!${ENDCOLOR}" || exit_msg "create_savegame + $1"
}

function restore_savegame {
	echo -en "Restoring $1${FILE_ENDING} ... "
	tar $(echo "-x${TAR_COMPRESSION}f") "${LOCAL_SAVEGAME_DIRECTORY}$1${FILE_ENDING}" -C $2 && echo -e "${C_SUCCESS}successful${C_NORMAL}!${ENDCOLOR}" || exit_msg "restore_savegame + $1"
}

function check_import_export {
	echo -en "Checking local savegame status: "
	compare_info_dates ${1}
	if [ ${STATUS} == ${RED} ]; then IMPORT_NEEDED=true; EXPORT_NEEDED=false; echo -e "Local savegame of ${ALL_EMULATORS_DISPLAY[${1}]} is ${RED}outdated${C_NORMAL}."; else IMPORT_NEEDED=false; EXPORT_NEEDED=true; echo -e "Local savegame of ${ALL_EMULATORS_DISPLAY[${1}]} is ${GREEN}up to date or newer${C_NORMAL}."; fi
}

# Check which emulator needs to get updated. Then update the ${OPTION} variable accordingly
function check_emu {
	for z in ${OPTION[@]}; do
		local used_new_option=false
		declare -A new_option

		if ${EMULATORS[${z}]}; then # If the emulator is active/enabled
			show_msg "${ALL_EMULATORS_DISPLAY[${z}]}" "enabled"
		else # If the emulator is inactive/disabled
			show_msg "${ALL_EMULATORS_DISPLAY[${z}]}" "disabled"
			continue # Important! Skip the emulator no matter what!
		fi

		if ${EXPORT} && ${EMULATORS[${z}]}; then #IF EXPORT
			check_import_export ${z}
			if ${EXPORT_NEEDED}; then
				new_option[${z}]=${z} #Add OPTION to new_option, because we don't skip it
				[[ ${MAX_NUMBER_OF_ADDITIONAL_BACKUPS} > 0 ]] && echo -e "${C_HEADLINES}Info: Max. number of backups: ${C_HIGHLIGHTS}${MAX_NUMBER_OF_ADDITIONAL_BACKUPS}${C_HEADLINES}. Shifting older backups:${ENDCOLOR}" && backup_old_savegame "${z}" || echo -e "${C_HEADLINES}Info: The old backup will be ${C_HIGHLIGHTS}overwritten${C_HEADLINES}! See: MAX_NUMBER_OF_ADDITIONAL_BACKUPS${ENDCOLOR}";
				create_savegame ${z} ${SAVEGAME_PATH[${z}]};
			else
				#If we are here, we dont want to upload the specific emu and dont want to update .info and .synchronization files
				used_new_option=true;
				#Here we dont add the emu into the new_option array, because we want to skip it
			fi
		fi

		if ${IMPORT} && ${EMULATORS[${z}]}; then #IF IMPORT
			check_import_export ${z}
			if ${IMPORT_NEEDED}; then
				new_option[${z}]=${z} #Add OPTION to new_option, because we don't skip it
				${NO_CLOUD} || ${DEACTIVATE_UPLOAD_BY_DEFAULT} || download_savegame "${z}"; #Download the actual savegame files from the cloud, if active
				restore_savegame "${z}" "${SAVEGAME_PATH[${z}]}"; #Restore the specific emu savegame in LOCAL_SAVEGAME_DIRECTORY
			else
				used_new_option=true;
				#Here we dont add the emu into the new_option array, because we want to skip it
			fi
		fi
	done

	# Update the OPTION variable
	OPTION=( ${new_option[@]} );
}

function show_cloud_status {
	if ${NO_CLOUD} || ${DEACTIVATE_UPLOAD_BY_DEFAULT}; then
		echo -e "${C_HEADLINES}Info: The cloud feature is ${C_HIGHLIGHTS}deactivated${C_HEADLINES}.${ENDCOLOR}";
	else
		echo -e "${C_HEADLINES}Info: The cloud feature is ${C_HIGHLIGHTS}activated${C_HEADLINES}.${ENDCOLOR}"
	fi
}

# Check savegame directory --------------- Check savegame directory #
if [ ! -d "${LOCAL_SAVEGAME_DIRECTORY}" ]; then
	mkdir -p "${LOCAL_SAVEGAME_DIRECTORY}"
fi

# Check savegame info file --------------- Check savegame info file #
if [ ! -f "${INFO_PATH}" ]; then
	touch "${INFO_PATH}"
fi

# Check parameters ------------------------------- Check parameters #
if [[ $# -eq 0 ]]; then
	echo -e "${C_ERROR}Error: You need to add an option. Add -h for a help page. :)${ENDCOLOR}"
	exit 1
fi

# Check whether .info or .synchronization are empty:
check_empty_info_file #Create empty arrays, if .info is empty
if [ ! -f "${SYNCHRONIZATION_PATH}" ]; then touch ${SYNCHRONIZATION_PATH}; create_empty_info_file "S_" ""; fi #If .synchronization does not exist, create it
if [[ $(cat ${SYNCHRONIZATION_PATH}) == "" ]]; then create_empty_info_file "S_" ""; fi #If .synchronization is empty, create empty arrays

get_file_ending

while [[ $# -gt 0 ]]; do
	case $1 in
		-n|--no)
			NO_CLOUD=true
			;;
		export)
			EXPORT=true
			echo -e "${C_HEADLINES}Mode: ${C_HIGHLIGHTS}Export${ENDCOLOR}"
			;;
		import)
			IMPORT=true
			echo -e "${C_HEADLINES}Mode: ${C_HIGHLIGHTS}Import${ENDCOLOR}"
			;;
		-a|--all)
			OPTION=(${ALL_EMULATORS[@]})
			;;
		-2|-ps2|--pcsx2)
			OPTION=("pcsx2")
			;;
		-p|-psp|--ppsspp)
			OPTION=("ppsspp")
			;;
		-d|--dolphin)
			OPTION=("dolphin_gc" "dolphin_wii")
			;;
		-g|--gamecube)
			OPTION=("dolphin_gc")
			;;
		-w|--wii)
			OPTION=("dolphin_wii")
			;;
		-c|-3ds|--citra)
			OPTION=("citra")
			;;
		-s|--status)
			show_cloud_status
			${NO_CLOUD} || ${DEACTIVATE_UPLOAD_BY_DEFAULT} || download_synchronization #Download .synchronization file from the cloud, if active
			show_status
			exit 0
			;;
		-/|--path|--var)
			show_path_variables
			exit 0
			;;
		-!|--change_var)
			shift
			VAR_NUMBER=$1
			shift
			NEW_VAR_VALUE=$1
			change_var_value
			exit 0
			;;
		-v|--version)
			echo -e "${C_NORMAL}Bash-Script: save-emu.sh | Released: ${DATE} | Version:${C_HIGHLIGHTS} ${VERSION} ${C_NORMAL}| GitHub: https://github.com/Shipoyumi/save-emu${ENDCOLOR}"
			exit 0
			;;
		-h|--help)
			show_help
			exit 0
			;;
		-*|--*)
			echo -e "${C_ERROR}Error: Unknown option $1 | Use -h for a help page. :)${ENDCOLOR}"
			exit 1
			;;
		*)
			echo -e "${C_ERROR}Error: Your argument $1 is not supported. Use -h for a help page. :)${ENDCOLOR}"
			exit 1
			;;
	esac
	shift
done

show_cloud_status

${NO_CLOUD} || ${DEACTIVATE_UPLOAD_BY_DEFAULT} || download_synchronization #Download .synchronization file from the cloud, if active

# Info: All of the following commands use the ${OPTION} variable to update/import/export stuff!

check_emu #Start the check_process. If no OPTION is given, then we do nothing, because the array is empty

# IMPORT: Updating .info file locally
if ${IMPORT}; then echo -en "Updating .info file ... "; import_info_file "i" && echo -e "${GREEN}successful.${C_NORMAL}" || echo -e "${RED}failed.${C_NORMAL}"; fi

# EXPORT: Updating .info file locally
if ${EXPORT}; then echo -en "Updating .info file ... "; export_info_file "i" && echo -e "${GREEN}successful.${C_NORMAL}" || echo -e "${RED}failed.${C_NORMAL}"; fi

# EXPORT: Updating .synchronization file locally
if ${EXPORT}; then echo -en "Updating .synchronization file ... "; export_info_file "s" && echo -e "${GREEN}successful.${C_NORMAL}" || echo -e "${RED}failed.${C_NORMAL}"; fi

# EXPORT: Upload savegames after the creation of the compressed archives
if ${EXPORT}; then ${NO_CLOUD} || ${DEACTIVATE_UPLOAD_BY_DEFAULT} || upload_savegame; fi

# End message (success)
echo -e "${C_SUCCESS}Finished process successfully! ${CAT}${ENDCOLOR}"
