#!/bin/sh -e

if [ -z "${CRONFIG}" ]; then
    echo "No config specified"
    exit 1
fi

command="/opt/scripts/backup.job.sh ${@} > /proc/1/fd/1 2>&1"

echo "Job to be executed : ${command}"
# Configure the job
crontab -l | { cat; echo "${CRONFIG} ${command}"; } | crontab -
# Run the job
crond -l 2 -f