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
echo " Working directory : $(workdir)"
echo -e "=========================\n"

cd /opt/backups/
filterCommand="docker ps --format '{{.Names}}:{{.Image}}' ${filter:-"--filter 'name=database'"}"
databases=$(eval $filterCommand)

for database in $databases
do
    container=$(echo $database | cut -d: -f1)
    dbType=$(echo $database | cut -d: -f2)
    #stack=$(echo $container | cut -d. -f1 | cut -d_ -f1)
    project=$(docker inspect --format '{{index .Config.Labels "com.docker.compose.project"}}' ${container})
    namespace=$(docker inspect --format '{{index .Config.Labels "com.docker.stack.namespace"}}' ${container})
    stack=${project:-${namespace}}

    case $dbType in
        mysql)
            command='mysqldump -u ${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE}'
            ;;
        postgres)
            command='pg_dump -U ${POSTGRES_USER} ${POSTGRES_DB}';
            ;;
        *)  continue;;
    esac

    backup="mkdir -p ${stack} && docker exec ${container} sh -c '${command}' > ${stack}/${today}.sql"
    echo -n "- [${dbType}] ${stack} : "
    eval ${backup}
    echo "done"
done

echo
echo -e "! Backup terminated\n\n"

exit 0

# docker ps \
#     --format '{{.Names}}\t{{.Image}}' \
#     --filter "name=database" \
#     --filter "name=psql" \
# | awk '{
#     # Prepare backup command according to the current engine
#     if ($2 ~ /mysql/) command="mysqldump -u ${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE}";
#     else if ($2 ~ /postgres/) command="pg_dump -U ${POSTGRES_USER} ${POSTGRES_DB}";

#     "date +%F" | getline today
#     # Get the stack name
#     inspect="docker inspect --format '\''{{index .Config.Labels \"com.docker.stack.namespace\"}}'\'' " $1;
#     inspect | getline stack
    
#     backup="docker exec " $1 " sh -c '\''" command "'\'' > " stack "/" today ".sql";
#     print $1 " sh -c '\''" command "'\'' > " stack "/" today ".sql";
# }' \
# | xargs --no-run-if-empty docker exec