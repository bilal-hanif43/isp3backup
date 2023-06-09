#!/bin/sh
#
# ISPConfig3 restore script based on bak-res script by go0ogl3 gabi@eurosistems.ro
#
# Note: This script assumes that the backup was created using the corresponding backup script.
# Please make sure to adjust the variables according to your backup configuration.

## Start user editable variables
BACKUPDIR="/backup"                 # backup directory
RESTOREDIR="/var/www/clients"       # directory where ISPConfig 3 clients folders should be restored

DBUSER="root"                       # database user
DBPASS="nBDxqSaN5mJKystXX8UK"       # database password
TMPDIR="/tmp/tmpbck"                # temp dir for database dump and other stuff

## End user editable variables

## Do not edit this section
FDATE=`date +%F`        # Full Date, YYYY-MM-DD, year sorted, eg. 2009-11-21

## End of non-editable variables

## Start restoration process
message="Start restore ..."
echo $(dateStatement) $message

# Check if the backup directory exists
if [ ! -d $BACKUPDIR/$FDATE/ ]; then
  message="Backup directory does not exist for the specified date: $FDATE"
  echo $(dateStatement) $message
  exit 1
fi

###### Start databases restoration
message="Start MySQL databases restoration"
echo $(dateStatement) $message

# Create temporary directory if it doesn't exist
if [ ! -d $TMPDIR/ ]; then
  mkdir $TMPDIR/
fi

# Restore each database
for backupFile in $(ls $BACKUPDIR/$FDATE/db/*.tar.gz); do
  database=$(basename ${backupFile%.*})
  echo "Restoring database: $database"
  
  # Extract the database dump
  tar -zxpf $backupFile -C $TMPDIR

  # Restore the database
  mysql -u$DBUSER -p$DBPASS -e "DROP DATABASE IF EXISTS $database;"
  mysql -u$DBUSER -p$DBPASS -e "CREATE DATABASE $database;"
  mysql -u$DBUSER -p$DBPASS $database < $TMPDIR/db-$database-$FDATE.sql

  # Clean up
  rm $TMPDIR/db-$database-$FDATE.sql
done

message="MySQL databases restoration completed"
echo $(dateStatement) $message

###### End databases restoration

###### Start websites restoration
message="Start websites restoration"
echo $(dateStatement) $message

# Restore each website
for backupFile in $(ls $BACKUPDIR/$FDATE/webs/*/*.tar.gz); do
  website=$(basename ${backupFile%.*})
  client=$(dirname $(dirname $backupFile))

  echo "Restoring website: $client/$website"

  # Create the website directory if it doesn't exist
  if [ ! -d $RESTOREDIR/$client/$website/ ]; then
    mkdir -p $RESTOREDIR/$client/$website/
  fi

  # Extract the website backup
  tar -zxpf $backupFile -C $RESTOREDIR/$client/$website/
done

message="Websites restoration completed"
echo $(dateStatement) $message

###### End websites restoration

# all done
message="Restore process completed"
echo $(dateStatement) $message
exit 0
