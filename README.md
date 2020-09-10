# WP Auto Update

## Description
This is a simple bash script that's using [WP CLI](https://wp-cli.org/) to update the WordPress Core/Plugins Automatically.
WordPress already has a feature like this so what this script does differently, it creates a full website backup before the update, making it safe for live websites so they could be reverted easily if anything bad happens during the update.

The code is completely open source, you can change it however you like

## Usage
Note:
It's not possible to run this code as **root**!\
Find the following variables and edit them if needed\
**SITES_PATH** - default: */var/www/html* \
**SITES_WP_ROOT** - default */public_html* (delete if you don't have this)\
**MAIL_SUBJECT**\
**MAIL_TO**\
Give the script execute permission `chmod +x wp_auto_update.sh`\
Run it with `./wp_auto_update.sh`\
System wide use:\
Move the script to the */usr/local/bin* `sudo mv wp_auto_update.sh /usr/local/bin/wp_auto_update`\
Run it with `wp_auto_update` anywhere (Useful for cronjobs)

## Logging & Backups
Global log file can be found under **SITES_PATH**/wp_auto_update folder.
Site logs can be found under **SITES_PATH**/**SITE_FOLDER_NAME**/logs/date
Site logs can be found under **SITES_PATH**/**SITE_FOLDER_NAME**/backups/date

## TODO
- [ ] Create email notification
