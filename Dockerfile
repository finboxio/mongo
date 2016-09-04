FROM ubuntu:14.04

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927 && \
    echo "deb http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.2.list && \
    apt-get update && apt-get install -y --force-yes --no-install-recommends ca-certificates curl wget mongodb-org python xfsprogs logrotate && \
    curl -L -o /usr/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 && \
    chmod +x /usr/bin/jq && \
    curl -O https://bootstrap.pypa.io/get-pip.py && \
    python get-pip.py && \
    pip install awscli --ignore-installed six && \
    curl -L -o /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.7/gosu-$(dpkg --print-architecture)" && \
    curl -L -o /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/1.7/gosu-$(dpkg --print-architecture).asc" && \
    export GNUPGHOME="$(mktemp -d)" && \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 && \
    gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu && \
    rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc && \
    chmod +x /usr/local/bin/gosu && \
    gosu nobody true && \
    curl -sSL https://cloud.mongodb.com/download/agent/monitoring/mongodb-mms-monitoring-agent_latest_amd64.deb -o mms.deb && \
    dpkg -i mms.deb && \
    rm mms.deb && \
    curl -L -o /usr/bin/slack https://gist.githubusercontent.com/bdentino/6f6f91960e239e158f84d6bfe08cfd1d/raw/d1a387c6c568cff1f5169e158a3dfc15bdd1a9b7/slack-bash && \
    chmod +x /usr/bin/slack && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV DISABLE_THP=true \
    MONGO_HOST=localhost \
    MONGO_PORT=27017 \
    MONGO_STORAGE_ENGINE=wiredTiger \
    MONGO_DIR=/ebs/mongo \
    MONGO_USER= \
    MONGO_PASSWORD= \
    MONGO_DATABASE= \
    MONGO_REPLSET= \
    MONGO_ROLE= \
    MONGO_PRIMARY= \
    MONGO_KEYFILE= \
    MMS_USER= \
    MMS_PASSWORD= \
    MMS_SERVER=https://mms.mongodb.com \
    MMS_API_KEY= \
    MMS_MUNIN=false \
    MMS_CHECK_SSL_CERTS=false \
    EBS_VOLUME_NAME= \
    EBS_VOLUME_SIZE= \
    EBS_VOLUME_TYPE=gp2 \
    EBS_VOLUME_IOPS= \
    BACKUP_NAME= \
    BACKUP_MAX_DAYS= \
    BACKUP_MIN_COUNT=

VOLUME /host/dev \
       /ebs

ADD mongo-* /usr/bin/

ENTRYPOINT /usr/bin/mongo-bootstrap
