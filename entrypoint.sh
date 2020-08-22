#!/bin/sh -l

set -eu

export GITHUB="true"

THEDATE=`date +%d%m%y%H%M`

# Check what to be back up
echo "Backup type: $INPUT_TYPE"
if [ "$INPUT_TYPE" = "db" ]
  then
    FILENAME=mysql-$INPUT_DB_NAME.$THEDATE.sql.gz
    echo "DB type: $INPUT_DB_TYPE"
    if [ "$INPUT_DB_TYPE" = "mysql" ]
      then
        INPUT_SCRIPT="mysqldump -q -u $INPUT_DB_USER -p'$INPUT_DB_PASS' $INPUT_DB_NAME | gzip -9 > $FILENAME"
    fi
fi

# Execute SSH Commands to create backups first
echo "Running commands over ssh..."
sh -c "/bin/drone-ssh $*"

# Load the deploy key
echo "Loading the deploy key..."
mkdir -p ~/.ssh
echo $INPUT_DEPLOY_KEY > ~/.ssh/deploy_key 
chmod 600 ~/.ssh/deploy_key
echo "Done!!"

#-----------------------------
# CREATE DESTINATION DIR IF NOT EXISTS
#-----------------------------
if [ ! -d ./$INPUT_DB_NAME/ ]
then
    mkdir $INPUT_DB_NAME
fi

echo "Show me destination dir.."
ls -la

# Rsync the backup files to container
echo "Sync the backups..."
echo "Run command: rsync --remove-source-files -avzhe 'ssh -i ~/.ssh/deploy_key -o StrictHostKeyChecking=no -p 22' --progress $INPUT_USERNAME@$INPUT_HOST:./mysql* ./$INPUT_DB_NAME/"
sh -c "rsync --remove-source-files -avzhe 'ssh -i ~/.ssh/deploy_key -o StrictHostKeyChecking=no' --progress $INPUT_USERNAME@$INPUT_HOST:./mysql* ./$INPUT_DB_NAME/"

echo "Show me backups..."
ls -la && ls -l ./$INPUT_DB_NAME/
