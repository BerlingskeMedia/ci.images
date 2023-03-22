FROM alpine

RUN apk add --no-cache \
        python3 \
        py3-pip \
        bash \
        jq \
    && pip3 install --upgrade pip \
    && pip3 install --no-cache-dir \
        awscli \
    && rm -rf /var/cache/apk/*
RUN aws --version   # Just to make sure its installed alright

COPY run.sh /

ENTRYPOINT ["/run.sh"]
