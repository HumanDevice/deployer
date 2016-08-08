# bash scripts

## deployer v1.1

deploy SVN version of Yii 2 project

### SYNOPSIS

    deployer.sh -d TAG [-v] [-n] [-e ENV]
    deployer.sh -r TAG [-v] [-n] [-e ENV]
    deployer.sh -dev [-v] [-n] [-e ENV]
    deployer.sh -h

### DESCRIPTION

Deploys the target TAG version of Yii 2 project or rollbacks to the target TAG version. 
Creates the releases and composer folders. Deployed version is stored in the releases
folder under the TAG name. Composer folder stores the vendor folder with composer
dependencies. TAG version is SVN-imported using provided SVN credentials.

Deployed or rollbacked version is symlinked to the Apache host target folder.

    -d TAG, --deploy TAG

deploy TAG version

    -r TAG, --rollback TAG

rollback to TAG version

    -dev

deploy DEV version

    -v, --verbose

runs the script in verbose mode where output of svn, composer and init is visible

    -n, --noupdate

skips composer update part (composer install ignores this option)

    -e ENV, --env ENV

sets environment name ENV for init

    -h, --help

help screen
