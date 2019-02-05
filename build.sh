#!/usr/bin/env bash
set -e
docker build -t jamal0230/centos-mkl-julia-jupyter:1.0.3 .
docker push jamal0230/centos-mkl-julia-jupyter:1.0.3
docker tag jamal0230/centos-mkl-julia-jupyter:1.0.3 jamal0230/centos-mkl-julia-jupyter:latest
docker push jamal0230/centos-mkl-julia-jupyter:latest
