FROM    alpine:latest

ENV     DANTE_VER 1.4.2

ENV     DANTE_URL https://www.inet.no/dante/files/dante-$DANTE_VER.tar.gz

ENV     DANTE_SHA 4c97cff23e5c9b00ca1ec8a95ab22972813921d7fbf60fc453e3e06382fc38a7

RUN     apk add --no-cache --virtual .build-deps \
            build-base \
            curl \
            linux-pam-dev && \
        install -v -d /src && \
        curl -sSL $DANTE_URL -o /src/dante.tar.gz && \
        echo "$DANTE_SHA */src/dante.tar.gz" | sha256sum -c && \
        tar -C /src -vxzf /src/dante.tar.gz && \
        cd /src/dante-$DANTE_VER && \
        # https://lists.alpinelinux.org/alpine-devel/3932.html
        ac_cv_func_sched_setscheduler=no ./configure --without-krb5 --without-ldap --without-upnp --with-pam && \
        make -j install && \
        cd / && rm -r /src && \
        apk add --no-cache \
            linux-pam

RUN \
  mkdir /pam && \
  cd pam && \
  curl -sSL https://github.com/prapdm/libpam-pwdfile/archive/v1.0.tar.gz | tar xz --strip 1 && \
  make install && \
  cd .. && \
  rm -rvf pam && \
  apk del .build-deps && \
  rm -rvf /var/cache/apk/* && \
  rm -rvf /tmp/* && \
  rm -rvf /src  && \
  rm -rvf /var/log/*

RUN     echo "auth required pam_pwdfile.so pwdfile /sockd.passwd" > /etc/pam.d/sockd
RUN     echo "account required pam_permit.so" >> /etc/pam.d/sockd

EXPOSE  1080

CMD     ["sockd"]
