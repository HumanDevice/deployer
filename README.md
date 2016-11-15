# deployer

Deploys SVN version of Yii 2 project

## SYNOPSIS

    deployer -d TAG [-v] [-n] [-e ENV]
    deployer -r TAG [-v] [-n] [-e ENV]
    deployer -dev [-v] [-n] [-e ENV]
    deployer -h
    deployer -c
    
## LOCAL INSTALLATION

Copy `deployer` (optionally with `deployer.cfg`) to the project folder.

## GLOBAL INSTALLATION

Run

    composer global require humandevice/deployer

and then

    composer global run-script post-update-cmd -d ./vendor/humandevice/deployer

## DESCRIPTION

Deploys the target TAG version of Yii 2 project or rollbacks to the target TAG version. 
Creates the releases and composer folders. Deployed version is stored in the releases
folder under the TAG name. Composer folder stores the vendor folder with composer
dependencies. TAG version is SVN-imported using provided SVN credentials.
Script deletes `environments` folder.

If environment is set to `Production` composer runs with option `--no-dev --optimize-autoloader`.

Deployed or rollbacked version is symlinked to the Apache host target folder.

| option | alias          | description
|--------|----------------|-----------------------------------------------------------------------------------
| -d TAG | --deploy TAG   | deploy TAG version
| -r TAG | --rollback TAG | rollback to TAG version
| -dev   |                | deploy development version
| -v     | --verbose      | runs the script in verbose mode where output of svn, composer and init is visible
| -n     | --noupdate     | skips composer update part (composer install ignores this option)
| -e ENV | --env ENV      | sets environment name ENV for init
| -h     | --help         | help screen
| -c     | --config       | creates (overwrites) deployer.cfg file

## CONFIGURATION

Configuration can be stored in separate file `deployer.cfg` (in the same folder).

| name       | description
|------------|----------------------------------------------------------------------------
| HOST       | Project folder name, this is virtual host target folder.
| ENV        | Environment name for Yii 2 init command (can be set with -e flag also).
| SVN_URL    | URL of the SVN server.
| SVN_USER   | Name of the SVN user with read rights.
| SVN_PASS   | SVN password for SVN_USER.
| SVN_BRANCH | SVN branch path for development releases (no starting and ending trailers).
| RIGHTS     | optional folder rights to be set (use chown syntax owner:group).
| PROJECT    | Project name (for display purposes only).

