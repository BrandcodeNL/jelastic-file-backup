#!/bin/bash

echo "starting backup"
CONFIGFILE="settings.conf"
source $CONFIGFILE


TIME_FORMAT='%d%m%Y-%H%M'

TODAY=$(date +"%Y-%m-%d")
DAILY_DELETE_NAME="daily-"`date +"%Y-%m-%d" --date '7 days ago'`
WEEKLY_DELETE_NAME="weekly-"`date +"%Y-%m-%d" --date '5 weeks ago'`
MONTHLY_DELETE_NAME="monthly-"`date +"%Y-%m-%d" --date '12 months ago'`

check_config(){
    [ ! -f $CONFIGFILE ] && close_on_error "Config file not found, make sure config file is correct"
}

do_backup(){

    BACKUP_PATH="$LOCAL_BACKUP_DIR"
    [ $VERBOSE -eq 1 ] && echo " Check if backup path exists, if not create '$BACKUP_PATH'"
    [[ ! -d "$BACKUP_PATH" ]] && mkdir -p "$BACKUP_PATH"
    echo "   Creating $BACKUP_PATH/daily-$TODAY.tar.gz"
    
    FILE_NAME="daily-$TODAY.tar.gz"
    FILE_PATH="${BACKUP_PATH}/"
    FILENAMEPATH="$FILE_PATH$FILE_NAME"

    tar -czf $FILENAMEPATH $BACKUP_PATHS #--files-from=$BACKUP_CONFFILE

    [ $FTP_ENABLE -eq 1 ] && ftp_backup $FILE_NAME
    
    # delete old backups
    if [ -f "$BACKUP_PATH/$DAILY_DELETE_NAME.tar.gz" ]; then
        echo "   Deleting $BACKUP_PATH/$DAILY_DELETE_NAME.tar.gz"
        rm -rf $BACKUP_PATH/$DAILY_DELETE_NAME.tar.gz
        [ $FTP_ENABLE -eq 1 ] && ftp_delete $DAILY_DELETE_NAME.tar.gz
    fi
    if [ -f "$BACKUP_PATH/$WEEKLY_DELETE_NAME.tar.gz" ]; then
        echo "   Deleting $BACKUP_PATH/$WEEKLY_DELETE_NAME.tar.gz"
        rm -rf $BACKUP_PATH/$WEEKLY_DELETE_NAME.tar.gz
        [ $FTP_ENABLE -eq 1 ] && ftp_delete $WEEKLY_DELETE_NAME.tar.gz
    fi
    if [ -f "$BACKUP_PATH/$MONTHLY_DELETE_NAME.tar.gz" ]; then
        echo "   Deleting $BACKUP_PATH/$MONTHLY_DELETE_NAME.tar.gz"
        rm -rf $BACKUP_PATH/$MONTHLY_DELETE_NAME.tar.gz
        [ $FTP_ENABLE -eq 1 ] && ftp_delete $MONTHLY_DELETE_NAME.tar.gz

    fi
    
    # make weekly
    if [ `date +%u` -eq 7 ];then
        cp $BACKUP_PATH/daily-$TODAY.tar.gz $BACKUP_PATH/weekly-$TODAY.tar.gz
        [ $FTP_ENABLE -eq 1 ] && ftp_backup "weekly-$TODAY.tar.gz"
    fi

    # make monthly
    if [ `date +%d` -eq 25 ];then
        cp $BACKUP_PATH/daily-$TODAY.tar.gz $BACKUP_PATH/monthly-$TODAY.tar.gz
        [ $FTP_ENABLE -eq 1 ] && ftp_backup monthly-$TODAY.tar.gz
    fi          
            
    
    [ $VERBOSE -eq 1 ] && echo "*** Backup completed ***"
    [ $VERBOSE -eq 1 ] && echo "*** Check backup files in ${BACKUP_PATH} ***"

}

ftp_backup(){
[ $VERBOSE -eq 1 ] && echo "Uploading backup file: $1 to FTP"
ftp -n $FTP_SERVER << EndFTP
user "$FTP_USERNAME" "$FTP_PASSWORD"
passive
binary
hash
cd $FTP_UPLOAD_DIR
lcd $FILE_PATH
put "$1"
bye
EndFTP
}

ftp_delete(){
[ $VERBOSE -eq 1 ] && echo "Delete backup file: $1 on FTP"
ftp -n $FTP_SERVER << EndFTP
user "$FTP_USERNAME" "$FTP_PASSWORD"
cd $FTP_UPLOAD_DIR
delete "$1"
bye
EndFTP
}

### main ####
check_config
do_backup
