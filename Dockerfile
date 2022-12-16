FROM bids/base_validator

MAINTAINER Guillaume Flandin <g.flandin@ucl.ac.uk>

# Update system
RUN apt-get -qq update && apt-get -qq install -y \
    unzip \
    xorg \
    wget && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install MATLAB MCR
ENV MATLAB_VERSION R2019b
ENV MATLAB_UPDATE 5
RUN mkdir /opt/mcr_install && \
    mkdir /opt/mcr && \
    wget -P /opt/mcr_install https://ssd.mathworks.com/supportfiles/downloads/${MATLAB_VERSION}/Release/${MATLAB_UPDATE}/deployment_files/installer/complete/glnxa64/MATLAB_Runtime_${MATLAB_VERSION}_Update_${MATLAB_UPDATE}_glnxa64.zip && \
    unzip -q /opt/mcr_install/MATLAB_Runtime_${MATLAB_VERSION}_Update_${MATLAB_UPDATE}_glnxa64.zip -d /opt/mcr_install && \
    /opt/mcr_install/install -destinationFolder /opt/mcr -agreeToLicense yes -mode silent && \
    rm -rf /opt/mcr_install /tmp/*

# Configure environment
ENV MCR_VERSION v97
ENV LD_LIBRARY_PATH /opt/mcr/${MCR_VERSION}/runtime/glnxa64:/opt/mcr/${MCR_VERSION}/bin/glnxa64:/opt/mcr/${MCR_VERSION}/sys/os/glnxa64:/opt/mcr/${MCR_VERSION}/sys/opengl/lib/glnxa64
ENV MCR_INHIBIT_CTF_LOCK 1

# Install SPM Standalone
ENV SPM_VERSION 12
ENV SPM_REVISION r7771
ENV SPM_DIR /opt/spm${SPM_VERSION}
ENV SPM_EXEC ${SPM_DIR}/spm${SPM_VERSION}
RUN wget -P /opt https://www.fil.ion.ucl.ac.uk/spm/download/restricted/bids/spm${SPM_VERSION}_${SPM_REVISION}_Linux_${MATLAB_VERSION}.zip && \
    unzip -q /opt/spm${SPM_VERSION}_${SPM_REVISION}_Linux_${MATLAB_VERSION}.zip -d /opt && \
    rm -f /opt/spm${SPM_VERSION}_${SPM_REVISION}_Linux_${MATLAB_VERSION}.zip && \
    ${SPM_EXEC} function exit

# Configure SPM BIDS App entry point
COPY run.sh spm_BIDS_App.m pipeline_participant.m pipeline_group.m /opt/spm${SPM_VERSION}/
RUN chmod +x /opt/spm${SPM_VERSION}/run.sh
RUN chmod +x /opt/spm${SPM_VERSION}/spm${SPM_VERSION}
RUN chmod +x /opt/spm${SPM_VERSION}/run_spm12.sh
COPY version /opt/spm${SPM_VERSION}/version

ENTRYPOINT ["/opt/spm12/run.sh"]
#ENTRYPOINT ["/opt/spm12/spm12","script","/opt/spm12/spm_BIDS_App.m"]
