FROM bids/base_validator

MAINTAINER Guillaume Flandin <g.flandin@ucl.ac.uk>

# Install MATLAB MCR R2016a
RUN apt-get -qq update && apt-get -qq install -y \
    unzip \
    xorg \
    wget && \
    mkdir /mcr-install && \
    mkdir /opt/mcr && \
    cd /mcr-install && \
    wget http://www.mathworks.com/supportfiles/downloads/R2016a/deployment_files/R2016a/installers/glnxa64/MCR_R2016a_glnxa64_installer.zip && \
    cd /mcr-install && \
    unzip -q MCR_R2016a_glnxa64_installer.zip && \
    ./install -destinationFolder /opt/mcr -agreeToLicense yes -mode silent && \
    cd / && \
    rm -rf mcr-install

# Configure environment
ENV LD_LIBRARY_PATH /opt/mcr/v901/runtime/glnxa64:/opt/mcr/v901/bin/glnxa64:/opt/mcr/v901/sys/os/glnxa64:/opt/mcr/v901/sys/opengl/lib/glnxa64

# Install SPM12 Standalone
RUN cd /opt && \
    wget http://www.fil.ion.ucl.ac.uk/spm/download/restricted/bids/spm12_latest_Linux_R2016a.zip && \
    unzip -q spm12_latest_Linux_R2016a.zip && \
    rm -f spm12_latest_Linux_R2016a.zip && \
    /opt/spm12/spm12 quit

# HPC folders:
RUN mkdir /oasis && \
    mkdir /projects && \
    mkdir /scratch && \
    mkdir /local-scratch

# Install OpenfMRI entry point
RUN mkdir -p /code
COPY spm_OpenfMRI.m /code/spm_OpenfMRI.m

ENTRYPOINT ["/opt/spm12/spm12","script","/code/spm_OpenfMRI.m"]
