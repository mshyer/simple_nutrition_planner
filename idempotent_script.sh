DATABASE_NAME=$1 #1st argument passed from command line shell

dropdb $DATABASE_NAME
createdb $DATABASE_NAME

psql $DATABASE_NAME -f $DATABASE_NAME.sql
