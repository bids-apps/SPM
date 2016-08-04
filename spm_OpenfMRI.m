% Example of SPM workflow for OpenfMRI 2.0 (using BIDS)

% Copyright (C) 2016 Wellcome Trust Centre for Neuroimaging

% Guillaume Flandin
% $Id$


%==========================================================================
%-OpenfMRI structure
%==========================================================================

OpenfMRI = struct(...
    'dir','', ...            % BIDS root directory
    'outdir','', ...         % output directory
    'level','', ...          % first or second level analysis [participant*,group*]
    'participants',{{}}, ... % label of participants to be considered
    'temp',true);            % create local temporary copy of input files

%==========================================================================
%-Input arguments
%==========================================================================

if numel(inputs) < 1
    error('A BIDS directory has to be specified.');
elseif numel(inputs) < 2
    error('An output directory has to be specified.');    
elseif numel(inputs) < 3
    error('Missing argument participant/group.');
end
OpenfMRI.dir    = inputs{1};
OpenfMRI.outdir = inputs{2};
OpenfMRI.level  = inputs{3};

i = 4;
while i <= numel(inputs)
    arg = inputs{i};
    switch arg
        case '--participant_label'
            arg = 'participants';
        otherwise
            warning('Unknown input argument "%s".',arg);
            arg = strtok(arg,'-');
    end
    j = 1;
    while true
        i = i + 1;
        if i <= numel(inputs)
            if inputs{i}(1) == '-', break; end
            OpenfMRI.(arg){j} = inputs{i};
            j = j + 1;
        else
            break;
        end
    end
end

%==========================================================================
%-Validation of input arguments
%==========================================================================

%- bids_dir
%--------------------------------------------------------------------------
if  ~exist(OpenfMRI.dir,'dir')
    error('BIDS directory does not exist.');
end

%- level [participant/group] & output_dir
%--------------------------------------------------------------------------
if ~isempty(strmatch('participant',OpenfMRI.level))
    if ~exist(OpenfMRI.outdir,'dir')
        sts = mkdir(OpenfMRI.outdir);
        if ~sts
            error('BIDS output directory could not be created.');
        end
    end
elseif ~isempty(strmatch('group',OpenfMRI.level))
    if ~exist(OpenfMRI.outdir,'dir')
        error('BIDS output directory does not exist.');
    end
else
    error('Unknown level analysis.');
end

%==========================================================================
%-Parse BIDS directory and validate list of participants
%==========================================================================

%-Parse BIDS directory
%--------------------------------------------------------------------------
BIDS = spm_BIDS(OpenfMRI.dir);

%- --participant_label
%--------------------------------------------------------------------------
if isempty(OpenfMRI.participants)
    OpenfMRI.participants = {BIDS.subjects.name};
else
    OpenfMRI.participants = cellfun(@(s) ['sub-' s], ...
        OpenfMRI.participants, 'UniformOutput',false);
    df = setdiff(OpenfMRI.participants,{BIDS.subjects.name});
    if ~isempty(df)
        error('Participant directory "%s" does not exist.',df{1});
    end
end

%==========================================================================
%-SPM Initialisation
%==========================================================================

spm('defaults','fmri');
spm_jobman('initcfg');

%==========================================================================
%-Temporary copy of input data and uncompress image files
%==========================================================================

atExit = '';
OpenfMRI.tmpdir = OpenfMRI.dir;

if ~isempty(strmatch('participant',OpenfMRI.level)) && ~isempty(OpenfMRI.participants)
    if OpenfMRI.temp
        %-Create temporary directory
        %------------------------------------------------------------------
        OpenfMRI.tmpdir = tempname(OpenfMRI.outdir);
        sts = mkdir(OpenfMRI.tmpdir);
        if ~sts
            error('Output temporary directory could not be created.');
        end
        %atExit = onCleanup(@() rmdir(OpenfMRI.tmpdir,'s'));
        
        %-Copy participants' data
        %------------------------------------------------------------------
        for s=1:numel(OpenfMRI.participants)
            fprintf('Temporary directory: %s\n',...
                fullfile(OpenfMRI.tmpdir,OpenfMRI.participants{s}));
            sts = copyfile(fullfile(OpenfMRI.dir,OpenfMRI.participants{s}),...
                fullfile(OpenfMRI.tmpdir,OpenfMRI.participants{s}));
            if ~sts
                error('Data could not be temporarily copied.');
            end
        end
    end
    
    %-Uncompress gzipped NIfTI files
    %----------------------------------------------------------------------
    for s=1:numel(OpenfMRI.participants)
        niigz = spm_select('FPListRec',...
            fullfile(OpenfMRI.tmpdir,OpenfMRI.participants{s}),'^.*\.nii\.gz$');
        if ~isempty(niigz)
            niigz = cellstr(niigz);
            for i=1:numel(niigz)
                gunzip(niigz{i});
                delete(niigz{i});
            end
        end
    end
    
    %-Gather from BIDS structure all relevant information for analysis
    %----------------------------------------------------------------------
    % structural and functional images for each subject/visit/run/task
    for s=1:numel(OpenfMRI.participants)
        idx = find(ismember({BIDS.subjects.name},OpenfMRI.participants{s}));
        % numel(idx) > 1 for multiple sessions/visits
    end
    BIDS = spm_changepath(BIDS,BIDS.dir,OpenfMRI.tmpdir);
    BIDS = spm_changepath(BIDS,'.nii.gz','.nii');
end

%==========================================================================
%-Analysis level: participant
%==========================================================================

if ~isempty(strmatch('participant',OpenfMRI.level))
    
    %-fMRI Preprocessing
    %======================================================================
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
    
    for s=1:numel(OpenfMRI.participants)
        clear matlabbatch f a

        idx = find(ismember({BIDS.subjects.name},OpenfMRI.participants{s}));
        for i=1:numel(BIDS.subjects(idx).func)
            f{i,1} = fullfile(BIDS.subjects(idx).path,'func',BIDS.subjects(idx).func(i).filename);
        end
        a = fullfile(BIDS.subjects(idx).path,'anat',BIDS.subjects(idx).anat.filename); % assumes T1 is first

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

        spm_jobman('run',matlabbatch);
    end
    
    % make sure relevant files are stored in OpenfMRI.outdir
    % -> normalised structural, smoothed normalised functional, movement pars
    
    %-First Level fMRI
    %======================================================================
    fprintf('Nothing to do at fMRI first level yet.\n');
    for s=1:numel(OpenfMRI.participants)
        
    end
    
    % make sure relevant files are stored in OpenfMRI.outdir
    % -> the entire folder containing SPM.mat, also NIDM export
end
    
%==========================================================================
%-Analysis level: group
%==========================================================================

if ~isempty(strmatch('group',OpenfMRI.level))
    fprintf('Nothing to do at the group level yet.\n');
end

% make sure relevant files are stored in OpenfMRI.outdir
% -> the entire folder containing SPM.mat, also NIDM export

%==========================================================================
%-Delete temporary files and exit
%==========================================================================
%delete(atExit);
