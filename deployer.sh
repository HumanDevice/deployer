#!/bin/bash
# Human Device Yii 2 deployer v1.2
# ========================================================
# -h, --help for help

# SETTINGS
# ========================================================

# project host folder name
HOST="change me"

# default environment name for Yii 2 init
ENV="Development"

# SVN credentials
SVN_URL='change me'
SVN_USER='change me'
SVN_PASS='change me'

# SVN branch path for development release
SVN_BRANCH='branches/dev'

# folders owner and group if needed (use chown syntax)
RIGHTS=""

# project name (just for display)
PROJECT="change me"

# production releases folder name
R_FOLDER="releases"

# development current release folder name
DC_FOLDER="dev_current"

# development next release folder name
DN_FOLDER="dev_next"

# composer folder name for vendor storage
C_FOLDER="composer"

# temporary composer folder name for vendor storage
C_TEMP_FOLDER="composer_temp"

# script variables
# ========================================================
VERSION=""
VERBOSE=0
USING_TEMPORARY_COMPOSER=0
MODE=0
COMPOSER_DONT_UPDATE=0

# generate line with dots
LINE() {
    local LINE=$(printf '%0.1s' "."{1..60})
    printf "%s%s" "$1" "${LINE:${#1}}"
}

# cleans temporary folder
END_MARKER() {
    if [[ $USING_TEMPORARY_COMPOSER -eq 1 ]]; then
        LINE " > deleting temporary composer folder"
        if rm -rf "./${C_TEMP_FOLDER}"
        then
            echo "deleted"
        fi
    fi
    echo "FINISHED at $(date +"%r")."
}

# creates folder
CREATE_FOLDER() {
    LINE "$1"
    if mkdir "$2"
    then
        chmod 0775 "$2"
        if [[ "$RIGHTS" != "" ]]; then
            chown ${RIGHTS} "$2"
        fi
        echo "created"
        return 1
    fi
    return 0
}

# initialises release folder
INIT_RELEASE_FOLDER() {
    if [[ ! -d "./${R_FOLDER}"  ]]; then
        CREATE_FOLDER " > initialing releases folder" "./${R_FOLDER}"
        if [[ $? -eq 0 ]]; then
            return 0
        fi
    fi
    LINE " > checking release ${1} folder"
    if [[ -d "./${R_FOLDER}/$1" ]]; then
        echo "ALREADY EXISTS! > exit with error"
    else
        echo "ok"
        return 1
    fi
    return 0
}

# initialises development folder
INIT_DEVELOPMENT_FOLDER() {
    if [[ ! -d "./${R_FOLDER}"  ]]; then
        CREATE_FOLDER " > initialing releases folder" "./${R_FOLDER}"
        if [[ $? -eq 0 ]]; then
            return 0
        fi
    fi
    if [[ -d "./${R_FOLDER}/${DN_FOLDER}" ]]; then
        LINE " > deleting old next development release folder"
        if rm -rf "./${R_FOLDER}/${DN_FOLDER}"
        then
            echo "deleted"
        else
            return 0
        fi
    fi
    return 1
}

# checks release folder
CHECK_RELEASE_FOLDER() {
    LINE " > checking release ${1} folder"
    if [[ ! -d "./${R_FOLDER}/$1" ]]; then
        echo "NOT FOUND! > exit with error"
    else
        echo "ok"
        return 1
    fi
    return 0
}

# downloads production release SVN folder
DOWNLOAD_PROD_RELEASE() {
    LINE " > downloading SVN snapshot"
    local CMD="svn export -q \"${SVN_URL}/tags/${1}\" \"./${R_FOLDER}/${1}\" --no-auth-cache --non-interactive --trust-server-cert --username \"${SVN_USER}\" --password '${SVN_PASS}'"
    if [[ $VERBOSE -eq 1 ]]; then
        CMD="svn export \"${SVN_URL}/tags/${1}\" \"./${R_FOLDER}/${1}\" --no-auth-cache --non-interactive --trust-server-cert --username \"${SVN_USER}\" --password '${SVN_PASS}'"
    fi
    if eval "$CMD"
    then
        echo "downloaded"
        if [[ "$RIGHTS" != "" ]]; then
            chown -R ${RIGHTS} "./${R_FOLDER}/${1}"
        fi
        return 1
    fi
    return 0
}

