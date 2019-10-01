#!/bin/sh

today=$(date +%F)
workdir="/opt/backups/"
filter=""

while getopts p: param
do
    case $param in
        p)      filter="${filter} --filter 'name=${OPTARG}'";;
        [?])    print >2 "Usage: $0 [-p database-pattern]...";;
    esac
done

echo "========================="
echo " Starting DB-Backup"
echo " Initialized at ${today}"
echo " Working directory : ${workdir}"
echo -e "=========================\n"

cd /opt/backups/
filterCommand="docker ps --format '{{.Names}}:{{.Image}}' ${filter:-"--filter 'name=database'"}"
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
            command='mongodump --archive';
            ;;
        mysql)
            command='mysqldump -u ${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE}'
            ;;
        postgres)
            command='pg_dump -U ${POSTGRES_USER} ${POSTGRES_DB}';
            ;;
        *)  continue;;
    esac

    backup="mkdir -p ${stack} && docker exec ${container} sh -c '${command}' > ${stack}/${today}.sql"
    clean="ls -r ${stack} | tail -n +14 | grep -v '01.sql' | xargs --no-run-if-empty rm "
    echo -n "- [${dbType}] ${stack} : "
    eval ${backup}
    eval ${clean}
    echo "done"
done

echo
echo -e "! Backup terminated\n\n"

exit 0