FROM alpine:3.23.3 AS app

# Install your software in this build stage.
# It will be shared with the local and final images.

COPY --chmod=755 test_script.sh /usr/local/bin/

#=================================================================================================
FROM app AS final

# RCP CaaS requirements to access storage
ARG LDAP_USERNAME
ARG LDAP_UID
ARG LDAP_GROUPNAME
ARG LDAP_GID

# The following works on Alpine Linux. On Ubuntu or Debian, use
# RUN groupadd ${LDAP_GROUPNAME} --gid ${LDAP_GID} \
#   && useradd -m -s /bin/bash -g ${LDAP_GROUPNAME} -u ${LDAP_UID} ${LDAP_USERNAME} \
#   && mkdir -p /home/${LDAP_USERNAME} \
#   && chown -R ${LDAP_USERNAME}:${LDAP_GROUPNAME} /home/${LDAP_USERNAME}

RUN addgroup -g ${LDAP_GID} ${LDAP_GROUPNAME} \
  && adduser -D -s /bin/sh -G ${LDAP_GROUPNAME} -u ${LDAP_UID} ${LDAP_USERNAME} \
  && mkdir -p /scratch \
  && chown -R ${LDAP_USERNAME}:${LDAP_GROUPNAME} /scratch

USER ${LDAP_USERNAME}
WORKDIR /home/${LDAP_USERNAME}

CMD ["test_script.sh"]