# downloads development release SVN folder
DOWNLOAD_DEV_RELEASE() {
    LINE " > downloading development SVN snapshot"
    local CMD="svn export -q \"${SVN_URL}/${SVN_BRANCH}\" \"./${R_FOLDER}/${DN_FOLDER}\" --no-auth-cache --non-interactive --trust-server-cert --username \"${SVN_USER}\" --password '${SVN_PASS}'"
    if [[ $VERBOSE -eq 1 ]]; then
        CMD="svn export \"${SVN_URL}/${SVN_BRANCH}\" \"./${R_FOLDER}/${DN_FOLDER}\" --no-auth-cache --non-interactive --trust-server-cert --username \"${SVN_USER}\" --password '${SVN_PASS}'"
    fi
    if eval "$CMD"
    then
        echo "downloaded"
        if [[ "$RIGHTS" != "" ]]; then
            chown -R ${RIGHTS} "./${R_FOLDER}/${DN_FOLDER}"
        fi
        return 1
    fi
    return 0
}

# installs composer dependencies
COMPOSER_INSTALL() {
    LINE " > installing composer dependencies"
    if [[ $USING_TEMPORARY_COMPOSER -eq 1 ]]; then
        cd "./${C_TEMP_FOLDER}"
    else
        cd "./${C_FOLDER}"
    fi
    local CMD="composer install -q"
    if [[ $VERBOSE -eq 1 ]]; then
        CMD="composer install"
    fi
    if eval "$CMD"
    then
        echo "installed"
        cd ..
        return 1
    fi
    cd ..
    return 0
}

# updates composer dependencies
COMPOSER_UPDATE() {
    if [[ $COMPOSER_DONT_UPDATE -eq 1 ]]; then
        return 1
    fi
    LINE " > updating composer dependencies"
    cd "./${C_FOLDER}"
    local CMD="composer update -q"
    if [[ $VERBOSE -eq 1 ]]; then
        CMD="composer update"
    fi
    if eval "$CMD"
    then
        echo "updated"
        cd ..
        return 1
    fi
    cd ..
    return 0
}

# checks vendor folder
CHECK_VENDOR() {
    if [[ ! -d "./${C_FOLDER}" ]]; then
        CREATE_FOLDER " > creating composer folder" "./${C_FOLDER}"
        if [[ $? -eq 0 ]]; then
            return 0
        fi
    fi
    LINE " > checking release ${1} composer.json"
    if [[ ! -e "./${R_FOLDER}/$1/composer.json" ]]; then
        echo "NO COMPOSER.JSON FOUND! > exit with error"
        return 0
    else
        echo "ok"
    fi
    if [[ ! -e "./${C_FOLDER}/composer.json" ]]; then
        LINE " > copying composer.json from release ${1} folder"
        if cp "./${R_FOLDER}/$1/composer.json" "./${C_FOLDER}"
        then
            echo "copied"
            COMPOSER_INSTALL
            if [[ $? -eq 0 ]]; then
                return 0
            fi
            return 1
        fi
    else
        LINE " > comparing deployed and vendor composer.json versions"
        if [[ $(stat -c%s "./${C_FOLDER}/composer.json") -eq $(stat -c%s "./${R_FOLDER}/${1}/composer.json") ]]; then
            echo "matching"
            COMPOSER_UPDATE
            if [[ $? -eq 0 ]]; then
                return 0
            fi
            return 1
        else
            echo "different"
            CREATE_FOLDER " > creating temporary composer folder" "./${C_TEMP_FOLDER}"
            if [[ $? -eq 0 ]]; then
                return 0
            fi
            USING_TEMPORARY_COMPOSER=1
            LINE " > copying composer.json from release ${1} folder"
            if cp "./${R_FOLDER}/${1}/composer.json" "./${C_TEMP_FOLDER}"
            then
                echo "copied"
                COMPOSER_INSTALL
                if [[ $? -eq 0 ]]; then
                    return 0
                fi
                return 1
            fi
        fi
    fi
    return 0
}

# symlinks folders
SYMLINK() {
    LINE " > symlinking vendor folder to release $1"
    local CMD="ln -s \"./../../${C_FOLDER}/vendor\" \"./${R_FOLDER}/${1}/vendor\""
    if [[ $USING_TEMPORARY_COMPOSER -eq 1 ]]; then
        CMD="ln -s \"./../../${C_TEMP_FOLDER}/vendor\" \"./${R_FOLDER}/${1}/vendor\""
    fi
    if eval "$CMD"
    then
        echo "done"
        return 1
    fi
    return 0
}

# starts Yii 2 init
INIT() {
    LINE " > running Yii 2 init for ${ENV}"
    local CMD="php \"./${R_FOLDER}/${1}/init\" --env=${ENV} --overwrite=All >/dev/null"
    if [[ $VERBOSE -eq 1 ]]; then
        CMD="php \"./${R_FOLDER}/${1}/init\" --env=${ENV} --overwrite=All"
    fi
    if eval "$CMD"
    then
        echo "done"
        return 1
    fi
    return 0
}

