FROM bids/matlab-compiler-runtime:9.7

MAINTAINER Guillaume Flandin <g.flandin@ucl.ac.uk>

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
COPY version /version

ENTRYPOINT ["/opt/spm12/run.sh"]
#ENTRYPOINT ["/opt/spm12/spm12","script","/opt/spm12/spm_BIDS_App.m"]
