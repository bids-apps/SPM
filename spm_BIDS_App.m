% SPM BIDS App
%   SPM:  http://www.fil.ion.ucl.ac.uk/spm/
%   BIDS: http://bids.neuroimaging.io/
%   App:  https://github.com/BIDS-Apps/SPM/
%
% See also:
%   BIDS Validator: https://github.com/INCF/bids-validator

% Copyright (C) 2016 Wellcome Trust Centre for Neuroimaging

% Guillaume Flandin
% $Id$


%==========================================================================
%-BIDS App structure
%==========================================================================

BIDS_App = struct(...
    'dir','', ...            % BIDS root directory
    'outdir','', ...         % output directory
    'level','', ...          % first or second level analysis [participant*,group*]
    'participants',{{}}, ... % label of participants to be considered
    'temp',true);            % create local temporary copy of input files

%==========================================================================
%-Input arguments
%==========================================================================

if numel(inputs) == 0, inputs = {'--help'}; end
if numel(inputs) == 1
    switch inputs{1}
        case {'-v','--version'}
            fprintf('%s BIDS App, %s %s, version %s\n',...
                spm('version'), upper(spm_check_version), version, ...
                deblank(fileread('/version')));
        case {'-h','--help'}
            fprintf([...
                'Usage: bids/spm BIDS_DIR OUTPUT_DIR LEVEL [OPTIONS]\n',...
                '       bids/spm [ -h | --help | -v | --version ]\n',...
                '\n',...
                'Mandatory inputs:\n',...
                '    BIDS_DIR        Input directory following the BIDS standard\n',...
                '    OUTPUT_DIR      Output directory\n',...
                '    LEVEL           Level of the analysis that will be performed\n',...
                '                    {participant,group}\n',...
                '\n',...
                'Options:\n',...
                '    --participant_label PARTICIPANT_LABEL [PARTICIPANT_LABEL ...]\n',...
                '                    Label(s) of the participant(s) to analyse\n',...
                '    -h, --help      Print usage\n',...
                '    -v, --version   Print version information and quit\n']);
        otherwise
            fprintf([...
                'bids/spm: ''%s'' is not a valid syntax.\n',...
                'See ''bids/spm --help''.\n'],inputs{1});
    end
    exit(0);
end
if numel(inputs) < 2
    error('An output directory has to be specified.');
elseif numel(inputs) < 3
    error('Missing argument participant/group.');
end

BIDS_App.dir    = inputs{1};
BIDS_App.outdir = inputs{2};
BIDS_App.level  = inputs{3};

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
            BIDS_App.(arg){j} = inputs{i};
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
if ~exist(BIDS_App.dir,'dir')
	error('BIDS directory "%s" does not exist.',BIDS_App.dir);
end

%- level [participant/group] & output_dir
%--------------------------------------------------------------------------
if ~isempty(strmatch('participant',BIDS_App.level))
    if ~exist(BIDS_App.outdir,'dir')
        sts = mkdir(BIDS_App.outdir);
        if ~sts
            error('BIDS output directory could not be created.');
        end
    end
elseif ~isempty(strmatch('group',BIDS_App.level))
    if ~exist(BIDS_App.outdir,'dir')
        error('BIDS output directory "%s" does not exist.',BIDS_App.outdir);
    end
else
    error('Unknown analysis level "%s".',BIDS_App.level);
end

%==========================================================================
%-Parse BIDS directory and validate list of participants
%==========================================================================

%-Call BIDS Validator
%--------------------------------------------------------------------------
[status, result] = system('bids-validator --version');
if ~status
    [status, result] = system(['bids-validator "' BIDS_App.dir '"']);
    if status~=0
        fprintf('%s\n',result);
        exit(1);
    end
end

%-Parse BIDS directory
%--------------------------------------------------------------------------
BIDS = spm_BIDS(BIDS_App.dir);

%- --participant_label
%--------------------------------------------------------------------------
if isempty(BIDS_App.participants)
    BIDS_App.participants = {BIDS.subjects.name};
else
    BIDS_App.participants = cellfun(@(s) ['sub-' s], ...
        BIDS_App.participants, 'UniformOutput',false);
    df = setdiff(BIDS_App.participants,{BIDS.subjects.name});
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
BIDS_App.tmpdir = BIDS_App.dir;

if ~isempty(strmatch('participant',BIDS_App.level)) && ~isempty(BIDS_App.participants)
    if BIDS_App.temp
        %-Create temporary directory
        %------------------------------------------------------------------
        BIDS_App.tmpdir = tempname(BIDS_App.outdir);
        sts = mkdir(BIDS_App.tmpdir);
        if ~sts
            error('Output temporary directory could not be created.');
        end
        %atExit = onCleanup(@() rmdir(OpenfMRI.tmpdir,'s'));
        
        %-Copy participants' data
        %------------------------------------------------------------------
        for s=1:numel(BIDS_App.participants)
            fprintf('Temporary directory: %s\n',...
                fullfile(BIDS_App.tmpdir,BIDS_App.participants{s}));
            sts = copyfile(fullfile(BIDS_App.dir,BIDS_App.participants{s}),...
                fullfile(BIDS_App.tmpdir,BIDS_App.participants{s}));
            if ~sts
                error('Data could not be temporarily copied.');
            end
        end
    end
    
    %-Uncompress gzipped NIfTI files
    %----------------------------------------------------------------------
    for s=1:numel(BIDS_App.participants)
        niigz = spm_select('FPListRec',...
            fullfile(BIDS_App.tmpdir,BIDS_App.participants{s}),'^.*\.nii\.gz$');
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
    for s=1:numel(BIDS_App.participants)
        idx = find(ismember({BIDS.subjects.name},BIDS_App.participants{s}));
        % numel(idx) > 1 for multiple sessions/visits
    end
    BIDS = spm_changepath(BIDS,BIDS.dir,BIDS_App.tmpdir);
    BIDS = spm_changepath(BIDS,'.nii.gz','.nii');
end

%==========================================================================
%-Analysis level: participant
%==========================================================================

if ~isempty(strmatch('participant',BIDS_App.level))
    
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
    
    for s=1:numel(BIDS_App.participants)
        clear matlabbatch f a
        
        idx = find(ismember({BIDS.subjects.name},BIDS_App.participants{s}));
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
        
        [~,prov] = spm_jobman('run',matlabbatch);
    end
    
    % make sure relevant files are stored in OpenfMRI.outdir
    % -> normalised structural, smoothed normalised functional, movement pars
    
    %-First Level fMRI
    %======================================================================
    fprintf('Nothing to do at fMRI first level yet.\n');
    for s=1:numel(BIDS_App.participants)
        
    end
    
    % make sure relevant files are stored in OpenfMRI.outdir
    % -> the entire folder containing SPM.mat, also NIDM export
end

%==========================================================================
%-Analysis level: group
%==========================================================================

if ~isempty(strmatch('group',BIDS_App.level))
    fprintf('Nothing to do at the group level yet.\n');
end

% make sure relevant files are stored in OpenfMRI.outdir
% -> the entire folder containing SPM.mat, also NIDM export

%==========================================================================
%-Delete temporary files and exit
%==========================================================================
%delete(atExit);
