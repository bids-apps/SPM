%==========================================================================
%           C O N F I G U R A T I O N    F I L E  :  G R O U P
%==========================================================================

% Available variables: BIDS and BIDS_App

%==========================================================================
%-Structural mean image
%==========================================================================
a = spm_select('FPListRec',BIDS_App.outdir,'wm.*_T1w.nii');
if isempty(a), error('Cannot find preprocessed T1-weighted images.'); end

clear matlabbatch

matlabbatch{1}.spm.util.imcalc.input = cellstr(a);
matlabbatch{1}.spm.util.imcalc.output = 'meanT1w.nii';
matlabbatch{1}.spm.util.imcalc.outdir = {fullfile(BIDS_App.outdir)};
matlabbatch{1}.spm.util.imcalc.expression = 'mean(X)';
matlabbatch{1}.spm.util.imcalc.options.dmtx = 1;
matlabbatch{1}.spm.util.imcalc.options.dtype = 4;

[~,prov] = spm_jobman('run',matlabbatch);

%==========================================================================
%-Second Level fMRI
%==========================================================================
%fprintf('Nothing to do at fMRI second level.\n');
