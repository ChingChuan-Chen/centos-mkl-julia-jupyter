#!/usr/bin/env bash
set -e
JUPYTER_CONF_FILE=/root/.jupyter/jupyter_notebook_config.py
if [ ! -z "${PASSWORD}" ]; then
  sha_password=$(python3.5 -c "from notebook.auth import passwd; print(passwd('${PASSWORD}'))")
  sed -i -e "s/#c.NotebookApp.password =.*/c.NotebookApp.password = u'${sha_password}'/g" $JUPYTER_CONF_FILE
fi

if [ ! -z "${USE_HTTPS}" -a "${USE_HTTPS}" = "yes" ]; then
  mkdir -p /root/.jupyter/ssl
  tee /root/.jupyter/ssl/opsnssl.cnf << EOF
[req]
distinguished_name = req_distinguished_name
[req_distinguished_name]
EOF
  if [ ! -x "$(command -v openssl)" ]; then
    yum install -y openssl
  fi
  PEM_FILE=/root/.jupyter/ssl/notebook.pem
  openssl req -config /root/.jupyter/ssl/opsnssl.cnf -new -newkey rsa:2048 \
    -days 3650 -nodes -x509 -subj '/C=XX/ST=XX/L=XX/O=generated/CN=generated' \
    -keyout ${PEM_FILE} -out ${PEM_FILE}
  sed -i -e "s~#c.NotebookApp.certfile =.*~c.NotebookApp.certfile = u'${PEM_FILE}'~g" $JUPYTER_CONF_FILE
fi

exec "$@"

