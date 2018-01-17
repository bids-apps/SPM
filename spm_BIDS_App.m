% SPM BIDS App
%   SPM:  http://www.fil.ion.ucl.ac.uk/spm/
%   BIDS: http://bids.neuroimaging.io/
%   App:  https://github.com/BIDS-Apps/SPM/
%
% See also:
%   BIDS Validator: https://github.com/INCF/bids-validator

% Copyright (C) 2016-2018 Wellcome Trust Centre for Neuroimaging

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
    'config','',...          % configuration script
    'temp',true,...          % create local temporary copy of input files
    'validate',true);

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
                '    --config CONFIG_FILE\n',...
                '                    Optional configuration M-file describing\n',...
                '                    the analysis to be performed\n',...
                '    --skip-bids-validator\n',...
                '                    Skip BIDS validation\n',...
                '    -h, --help      Print usage\n',...
                '    -v, --version   Print version information and quit\n']);
        case {'--gui'}
            cd(spm('Dir'));
            waitfor(spm_Welcome);
            waitfor(spm_figure('FindWin','Menu'));
            exit(0);
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
        case '--config'
            arg = 'config';
        case '--skip-bids-validator'
            BIDS_App.validate = false;
            i = i + 1;
            continue;
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
if strncmp('participant',BIDS_App.level,11)
    if ~exist(BIDS_App.outdir,'dir')
        sts = mkdir(BIDS_App.outdir);
        if ~sts
            error('BIDS output directory could not be created.');
        end
    end
elseif strncmp('group',BIDS_App.level,5)
    if ~exist(BIDS_App.outdir,'dir')
        error('BIDS output directory "%s" does not exist.',BIDS_App.outdir);
    end
else
    error('Unknown analysis level "%s".',BIDS_App.level);
end

%-Configuration file
%--------------------------------------------------------------------------
if ~isempty(BIDS_App.config)
    if numel(BIDS_App.config) > 1
        error('More than one configuration file provided.');
    end
    BIDS_App.config = char(BIDS_App.config);
    if isempty(fileparts(BIDS_App.config))
        BIDS_App.config = fullfile(fileparts(mfilename('fullpath')),BIDS_App.config);
    end
    if isempty(spm_file(BIDS_App.config,'ext'))
        BIDS_App.config = [BIDS_App.config '.m'];
    end
    if ~spm_existfile(BIDS_App.config)
        error('Cannot find configuration file "%s".',BIDS_App.config);
    end
else
    BIDS_App.config = fullfile(fileparts(mfilename('fullpath')),...
        ['pipeline_' BIDS_App.level '.m']);
    if ~spm_existfile(BIDS_App.config)
        error('No default configuration file found for "%s" level.',BIDS_App.level);
    end
end

%==========================================================================
%-Parse BIDS directory and validate list of participants
%==========================================================================

%-Call BIDS Validator
%--------------------------------------------------------------------------
if BIDS_App.validate
    [status, result] = system('bids-validator --version');
    if ~status
        [status, result] = system(['bids-validator "' BIDS_App.dir '"']);
        if status~=0
            fprintf('%s\n',result);
            exit(1);
        end
    end
end

%-Parse BIDS directory
%--------------------------------------------------------------------------
BIDS = spm_BIDS(BIDS_App.dir);

%- --participant_label
%--------------------------------------------------------------------------
if isempty(BIDS_App.participants)
    BIDS_App.participants = spm_BIDS(BIDS,'subjects');
else
    df = setdiff(BIDS_App.participants,spm_BIDS(BIDS,'subjects'));
    if ~isempty(df)
        error('Participant directory "%s" does not exist.',df{1});
    end
end
BIDS_App.participants = cellfun(@(s) ['sub-' s], ...
    BIDS_App.participants, 'UniformOutput',false);


%==========================================================================
%-SPM Initialisation
%==========================================================================

spm('defaults','fmri');
spm_jobman('initcfg');

%==========================================================================
%-(Temporary) Copy of input data and uncompress image files
%==========================================================================

atExit = '';
BIDS_App.tmpdir = BIDS_App.dir;

if strncmp('participant',BIDS_App.level,11) && ~isempty(BIDS_App.participants)
    if BIDS_App.temp
        %-Create temporary directory
        %------------------------------------------------------------------
        BIDS_App.tmpdir = BIDS_App.outdir;
        %BIDS_App.tmpdir = tempname(BIDS_App.outdir);
        %sts = mkdir(BIDS_App.tmpdir);
        %if ~sts
        %    error('Output temporary directory could not be created.');
        %end
        %atExit = onCleanup(@() rmdir(BIDS_App.tmpdir,'s'));
        
        %-Copy participants' data
        %------------------------------------------------------------------
        for s=1:numel(BIDS_App.participants)
            %fprintf('Temporary directory: %s\n',...
            %    fullfile(BIDS_App.tmpdir,BIDS_App.participants{s}));
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
    
    %-Update BIDS structure to point to new local files
    %----------------------------------------------------------------------
    BIDS = spm_changepath(BIDS,BIDS.dir,BIDS_App.tmpdir,false);
    BIDS = spm_changepath(BIDS,'.nii.gz','.nii',false);
end

%-Simplify BIDS structure to only contain participants under study
%--------------------------------------------------------------------------
idx = ismember({BIDS.subjects.name},BIDS_App.participants);
BIDS.subjects = BIDS.subjects(idx);
if ~isempty(BIDS.participants)
    idx = ismember(BIDS.participants.participant_id,BIDS_App.participants);
    for fn=fieldnames(BIDS.participants)'
        BIDS.participants.(char(fn)) = BIDS.participants.(char(fn))(idx);
    end
end

%==========================================================================
%-Analysis level: participant*
%==========================================================================

if strncmp('participant',BIDS_App.level,11)
    
    BIDS_ORIG = BIDS;
    
    for s=1:numel(BIDS_App.participants)
        BIDS = BIDS_ORIG;
        idx = ismember({BIDS.subjects.name},BIDS_App.participants{s});
        BIDS.subjects = BIDS.subjects(idx);
        if ~isempty(BIDS.participants)
            idx = ismember(BIDS.participants.participant_id,BIDS_App.participants{s});
            for fn=fieldnames(BIDS.participants)'
                BIDS.participants.(char(fn)) = BIDS.participants.(char(fn))(idx);
            end
        end
        spm('FnBanner',['BIDS ' upper(BIDS_App.level) ' ' BIDS_App.participants{s}]);
        spm('Run',BIDS_App.config);
    end
    
    % make sure relevant files are stored in BIDS_App.outdir
end

%==========================================================================
%-Analysis level: group*
%==========================================================================

if strncmp('group',BIDS_App.level,5)
    
    spm('FnBanner',['BIDS ' upper(BIDS_App.level)]);
    spm('Run',BIDS_App.config);
    
    % make sure relevant files are stored in BIDS_App.outdir
end

%==========================================================================
%-Delete temporary files and exit
%==========================================================================
%delete(atExit);
close all force
