#!/bin/bash
# testing:
# 	bash ~/esp/esp-install-custom/cron-reinstall-esp-idf.sh test
# 	tail -f -n 50 ~/esp/install.log

# cron:
# 	crontab -e
# 	0 8 * * * bash $HOME/esp/esp-install-custom/cron-reinstall-esp-idf.sh

startTime=$(date '+%s')
cronVers=53-rc1.1 # version of this script
log=$HOME/esp/install.log

function return_status() {
	strii="\treturn status: ${?}"
	echo -e "$strii\n"
	echo -e "$strii\n" >> $log
}

function write_to_log() {
	echo -e "$1"
	echo -e "$1" >> $log
}

write_to_log " === $(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): new reinstall ==="
write_to_log "Cron version: ${cronVers}"

myUser=$USER

gitJobs=5
installDir=$HOME/esp
gitBranch=master
runningDir="$( cd "$( dirname "$0" )" && pwd )"
idfDir=$installDir/esp-idf
espressifLocation=$HOME/.espressif
customBinLocation=$installDir/.custom_bin
customBinFrom=$runningDir/custom_bin
versionData=$installDir/version-data.txt

if [ "$1" == "test" ]; then
	write_to_log "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): test mode"
	gitCmd="git clone --jobs $gitJobs --branch $gitBranch --single-branch https://github.com/espressif/esp-idf $idfDir"
	installCmd="echo $idfDir/install.sh all"
	toolsInstallCmd="echo python $idfDir/tools/idf_tools.py install all"
	sleepMins=0

	# rm  -f $HOME/esp/install.log; rm  -f $HOME/esp/install.log; ls $HOME/esp; bash $HOME/esp/esp-install-custom/cron-reinstall-esp-idf.sh
	rm -f $HOME/esp/install.log
	rm -f $HOME/version-data.txt
	ls $HOME/esp
	
	function logout_all_users() {
		who | awk '{print $1}'
		return $?
	}
else
	write_to_log "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): LIVE mode"

	sleepMins=3 # minutes of warning to wait for user to log out

	gitCmd="git clone --recursive --jobs $gitJobs --branch $gitBranch https://github.com/espressif/esp-idf $idfDir"
	installCmd="$idfDir/install.sh all"
	toolsInstallCmd="python $idfDir/tools/idf_tools.py install all"

	function logout_all_users() {
		who | sudo awk '$1 !~ /root/{ cmd="/usr/bin/loginctl terminate-user " $1; system(cmd)}'
		return $?
	}
fi

sleepSecs=$((sleepMins*60)) # calculated seconds of warning to wait for user to log out

warningString="\nWARNING:\n\tReinstalling esp-idf in ${sleepMins} minutes! You will be force logged out in ${sleepMins} minutes! Save and log out!\n\tmonitor with \`tail -f -n 50 $HOME/esp/install.log\`\n\tterminate with \`sudo killall cron-reinstall-esp-idf.sh\`\n\t$(date '+%d/%m/%Y %H:%M:%S %Z (%s)')"

write_to_log "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): sending warning message to $myUser"
write_to_log "$warningString"
echo -e "$warningString" | sudo write "$myUser"
return_status

write_to_log "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): sleeping ${sleepMins} minutes"
sleep $sleepSecs
return_status

write_to_log "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): force logging out all users"
logout_all_users
return_status

write_to_log "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)')\nvars:\n\tmyUser: $myUser\n\tcronVers: $cronVers\n\tgitJobs: $gitJobs\n\tversionData: $versionData\n\tlog: $log\n\tsleepMins: $sleepMins\n\tsleepSecs: $sleepSecs\n\tinstallDir: $installDir\n\tgitBranch: $gitBranch\n\trunningDir: $runningDir\n\tidfDir: $idfDir\n\tespressifLocation: $espressifLocation\n\tcustomBinLocation: $customBinLocation\n\tcustomBinFrom: $customBinFrom\n\tinstallCmd: $installCmd\n\ttoolsInstallCmd: $toolsInstallCmd"
return_status

if ! [ -d $installDir ]; then
	write_to_log "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): creating ${installDir}"
	mkdir $installDir
	return_status
fi

if [ -d $idfDir ]; then
	write_to_log "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): deleting ${idfDir}"
	rm -rf $idfDir
	return_status
fi

if [ -d $espressifLocation ]; then
	write_to_log "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): deleting ${espressifLocation}"
	rm -rf "${espressifLocation}"
	return_status
fi

if [ -d $customBinLocation ]; then
	write_to_log "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): deleting ${customBinLocation}"
	rm -rf $customBinLocation
	return_status
fi

write_to_log "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): copying scripts from ${customBinFrom} to ${customBinLocation}"
cp -r $customBinFrom $customBinLocation
return_status

write_to_log "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): making scripts executable at ${customBinLocation}"
chmod -R +x $customBinLocation
return_status

write_to_log "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): cloning git branch ${gitBranch} with ${gitJobs} jobs to ${idfDir}"
eval "$gitCmd"
return_status

write_to_log "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): installing with ${idfDir}/install.sh all"
eval "$installCmd"
return_status

write_to_log "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): installing tools with python ${idfDir}/tools/idf_tools.py install all"
eval "$toolsInstallCmd"
return_status

write_to_log "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): backing up ${idfDir}/export.sh to ${idfDir}/export.sh.bak"
cp $idfDir/export.sh $idfDir/export.sh.bak
return_status

write_to_log "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): editing ${idfDir}/export.sh"
sed -i 's/return 0/# return 0/g' $idfDir/export.sh
return_status

write_to_log "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): adding add-to-export-sh.txt to ${idfDir}/export.sh"
cat $runningDir/add-to-export-sh.txt >> $idfDir/export.sh
return_status

write_to_log "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): getting the commit hash"
commitHash=$(git -C $idfDir rev-parse HEAD)
return_status

gitDataLog="$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): installed esp-idf from commit $commitHash from branch $gitBranch using $cronVers"
write_to_log "$gitDataLog"
echo -e "$gitDataLog" >> $versionData
return_status

rebootMsg="$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): rebooting in $sleepMins minutes. save and log out"
write_to_log "$rebootMsg"
echo "$rebootMsg" | sudo write "$myUser"
return_status

write_to_log "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): sleeping ${sleepMins} minutes"
sleep $sleepSecs
return_status

write_to_log "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): force logging out all users"
logout_all_users
return_status

endTime=$(date '+%s')
timeElapsed=$(($endTime-$startTime))
write_to_log "reinstall completed in $timeElapsed seconds"

write_to_log " === $(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): finished ===\n"

if [ "$1" == "test" ]; then
	echo sudo reboot
else
	sudo reboot
fi

