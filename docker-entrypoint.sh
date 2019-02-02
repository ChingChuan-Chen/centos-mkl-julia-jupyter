#!/usr/bin/env bash
set -e
if [ ! -z "$PASSWORD" ]; then
  customized_password=$(python3.5 -c "from notebook.auth import passwd; print(passwd('${PASSWORD}'))")
  sed -i -e "s/# c.NotebookApp.password.*/c.NotebookApp.password = '#{customized_password}'/g" /root/.jupyter/jupyter_notebook_config.py
fi

exec "$@"
