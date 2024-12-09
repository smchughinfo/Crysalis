import os
import subprocess

if os.getenv("OPENCLONE_ENVIRONMENT") == "remote":
    dbHost = "dev.database.openclone.ai"
    dbPort = 5432
    dbName = "log_db_prod"
    dbUser = "log_user_prod"
    dbUserPassword = "bunnies"

elif os.getenv("OPENCLONE_ENVIRONMENT") == "local":
    dbHost = os.getenv('OpenClone_DB_Host')
    dbPort = os.getenv('OpenClone_DB_Port')
    dbName = os.getenv("OpenClone_LogDB_Name")
    dbUser = os.getenv("OpenClone_LogDB_User")
    dbUserPassword = os.getenv("OpenClone_LogDB_Password")