# switches temporary composer folder
SWITCH_TEMP_COMPOSER() {
    if [[ $USING_TEMPORARY_COMPOSER -eq 1 ]]; then
        if rm "./${R_FOLDER}/${1}/vendor"
        then
            if rm -rf "./${C_FOLDER}"
            then
                if cp -a "./${C_TEMP_FOLDER}" "./${C_FOLDER}"
                then
                    if ln -s "./../../${C_FOLDER}/vendor" "./${R_FOLDER}/${1}/vendor"
                    then
                        return 1
                    fi
                fi
            fi
        fi
    else
        return 1
    fi
    return 0
}

# symlinks release
SYMLINK_RELEASE() {
    SWITCH_TEMP_COMPOSER "$1"
    if [[ $? -eq 1 ]]; then
        if ln -s "./${R_FOLDER}/${1}" "./${HOST}"
        then
            echo "released"
            return 1
        fi
    fi
    return 0
}

# creates backup
BACKUP_CREATE() {
    LINE " > creating host symlink and vendor backup"
    if cp -a "./${HOST}" "./${HOST}_backup"
    then
        if cp -a "./${C_FOLDER}/vendor" "./${C_FOLDER}/vendor_backup"
        then
            echo "done"
            return 1
        fi
    fi
    return 0
}

# deletes backup
BACKUP_DELETE() {
    LINE " > deleting host symlink and vendor backup"
    if rm "./${HOST}_backup"
    then
        if rm -rf "./${C_FOLDER}/vendor_backup"
        then
            echo "deleted"
        fi
    fi
}

# recovers backup
BACKUP_RECOVER() {
    LINE " > recovering host symlink and vendor from backup"
    if [[ -d "./${C_FOLDER}/vendor" ]]; then
        rm -rf "./${C_FOLDER}/vendor"
    fi
    if cp -a "./${C_FOLDER}/vendor_backup" "./${C_FOLDER}/vendor"
    then
        if cp -a "./${HOST}_backup" "./${HOST}"
        then
            echo "recovered"
        fi
    fi
}

# switches production releases
SWITCH() {
    if [[ ! -h "./${HOST}" ]]; then
        LINE " > symlinking ${HOST} to release $1"
        SYMLINK_RELEASE "$1"
        if [[ $? -eq 1 ]]; then
            return 1
        fi
    else
        BACKUP_CREATE
        if [[ $? -eq 1 ]]; then
            LINE " > switching to release $1"
            if rm "./${HOST}"
            then
                SYMLINK_RELEASE "$1"
                if [[ $? -eq 1 ]]; then
                    BACKUP_DELETE
                    return 1
                else
                    BACKUP_RECOVER
                fi
            fi
            BACKUP_DELETE
        fi
    fi
    return 0
}

# moves next development release to current
MOVEDEV() {
    if [[ -d "./${R_FOLDER}/${DC_FOLDER}" ]]; then
        LINE " > removing old current development release"
        if rm -rf "./${R_FOLDER}/${DC_FOLDER}"
        then
            echo "done"
        else
            return 0
        fi
    fi
    LINE " > moving next development release to current"
    if cp -a "./${R_FOLDER}/${DN_FOLDER}" "./${R_FOLDER}/${DC_FOLDER}"
    then
        echo "done"
        rm -rf "./${R_FOLDER}/${DN_FOLDER}"
    else
        return 0
    fi
    return 1
}

# deploys tag
DEPLOY() {
    echo "STARTING deployment of ${PROJECT} version ${VERSION} at $(date +"%r")."
    INIT_RELEASE_FOLDER "$VERSION"
    if [[ $? -eq 1 ]]; then
        DOWNLOAD_PROD_RELEASE "$VERSION"
        if [[ $? -eq 1 ]]; then
            CHECK_VENDOR "$VERSION"
            if [[ $? -eq 1 ]]; then
                SYMLINK "$VERSION"
                if [[ $? -eq 1 ]]; then
                    INIT "$VERSION"
                    if [[ $? -eq 1 ]]; then
                        SWITCH "$VERSION"
                    fi
                fi
            fi
        fi
    fi
    END_MARKER
}

# rollbacks tag
ROLLBACK() {
    echo "STARTING rollback of ${PROJECT} to version ${VERSION} at $(date +"%r")."
    CHECK_RELEASE_FOLDER "$VERSION"
    if [[ $? -eq 1 ]]; then
        CHECK_VENDOR "$VERSION"
        if [[ $? -eq 1 ]]; then
            SYMLINK "$VERSION"
            if [[ $? -eq 1 ]]; then
                SWITCH "$VERSION"
            fi
        fi
    fi
    END_MARKER
}

