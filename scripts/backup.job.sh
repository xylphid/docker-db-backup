#!/bin/sh

# Get container env
#   get_env "ENV_NAME"
get_env() {
    echo $(docker exec ${container} env | grep $1 | cut -d'=' -f2)
}

# Build mysql backup command
get_mysql_command() {
    MYSQL_RANDOM_ROOT_PASSWORD=$(get_env "MYSQL_RANDOM_ROOT_PASSWORD")
    if [[ "${MYSQL_RANDOM_ROOT_PASSWORD}" != "yes" ]]; then
        user='root'
        password=$(get_env "MYSQL_ROOT_PASSWORD_FILE")
        if [[ "${password}" != "" ]]; then
            password="\$(cat ${password})"
        else
            password=$(get_env "MYSQL_ROOT_PASSWORD")
        fi
    else
        user=$(get_env "MYSQL_USER")
        password=$(get_env "MYSQL_PASSWORD")
    fi

    database=$(get_env "MYSQL_DATABASE")
    if [[ "${database}" == "" ]]; then
        database="--all-databases"
    fi

    echo "export MYSQL_PWD=${password}; mysqldump --max-allowed-packet=512M -u ${user} ${database}"
}

# Build postgresql backup command
get_psql_command() {
    user=$(get_env "POSTGRES_USER")
    if [[ "${user}" == "" ]]; then
        user="postgres"
    fi

    database=$(get_env "POSTGRES_DB")
    if [[ "${database}" == "" ]]; then
        echo "pg_dumpall -U ${user}"
    else
        echo "pg_dump -U ${user} ${database}"
    fi
}

today=$(date +%F)
workdir="/opt/backups/"
filter=""

while getopts f: param
do
    case $param in
        f)      filter="${filter}|${OPTARG}'";;
        [?])    print >2 "Usage: $0 [-f image-pattern]...";;
    esac
done
filter=$(echo "${filter}" | sed "s/^|//")

echo "========================="
echo " Starting DB-Backup"
echo " Initialized at ${today}"
echo " Working directory : ${workdir}"
echo -e "=========================\n"

cd /opt/backups/
filterCommand="docker ps --format '{{.Names}}:{{.Image}}' | awk '/${filter:-"mariadb|mongo|mysql|postgres"}/{print \$1}'"
databases=$(eval $filterCommand)

for database in $databases
do
    container=$(echo $database | cut -d: -f1)
    dbType=$(echo $database | cut -d: -f2)
    project=$(docker inspect --format '{{index .Config.Labels "com.docker.compose.project"}}' ${container})
    namespace=$(docker inspect --format '{{index .Config.Labels "com.docker.stack.namespace"}}' ${container})
    stack=${project:-${namespace}}

    case $dbType in
        mongo)
            command='mongodump --quiet --archive';
            ;;
        mysql | mariadb)
            command=$(get_mysql_command)
            ;;
        postgres)
            command=$(get_psql_command)
            ;;
        *)  continue;;
    esac

    backup="mkdir -p ${stack} \
        && docker exec ${container} sh -c '${command}' > ${stack}/${today}.raw \
        && tar cfz ${stack}/${today}.tar.gz ${stack}/${today}.raw \
        && rm ${stack}/${today}.raw"
    clean="ls -r ${stack} | tail -n +14 | grep -v '01.tar.gz' | sed -e 's/^/${stack}\//' | xargs --no-run-if-empty rm "
    echo -n "- [${dbType}] ${stack} : "
    eval ${backup}
    eval ${clean}
    echo "done"
done

echo
echo -e "! Backup terminated\n\n"

exit 0