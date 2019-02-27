#!/bin/sh

today=$(date +%F)
filter=""

while getopts p: param
do
    case $param in
        p)      filter.="${filter} --filter 'name=${OPTARG}'";;
        [?])    print >2 "Usage: $0 [-p database-pattern]..."
    esac
done
# echo ${filter:-"--filter 'name=database'"}

# databases=$(docker ps \
#     --format '{{.Names}}:{{.Image}}' \
#     --filter "name=database" \
#     --filter "name=psql")
# databases=$(docker ps \
#     --format '{{.Names}}:{{.Image}}' \
#     ${filter:-"--filter 'name=database'"})
filterCommand="docker ps --format '{{.Names}}:{{.Image}}' ${filter:-"--filter 'name=database'"})"
databases=$(eval $filterCommand)

for database in $databases
do
    container=$(echo $database | cut -d: -f1)
    dbType==$(echo $database | cut -d: -f2)
    #stack=$(echo $container | cut -d. -f1 | cut -d_ -f1)
    stack=$(docker inspect --format '{{index .Config.Labels "com.docker.stack.namespace"}}')

    case $dbType in
        mysql)
            command='mysqldump -u ${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE}'
            ;;
        postgres)
            command='pg_dump -U ${POSTGRES_USER} ${POSTGRES_DB}';
            ;;
    esac

    backup="mkdir -p ${stack} && docker exec ${container} sh -c '${command}' > ${stack}/${today}.sql"
    echo backup
done

exit 0