# deploys development
DEPLOYDEV() {
    echo "STARTING deployment of ${PROJECT} development version at $(date +"%r")."
    INIT_DEVELOPMENT_FOLDER
    if [[ $? -eq 1 ]]; then
        DOWNLOAD_DEV_RELEASE
        if [[ $? -eq 1 ]]; then
            CHECK_VENDOR "$DN_FOLDER"
            if [[ $? -eq 1 ]]; then
                MOVEDEV
                if [[ $? -eq 1 ]]; then
                    SYMLINK "$DC_FOLDER"
                    if [[ $? -eq 1 ]]; then
                        INIT "$DC_FOLDER"
                        if [[ $? -eq 1 ]]; then
                            SWITCH "$DC_FOLDER"
                        fi
                    fi
                fi
            fi
        fi
    fi
    END_MARKER
}

# starts script
START() {
    if [[ $MODE -eq 1 ]]; then
        echo "NAME"
        echo ""
        echo "    deployer.sh - deploy SVN version of Yii 2 project"
        echo ""
        echo "SYNOPSIS"
        echo ""
        echo "    deployer.sh -d TAG [-v] [-n] [-e ENV]"
        echo "    deployer.sh -r TAG [-v] [-n] [-e ENV]"
        echo "    deployer.sh -dev [-v] [-n] [-e ENV]"
        echo "    deployer.sh -h"
        echo ""
        echo "DESCRIPTION"
        echo ""
        echo "    Deploys the target TAG version of Yii 2 project or rollbacks to the target TAG version."
        echo "    Creates the releases and composer folders. Deployed version is stored in the releases"
        echo "    folder under the TAG name. Composer folder stores the vendor folder with composer "
        echo "    dependencies. TAG version is SVN imported using provided SVN credentials."
        echo "    Deployed or rollbacked version is symlinked to the Apache host target folder."
        echo ""
        echo "    -d TAG, --deploy TAG"
        echo "        deploy TAG version"
        echo ""
        echo "    -r TAG, --rollback TAG"
        echo "        rollback to TAG version"
        echo ""
        echo "    -dev"
        echo "        deploy development version"
        echo ""
        echo "    -v, --verbose"
        echo "        runs the script in verbose mode where output of svn, composer and init is visible"
        echo ""
        echo "    -n, --noupdate"
        echo "        skips composer update part (composer install ignores this option)"
        echo ""
        echo "    -e ENV, --env ENV"
        echo "        sets environment name ENV for init"
        echo ""
        echo "    -h, --help"
        echo "        this information (ignores other options)"
        echo ""
        echo "AUTHOR"
        echo ""
        echo "    Pawel Brzozowski"
        echo ""
        echo "COPYRIGHT"
        echo ""
        echo "    Copyright (c) 2016 Human Device Sp. z o.o."
        echo ""
    elif [[ $MODE -eq 2 ]]; then
        if [[ "$VERSION" = "" ]]; then
            echo "    Version tag missing."
            echo "    For help run"
            echo "        deployer.sh -h"
        else
            DEPLOY "$VERSION"
        fi
    elif [[ $MODE -eq 3 ]]; then
        if [[ "$VERSION" = "" ]]; then
            echo "    Version tag missing."
            echo "    For help run"
            echo "        deployer.sh -h"
        else
            ROLLBACK "$VERSION"
        fi
    elif [[ $MODE -eq 4 ]]; then
        echo "    You can not run deploy, rollback and development deploy at the same time."
        echo "    For help run"
        echo "        deployer.sh -h"
    elif [[ $MODE -eq 5 ]]; then
        DEPLOYDEV
    elif [[ $MODE -eq 6 ]]; then
        echo "    Unrecognised option."
        echo "    For help run"
        echo "        deployer.sh -h"
    else
        echo "    Yii 2 project deployer."
        echo "    For help run"
        echo "        deployer.sh -h"
    fi
}

while [[ $# > 0 ]]
do
    case $1 in
        -h|--help)
            MODE=1
            break
            ;;
        -v|--verbose)
            VERBOSE=1
            ;;
        -n|--noupdate)
            COMPOSER_DONT_UPDATE=1
            ;;
        -e|--env)
            ENV="${2##*/}"
            shift
            ;;
        -dev)
            MODE=5
            ;;
        -d|--deploy)
            if [[ $MODE -eq 5 ]]; then
                MODE=4
            elif [[ $MODE -eq 3 ]]; then
                MODE=4
            else
                MODE=2
            fi
            VERSION="${2##*/}"
            shift
            ;;
        -r|--rollback)
            if [[ $MODE -eq 5 ]]; then
                MODE=4
            elif [[ $MODE -eq 2 ]]; then
                MODE=4
            else
                MODE=3
            fi
            VERSION="${2##*/}"
            shift
            ;;
        *)
            MODE=6
            break
            ;;
    esac
    shift
done

START
