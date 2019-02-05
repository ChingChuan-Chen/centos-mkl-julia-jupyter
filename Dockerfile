FROM centos:7

ENV TZ=Asia/Taipei \
  JULIA_VER=1.0.3 \
  PYTHON_VER=3.5.6 \
  CMAKE_VER=3.13.3 \
  MAX_PROCS=8

# setup timezone, install cjk fonts, mkl and deps of Julia
## libatomic m4 bzip2 which patch make gcc gcc-c++ gcc-gfortran for julia
## arpack libgfortran5 openblas openblas-serial64_ for Arpack.jl
## sqlite-devel for python 3
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
  yum install -y wget epel-release && \
  yum install -y google-noto-cjk-fonts adobe-source-han-sans-twhk-fonts && \
  yum-config-manager --add-repo https://yum.repos.intel.com/setup/intelproducts.repo && \
  rm -rf /var/cache/yum/ && yes | yum makecache fast && \
  yum install -y intel-mkl-64bit && \
  # register mkl-related so files to system
  echo "/opt/intel/mkl/lib/intel64" >> /etc/ld.so.conf.d/intel.conf && ldconfig && \
  yum install -y readline-devel libssh2-devel openssl-devel libcurl-devel \
    file which patch libatomic m4 bzip2 make gcc gcc-c++ gcc-gfortran \
    arpack libgfortran5 openblas openblas-serial64_ \
    java-1.8.0-openjdk-devel cmake3 sqlite-devel git && \
  ln -snf /usr/bin/cmake3 /usr/bin/cmake

# compile Julia
WORKDIR /julia-build
RUN git clone https://github.com/JuliaLang/julia.git && \
  cd julia && git checkout v${JULIA_VER} && \
  printf "USE_INTEL_MKL = 1\n\
MKLROOT = /opt/intel/mkl\n\
prefix=/usr/local/lib/julia" > Make.user && \
  # copy all so files of MKL
  mkdir -p usr/lib/julia && \
  cp /opt/intel/lib/intel64/*.so usr/lib/julia/ && \
  cp /opt/intel/mkl/lib/intel64/*.so usr/lib/julia/ && \
  # avoid insufficient memory
  export MAKE_PROC=$(($(nproc)>${MAX_PROCS}?${MAX_PROCS}:$(nproc))) && \
  make -j${MAKE_PROC} && make install && \
  # register julia so files to system
  echo "/usr/local/lib/julia/lib" >> /etc/ld.so.conf.d/julia.conf && ldconfig && \
  # link julia executables
  ln -snf /usr/local/lib/julia/bin/julia /usr/local/bin/julia-${JULIA_VER} && \
  ln -snf /usr/local/bin/julia-${JULIA_VER} /usr/local/bin/julia && \
  cd / && rm -rf /julia-build

# install python 3 and jupyter notebook
WORKDIR /python-build
RUN wget -q https://www.python.org/ftp/python/${PYTHON_VER}/Python-${PYTHON_VER}.tar.xz && \
  tar Jxf Python-${PYTHON_VER}.tar.xz && cd Python-${PYTHON_VER} && \
  # CXX will not be found by Python make
  export CXX=g++ && \
  ./configure --enable-shared --enable-optimizations --with-wide-unicode --enable-loadable-sqlite-extensions && \
  make -j${nproc} && make altinstall && \
  # register python-related so files to system
  echo "/usr/local/lib" >> /etc/ld.so.conf.d/python3.conf && ldconfig && \
  # clean up
  cd / && rm -rf /python-build && \
  # upgrade pip and setuptools
  pip3.5 install pip setuptools --upgrade && \
  # install jupyterlab
  pip3.5 install jupyter jupyterlab ipyparallel && \
  ipcluster nbextension enable && \
  # generate config file of jupyterlab
  JUPYTER_CONF_FILE=/root/.jupyter/jupyter_notebook_config.py && \
  /usr/local/bin/jupyter notebook --generate-config && \
  sed -i -e "s/#c.NotebookApp.ip =.*/c.NotebookApp.ip = '0.0.0.0'/g" $JUPYTER_CONF_FILE && \
  sed -i -e "s/#c.NotebookApp.port =.*/c.NotebookApp.port = 8888/g" /$JUPYTER_CONF_FILE && \
  sed -i -e "s/#c.NotebookApp.open_browser =.*/c.NotebookApp.open_browser = False/g" $JUPYTER_CONF_FILE && \
  cd / && rm -rf /python-build

# install julia packages
WORKDIR /jupyter
RUN JUPYTER=$(which jupyter) julia -e 'import Pkg; Pkg.update()' && \
  JUPYTER=$(which jupyter) julia -e 'using Pkg; pkg"add Gadfly RDatasets IJulia DataFrames Lazy \
    DataFramesMeta IterTools Distributions StatsModels GLM Clustering"; pkg"precompile"' && \
  git clone https://github.com/JuliaComputing/JuliaBoxTutorials.git

COPY docker-entrypoint.sh /jupyterlab/docker-entrypoint.sh
EXPOSE 8888
ENTRYPOINT ["/jupyterlab/docker-entrypoint.sh"]
CMD ["/usr/local/bin/jupyter", "lab", "--allow-root"]

