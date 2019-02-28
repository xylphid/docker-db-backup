from docker:18.09.2

ENV VERSION "2018.02.26"

LABEL maintainer.name="Anthony PERIQUET"
LABEL maintainer.email="anthony@periquet.net"
LABEL version=${VERSION}
LABEL description="Database backup automation"

ENV CRONFIG "0 23 * * *"

#ADD scripts/backup.job.sh /usr/local/bin
ADD scripts /opt/scripts/

# RUN chmod +x /usr/local/bin/backup.job.sh && \
#     ln -s usr/local/bin/backup.job.sh /backup.job.sh # backwards compat

VOLUME /opt/backups/
WORKDIR /opt/backups/

ENTRYPOINT [ "/opt/scripts/configure.sh" ]