FROM ubuntu:22.04 AS builder

ENV MAMBA_ROOT_PREFIX=/opt/conda
ENV MAMBA_DISABLE_LOCKFILE=TRUE

COPY environment.yaml /tmp
COPY install_aapp8.sh /tmp
COPY install_aapp8.patch /tmp
RUN mkdir /tmp/tarfiles
COPY AAPP_8.12.tgz /tmp/tarfiles
COPY kai_1_12_e8b74685d1.zip /tmp/tarfiles

RUN apt update && \
    apt -y upgrade && \
    apt -y install patch tar gzip gcc-9 make m4 cmake bash ksh cpp-9 g++-9 gfortran-9 perl wget unzip bzip2 curl libxml2 libxml2-dev && \
    apt -y clean

# Force usage of older compiler versions
RUN ln -s /usr/bin/gfortran-9 /usr/bin/gfortran
RUN ln -s /usr/bin/g++-9 /usr/bin/g++
RUN rm /usr/bin/gcc && ln -s /usr/bin/gcc-9 /usr/bin/gcc

# Patch the original installation script
RUN cd /tmp && \
    chmod +x install_aapp8.sh && \
    patch install_aapp8.sh install_aapp8.patch
# Install HDF5
RUN cd /tmp && \
    ./install_aapp8.sh 1
# Install BUFRDC
RUN cd /tmp && \
    ARCH=linux R64=R64 CNAME=_gnu ./install_aapp8.sh 2
# Install ECCODES
RUN cd /tmp && \
    ./install_aapp8.sh 3
# Install AAPP
RUN cd /tmp && \
    ./install_aapp8.sh 4 && \
    # There is no $HOME directory, so use /tmp as work directory
    cd /opt/AAPP_8.12 && \
    sed -i 's/\${WRK:\=\$HOME\/tmp}/\/tmp/' ATOVS_ENV8
# Install kai
RUN cd /tmp && \
    ./install_aapp8.sh 11

# The default sh does not work properly when sourcing bash environment so
# use bash instead
RUN ln -s /usr/bin/bash /bin/sh.bash && \
    mv /bin/sh.bash /bin/sh

# Install Pytroll AAPP runner in a micromamba environment
RUN mkdir /opt/conda && \
    curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj -C /usr/bin/ --strip-components=1 bin/micromamba && \
    rm /root/.bashrc && \
    micromamba shell init -s bash && \
    mv /root/.bashrc /opt/conda/.bashrc && \
    source /opt/conda/.bashrc && \
    micromamba activate && \
    micromamba install -c conda-forge --no-deps dask && \
    micromamba install -y -f /tmp/environment.yaml && \
    rm /tmp/environment.yaml && \
    pip cache purge && \
    # Remove pip, leave dependencies intact
    micromamba remove --force -y pip && \
    # Clean all mamba caches, inluding packages
    micromamba clean -af -y && \
    chgrp -R 0 /opt/conda && \
    chmod -R g=u /opt/conda


FROM ubuntu:22.04

RUN apt update && \
    apt -y upgrade && \
    apt -y install bash ksh libgomp1 libxml2 && \
    apt -y clean

COPY --from=builder /opt /opt
COPY --from=builder /usr/bin/micromamba /usr/bin
COPY entrypoint.sh /usr/bin/

EXPOSE 40000

ENTRYPOINT ["/usr/bin/entrypoint.sh"]
