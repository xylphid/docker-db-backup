from docker:19.03.2

ARG VERSION
ENV VERSION ${VERSION:-"nightly"}

LABEL maintainer.name="Anthony PERIQUET"
LABEL maintainer.email="anthony@periquet.net"
LABEL version=${VERSION}
LABEL description="Database backup automation"

ENV CRONFIG "0 23 * * *"

ADD scripts /opt/scripts/

VOLUME /opt/backups/
WORKDIR /opt/backups/

ENTRYPOINT [ "/opt/scripts/configure.sh" ]