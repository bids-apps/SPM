#!/bin/bash

HOME=$(mktemp -d --suffix=.matlab)
exec ${SPM_EXEC} script ${SPM_DIR}/spm_BIDS_App.m $@
