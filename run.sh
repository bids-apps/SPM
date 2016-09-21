#!/bin/bash

HOME=$(mktemp -d)
exec ${SPM_EXEC} script ${SPM_DIR}/spm_BIDS_App.m $@
