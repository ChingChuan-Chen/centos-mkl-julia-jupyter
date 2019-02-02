# Dockerfile

A docker of Jupyter lab with MKL-built julia and Python 3.5.5 based CentOS 7 and devtoolset-7.

[Docker Hub](https://hub.docker.com/r/jamal0230/centos-mkl-julia-jupyter/)

# Run
1. use `password` to login jupyter notebook with default port 8888
```
docker run -d -p 8888:8888 --name julia jamal0230/centos-mkl-julia-jupyter:1.0.3
```

2. use customized password  to login jupyter notebook with default port 8888
```
docker run -d -p 8888 :8888 -e PASSWORD=<password> --name julia jamal0230/centos-mkl-julia-jupyter:1.0.3
```
