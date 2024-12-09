# DatabaseRestore

1. Install VS Code Theme [Cyberpunk 2077 rebuild](https://vscodethemes.com/e/carlos18mz.cyberpunk-2077-rebuild/cyberpunk-2077-rebuild)
2. [Install Python 3.11.5](https://www.python.org/downloads/release/python-3115/)
3. `git clone https://github.com/smchughinfo/DatabaseRestore.git`
4. `cd DatabaseRestore`
5. code .
6. ctrl+shift+p > Python: Create Environment > Venv > Python 3.11.5 (requirements.txt or do step 8)
7. if environment not activated `.venv/scripts/activate`
8. `pip install -r requirements.txt`

The BatchScripts folder contains batch scripts that run the program. The program can do three things:

1. Backup the exsiting database.
2. Restore the database from the last backup.
3. Update the database schema by running migrations.

Container Info

To build the container cd into the root directory (same one as this README.md file) and run `docker build --no-cache -t openclone-database:1.0 -f Container/Dockerfile .` You will need Docker Desktop, WSL, WSL enabled in Docker Desktop, etc. To run container do:

```
@echo off

rem ####################################################################
rem ##### RUN EXISITING CONTAINER IF IT EXISTS #########################
rem ####################################################################

docker container inspect openclone-database >nul 2>&1
if %ERRORLEVEL% == 0 (
    docker start -a openclone-database
    pause
    goto :EOF
)

rem ####################################################################
rem ###### RUN CONTAINER FOR THE FIRST TIME ############################
rem ####################################################################

rem Initialize the command string
set cmd=docker run

rem ####################################################################
rem ###### NETWORK #####################################################
rem ####################################################################

set cmd=%cmd% -p 5433:5432

rem ####################################################################
rem ###### SUPERUSER ###################################################
rem ####################################################################

set cmd=%cmd% -e POSTGRES_PASSWORD=%OpenClone_postgres_superuser_password%

rem ####################################################################
rem ###### OPEN CLONE DB ###############################################
rem ####################################################################

set cmd=%cmd% -e OpenClone_OpenCloneDB_User=%OpenClone_OpenCloneDB_User%
set cmd=%cmd% -e OpenClone_OpenCloneDB_Password=%OpenClone_OpenCloneDB_Password%
set cmd=%cmd% -e OpenClone_OpenCloneDB_Name=%OpenClone_OpenCloneDB_Name%

rem ####################################################################
rem ###### LOG DB ######################################################
rem ####################################################################

set cmd=%cmd% -e OpenClone_LogDB_User=%OpenClone_LogDB_User%
set cmd=%cmd% -e OpenClone_LogDB_Password=%OpenClone_LogDB_Password%
set cmd=%cmd% -e OpenClone_LogDB_Name=%OpenClone_LogDB_Name%

rem ####################################################################
rem ###### CONTAINER NAME ##############################################
rem ####################################################################

set cmd=%cmd% --name openclone-database openclone-database:1.0

rem Finally execute the command
start cmd /k "%cmd%"

```



Notes: 

- If running migrate doesn't work try manually deleting the database and running it again.
- If after running restore or migrate you are unable to generate text to speech with ElevenLabs set clone.voice_id=null. clone.voice_id will be regenerated the next time the web server starts