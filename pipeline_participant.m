% Do not modify variables: BIDS,BIDS_App, BIDS_ORIG, s

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

f = cell(numel(BIDS.subjects.func),1);
for i=1:numel(BIDS.subjects.func)
    f{i} = fullfile(BIDS.subjects.path,'func',BIDS.subjects.func(i).filename);
end
a = fullfile(BIDS.subjects.path,'anat',BIDS.subjects.anat.filename); % assumes T1 is first

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
fprintf('Nothing to do at fMRI first level yet.\n');
