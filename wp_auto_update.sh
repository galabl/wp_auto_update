#!/bin/bash
# =========================================================================
# ============== WordPress Auto Update Core/Plugins Script ================
# =================== Created By galabl on 09/10/2020 =====================
# ====================== Last updated: 09/10/2020 =========================
# =========================================================================

# =========================================================================
# ========================== Script Variables =============================
# =========================================================================

SITES_PATH="/var/www/html" # Please update this if it's different in your environment
SITES_WP_ROOT="/public_html" # Please update or delete /public_html if neccessary to the folder name that have your WP installation (Must have trailing slash)
SKIP_FILE="skip_sites"
MAIL_SUBJECT="WordPress auto updates are completed"
MAIL_TO="email@domain.com"

# If you're unfamiliar with bash, please do not make any changes below!!!!!!
DATE="$(date +"%Y-%m-%d")"
SITES=""
SKIP=""
SCRIPT_FOLDER="$SITES_PATH/wp_auto_update"
LOGS="logs" 
BACKUPS="backups"
GLOBAL_LOG="$SCRIPT_FOLDER/global.log"

SITES="$(ls -a $SITES_PATH | sed -e '1,2d')"

# Boolean for sending email notification
UPDATED=false

# =========================================================================
# ============================ System Check ===============================
# =========================================================================

WP_CLI=/usr/local/bin/wp
if [ -x "$WP_CLI" ]; then
	echo "WP CLI is present on the system." >> $GLOBAL_LOG
else
	echo "Error! The WP CLI cannot be found in /usr/local/bin. Exiting!" >> $GLOBAL_LOG
	echo "Please install WP CLI following this guide https://make.wordpress.org/cli/handbook/guides/installing/" >> $GLOBAL_LOG
	exit 1
fi

# Check if sites path is defined correctly 
if [ ! -d "$SITES_PATH" ]; then
	echo "SITES_PATH Variable is not defined correctly. $SITES_PATH folder does not exist." >> $GLOBAL_LOG
	exit 1
fi 

# Check is script folder for storing logs and backups created
if [ ! -d "$SCRIPT_FOLDER" ]; then
	echo "Script folder doesn't exist. Creating $SCRIPT_FOLDER..." >> $GLOBAL_LOG
	mkdir $SCRIPT_FOLDER >> /dev/null 2>&1
fi

# =========================================================================
# ========================== Script Functions =============================
# =========================================================================

function create_site_folders() {
	if [ ! -d "$SCRIPT_FOLDER/$1" ]; then
		# Initial Folder Creation
		mkdir "$SCRIPT_FOLDER/$1" >> /dev/null 2>&1
		mkdir "$SCRIPT_FOLDER/$1/$BACKUPS">> /dev/null 2>&1
		mkdir "$SCRIPT_FOLDER/$1/$BACKUPS/$DATE" >> /dev/null 2>&1
		mkdir "$SCRIPT_FOLDER/$1/$LOGS" >> /dev/null 2>&1
		mkdir "$SCRIPT_FOLDER/$1/$LOGS/$DATE" >> /dev/null 2>&1
	else
		# If folder exist, just add additional for todays date 
		mkdir "$SCRIPT_FOLDER/$1/$BACKUPS/$DATE" >> /dev/null 2>&1
		mkdir "$SCRIPT_FOLDER/$1/$LOGS/$DATE" >> /dev/null 2>&1
	fi
}

# =========================================================================
# ===================== Starting The Update Process =======================
# =========================================================================

# Getting sites that needs to be skipped
if [ -f "$SCRIPT_FOLDER/$SKIP_FILE" ]; then
	SKIP="$(cat $SCRIPT_FOLDER/$SKIP_FILE)"
else
	echo "wp_auto_update" > $SCRIPT_FOLDER/$SKIP_FILE
fi

for SITE_NAME in $SITES
do
	SITE_PATH="$SITES_PATH/$SITE_NAME$SITES_WP_ROOT"
	# Check is this a WordPress site
	if $($WP_CLI core is-installed --path=$SITE_PATH); then
		create_site_folders $SITE_NAME
		LOG_FILE="$SCRIPT_FOLDER/$SITE_NAME/$LOGS/$DATE/debug.log"
		BACKUP_FILE="$SCRIPT_FOLDER/$SITE_NAME/$BACKUPS/$DATE/backup"
		SKIP_BOOL=false
		# Check if site needs to be skipped
		if [ "$SKIP" != "" ]; then
			for SKIP_NAME in $SKIP
			do
				[ "$SITE_NAME" == "$SKIP_NAME" ] && SKIP_BOOL=true || :
			done
		fi

		if $SKIP_BOOL; then
			echo "$SITE_NAME will be skipped" >> $LOG_FILE
		else
			echo "Checking $SITE_NAME for WordPress Core/Plugin updates" >> $LOG_FILE
			CORE_UPDATE=$($WP_CLI core check-update --path=$SITE_PATH | grep Success) >> $LOG_FILE
			PLUGIN_UPDATE=$($WP_CLI plugin update --dry-run --all --path=$SITE_PATH | grep "Available plugin updates" ) >> $LOG_FILE
			if [ -z "$CORE_UPDATE" ] || [ -z $PLUGIN_UPDATE ]; then
				echo "Creating files backup for $SITE_NAME" >> $LOG_FILE
				tar czf "$BACKUP_FILE.tgz" "$SITE_PATH"
				$WP_CLI db export --path=$SITE_PATH $BACKUP_FILE.sql >> $LOG_FILE
				if [ -f $BACKUP_FILE.tgz ] && [ -f $BACKUP_FILE.sql ]; then
					echo "Backups for $SITE_NAME are succesfully created. Let's start with updating" >> $LOG_FILE
					UPDATED=true
					$WP_CLI core update --path=$SITE_PATH >> $LOG_FILE
					$WP_CLI plugin update --all --path=$SITE_PATH >> $LOG_FILE
					echo "Updating $SITE_NAME finished" >> $LOG_FILE
				else
					echo "Something went wrong with creating files backup for $SITE_NAME!!! Exiting" >> $LOG_FILE
					exit 1
				fi
			else 
				echo "$SITE_NAME is up to date!" >> $LOG_FILE
			fi
		fi
	else
		echo "$SITE_NAME is not a WordPress site. Skipping..." >> $GLOBAL_LOG
		echo "-----------------------------------------------" >> $GLOBAL_LOG
		echo >> $GLOBAL_LOG
	fi
done

echo "No more sites to update. Bye!" >> $GLOBAL_LOG
echo "Check global.log and site logs"
exit 1

#TODO EMAIL NOTIFICATION