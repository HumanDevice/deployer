# deployer

Deploys SVN/GIT version of Yii 2 project

## SYNOPSIS

    deployer -d TAG [-v] [-s] [-e ENV]
    deployer -r TAG [-v] [-e ENV]
    deployer -dev [-v] [-s] [-e ENV]
    deployer -b BRANCH [-v] [-s] [-e ENV]
    deployer -h
    deployer -c
    deployer -u

## LOCAL INSTALLATION

Copy `deployer` to the project folder.

## GLOBAL INSTALLATION

Run

    composer global require humandevice/deployer

and then

    composer run-script post-update-cmd -d COMPOSER_VENDOR/humandevice/deployer

where `COMPOSER_VENDOR` is the vendor composer folder. You can find it by running `composer global config vendor-dir --absolute`.

## GLOBAL UPDATE

Run

    deployer -u

## CONFIGURATION

Run `deployer -c` to generate configuration file and set all variables there.

## DESCRIPTION

Deploys the target TAG version of Yii 2 project or rollbacks to the target TAG version.
Creates the releases and composer folders. Deployed version is stored in the releases
folder under the TAG name. Composer folder stores the vendor folder with composer
dependencies. TAG version is SVN-imported or GIT-cloned using provided credentials.
Script deletes `environments` folder and runs migration.

If environment is set to `Production` composer runs with option `--no-dev --optimize-autoloader`.

Deployed or rollbacked version is symlinked to the Apache host target folder.

| option    | alias           | description
|-----------|-----------------|-----------------------------------------------------------------------------------
| -d TAG    | --deploy TAG    | deploy TAG version
| -r TAG    | --rollback TAG  | rollback to TAG version
| -dev      |                 | deploy development version
| -b BRANCH | --branch BRANCH | deploy development version from BRANCH branch (no starting and ending trailers)
| -v        | --verbose       | runs the script in verbose mode where output of svn, composer and init is visible
| -s        | --skipmigrate   | skips the migration process
| -e ENV    | --env ENV       | sets environment name ENV for init
| -h        | --help          | help screen
| -c        | --config        | creates (overwrites) deployer.cfg file
| -u        | --update        | updates deployer using composer in global mode

## CONFIGURATION

Configuration can be stored in separate file `deployer.cfg` (in the same folder).

| name       | description
|------------|----------------------------------------------------------------------------
| HOST       | Project folder name, this is virtual host target folder.
| ENV        | Environment name for Yii 2 init command (can be set with -e flag also).
| REPO_TYPE  | Repo type: GIT or SVN.
| REPO_URL   | URL of the repo server.
| REPO_USER  | Name of the repo user with read rights.
| REPO_PASS  | Repo password for REPO_USER.
| DEV_BRANCH | Repo branch for development releases (no starting and ending trailers).
| RIGHTS     | Optional folder rights to be set (use chown syntax owner:group).
| PROJECT    | Project name (for display purposes only).

