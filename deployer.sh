#!/bin/bash
# Human Device Yii 2 deployer
# ========================================================
# -h, --help for help
# -d, --deploy for deployment
# -dv, --deployverbose (verbose)
# -r, --rollback for rollback
# -rv, --rollbackverbose (verbose)

# SETTINGS
# ========================================================

# project host folder name
HOST="change me"

# environment name for init
ENV="Development"

# SVN credentials
SVN_URL="change me"
SVN_USER="change me"
SVN_PASS="change me"

# project name
PROJECT="change me"

# releases folder name
R_FOLDER="releases"

# composer folder name for vendor storage
C_FOLDER="composer"

# temporary composer folder name for vendor storage
C_TEMP_FOLDER="composer_temp"

# script flags
# ========================================================
KNOWN_PARAMS=0
VERBOSE=0
USING_TEMPORARY_COMPOSER=0

LINE() {
    local LINE=$(printf '%0.1s' "."{1..60})
    printf "%s%s" "$1" "${LINE:${#1}}"
}

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

CREATE_FOLDER() {
    LINE "$1"
    if mkdir "$2"
    then
        chmod 0775 "$2"
        echo "created"
        return 1
    fi
    return 0
}

CHECK_RELEASE_FOLDER() {
    if [[ ! -d "./${R_FOLDER}"  ]]; then
        CREATE_FOLDER " > initialing releases folder" "./${R_FOLDER}"
        if [[ $? -eq 0 ]]; then
            return 0
        fi
    fi
    LINE " > checking deployed release folder"
    if [[ -d "./${R_FOLDER}/$1" ]]; then
        echo "ALREADY EXISTS! > exit with error"
    else
        echo "ok"
        return 1
    fi
    return 0
}

DOWNLOAD_RELEASE() {
    LINE " > downloading SVN snapshot"
    local CMD="svn --non-interactive --username "${SVN_USER}" --password "${SVN_PASS}" export -q "${SVN_URL}/tags/${1}" "./${R_FOLDER}/${1}""
    if [[ $VERBOSE -eq 1 ]]; then
        CMD="svn --non-interactive --username "${SVN_USER}" --password "${SVN_PASS}" export "${SVN_URL}/tags/${1}" "./${R_FOLDER}/${1}""
    fi
    if eval "$CMD"
    then
        echo "downloaded"
        return 1
    fi
    return 0
}

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

CHECK_VENDOR() {
    if [[ ! -d "./${C_FOLDER}" ]]; then
        CREATE_FOLDER " > creating composer folder" "./${C_FOLDER}"
        if [[ $? -eq 0 ]]; then
            return 0
        fi
    fi
    LINE " > checking deployed release composer.json"
    if [[ ! -e "./${R_FOLDER}/$1/composer.json" ]]; then
        echo "NO COMPOSER.JSON FOUND! > exit with error"
        return 0
    else
        echo "ok"
    fi
    if [[ ! -e "./${C_FOLDER}/composer.json" ]]; then
        LINE " > copying composer.json from deployed release folder"
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
            return 1
        else
            echo "different"
            CREATE_FOLDER " > creating temporary composer folder" "./${C_TEMP_FOLDER}"
            if [[ $? -eq 0 ]]; then
                return 0
            fi
            USING_TEMPORARY_COMPOSER=1
            LINE " > copying composer.json from deployed release folder"
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

SYMLINK() {
    LINE " > symlinking vendor folder to deployed release"
    local CMD="ln -s "./../../${C_FOLDER}/vendor" "./${R_FOLDER}/${1}/vendor""
    if [[ $USING_TEMPORARY_COMPOSER -eq 1 ]]; then
        CMD="ln -s "./../../${C_TEMP_FOLDER}/vendor" "./${R_FOLDER}/${1}/vendor""
    fi
    if eval "$CMD"
    then
        echo "done"
        return 1
    fi
    return 0
}

INIT() {
    LINE " > running Yii 2 init for ${ENV}"
    local CMD="php "./${R_FOLDER}/${1}/init" --env=${ENV} --overwrite=All >/dev/null"
    if [[ $VERBOSE -eq 1 ]]; then
        CMD="php "./${R_FOLDER}/${1}/init" --env=${ENV} --overwrite=All"
    fi
    if eval "$CMD"
    then
        echo "done"
        return 1
    fi
    return 0
}

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

SWITCH() {
    if [[ ! -h "./${HOST}" ]]; then
        LINE " > symlinking ${HOST} to deployed release"
        SYMLINK_RELEASE "$1"
        if [[ $? -eq 1 ]]; then
            return 1
        fi
    else
        BACKUP_CREATE
        if [[ $? -eq 1 ]]; then
            LINE " > switching to deployed release"
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

DEPLOY() {
    local VERSION="${1##*/}"
    echo "STARTING deployment of ${PROJECT} version ${VERSION} at $(date +"%r")."
    CHECK_RELEASE_FOLDER "$VERSION"
    if [[ $? -eq 1 ]]; then
        DOWNLOAD_RELEASE "$VERSION"
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

ROLLBACK() {
    local VERSION="${1##*/}"
    echo "STARTING rollback of ${PROJECT} to version ${VERSION} at $(date +"%r")."
    END_MARKER
}

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    KNOWN_PARAMS=1
    echo "deploy SVN tagged version (quiet):"
    echo "    ./deployer.sh -d tag"
    echo "    -d, --deploy"
    echo "deploy SVN tagged version (verbose):"
    echo "    ./deployer.sh -dv tag"
    echo "    -dv, --deployverbose"
    echo "rollback to the previously deployed version (quiet):"
    echo "    ./deployer.sh -r tag"
    echo "    -r, --rollback"
    echo "rollback to the previously deployed version (verbose):"
    echo "    ./deployer.sh -rv tag"
    echo "    -rv, --rollbackverbose"
elif [[ $# -eq 2 ]]; then
    case $1 in
        -d|--deploy)
            KNOWN_PARAMS=1
            DEPLOY "$2"
            ;;
        -dv|--deployverbose)
            KNOWN_PARAMS=1
            VERBOSE=1
            DEPLOY "$2"
            ;;
        -r|--rollback)
            KNOWN_PARAMS=1
            ROLLBACK "$2"
            ;;
        -rv|--rollbackverbose)
            KNOWN_PARAMS=1
            VERBOSE=1
            ROLLBACK "$2"
            ;;
    esac
fi

[ $KNOWN_PARAMS -eq 1 ] || echo "run ./deployer.sh -h or ./deployer.sh --help to get help"
