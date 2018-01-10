%==========================================================================
%     C O N F I G U R A T I O N    F I L E  :  P A R T I C I P A N T
%==========================================================================

% Available variables: BIDS and BIDS_App

%==========================================================================
%-fMRI Preprocessing
%==========================================================================
% ask for: slice timing correction (before or after realign)
% ask for: fieldmap
% ask for: realign and unwarp
% ask for: coregister with bias corrected (skull stripped?) anat
% ask for: voxel size for normalise/write
% ask for: smoothing kernel FWHM
% ask for: DARTEL
vox_anat = [1 1 1];
vox_func = [3 3 3];
FWHM = [12 12 12];

f = spm_BIDS(BIDS,'data', 'modality','func', 'type','bold');
if isempty(f), error('Cannot find BOLD time series.'); end
a = spm_BIDS(BIDS,'data', 'modality','anat', 'type','T1w');
if isempty(a), error('Cannot find T1-weighted image.'); end

clear matlabbatch

% Realign
%------------------------------------------------------------------
matlabbatch{1}.spm.spatial.realign.estwrite.data = cellfun(@(x) {{x}},f)';
matlabbatch{1}.spm.spatial.realign.estwrite.roptions.which = [0 1];

% Coregister
%------------------------------------------------------------------
matlabbatch{2}.spm.spatial.coreg.estimate.ref    = cellstr(spm_file(f{1},'prefix','mean','number',1));
matlabbatch{2}.spm.spatial.coreg.estimate.source = cellstr(a);

% Segment
%------------------------------------------------------------------
matlabbatch{3}.spm.spatial.preproc.channel.vols  = cellstr(a);
matlabbatch{3}.spm.spatial.preproc.channel.write = [0 1];
matlabbatch{3}.spm.spatial.preproc.warp.write    = [0 1];

% Normalise: Write
%------------------------------------------------------------------
matlabbatch{4}.spm.spatial.normalise.write.subj.def      = cellstr(spm_file(a,'prefix','y_','ext','nii'));
matlabbatch{4}.spm.spatial.normalise.write.subj.resample = cellstr(f);
matlabbatch{4}.spm.spatial.normalise.write.woptions.vox  = vox_func;

matlabbatch{5}.spm.spatial.normalise.write.subj.def      = cellstr(spm_file(a,'prefix','y_','ext','nii'));
matlabbatch{5}.spm.spatial.normalise.write.subj.resample = cellstr(spm_file(a,'prefix','m','ext','nii'));
matlabbatch{5}.spm.spatial.normalise.write.woptions.vox  = vox_anat;

% Smooth
%------------------------------------------------------------------
matlabbatch{6}.spm.spatial.smooth.data = cellstr(spm_file(f,'prefix','w'));
matlabbatch{6}.spm.spatial.smooth.fwhm = FWHM;

[~,prov] = spm_jobman('run',matlabbatch);


%==========================================================================
%-First Level fMRI
%==========================================================================
%fprintf('Nothing to do at fMRI first level.\n');
