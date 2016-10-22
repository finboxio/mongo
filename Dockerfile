FROM mongo:3.2

RUN apt-get update && \
    apt-get install -y jq curl logrotate && \
    curl -sSL https://cloud.mongodb.com/download/agent/monitoring/mongodb-mms-monitoring-agent_latest_amd64.deb -o mms.deb && \
    dpkg -i mms.deb && \
    rm mms.deb && \
    apt-get remove --purge -y curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /etc/mongo-conf
ADD bin /opt/mongo-conf/bin

ENTRYPOINT /opt/mongo-conf/bin/entrypoint.sh
