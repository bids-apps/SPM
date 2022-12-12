# SPM BIDS App

## Description

[BIDS App](http://bids-apps.neuroimaging.io/) containing an instance of the [SPM12 software](http://www.fil.ion.ucl.ac.uk/spm/).

## Documentation

Extensive documentation can be found in the [SPM manual](http://www.fil.ion.ucl.ac.uk/spm/doc/manual.pdf).

## Usage

To launch an instance of the container and analyse some data in BIDS format, type:

```bash
$ docker run bids/spm bids_dir output_dir level [--participant_label PARTICIPANT_LABEL [PARTICIPANT_LABEL ...]] [--config CFG_FILE]
```

For example, to run an analysis in ```participant``` level mode, type:

```bash
$ docker run -ti --rm \
  -v /tmp:/tmp \
  -v /var/tmp:/var/tmp \
  -v /path/to/local/bids/input/dataset/:/data \
  -v /path/to/local/output/:/output \
  bids/spm \
  /data /output participant --participant_label 01
```

For example, to run an analysis in ```group``` level mode with a user-defined pipeline, type:

```bash
$ docker run -ti --rm \
  -v /tmp:/tmp \
  -v /var/tmp:/var/tmp \
  -v /path/to/local/bids/input/dataset/:/data \
  -v /path/to/local/output/:/output \
  -v /path/to/local/cfg/:/cfg \
  bids/spm \
  /data /output group --config /cfg/my_pipeline_group.m
```

To build the container, type:

```bash
$ docker build -t <yourhandle>/spm12 .
```

### Configuration file

The configuration file is a MATLAB script detailing the analysis pipeline to be executed. Two struct variables, ```BIDS``` and ```BIDS_App``` are available from within the script, containing details from the command line and the BIDS-formatted dataset. In particular, the ```BIDS``` structure can be queried using the ```spm_BIDS()``` function (see [this](https://en.wikibooks.org/wiki/SPM/BIDS)). The default configuration files for first and second level analyses are ```pipeline_participant.m``` and ```pipeline_group.m```. A template for a single configuration file for all levels could be as follow:

```bash
if strcmp(BIDS_App.level,'participant')
    % First level analysis
    
    % Get T1-weighted image filename for given subject:
    % a = spm_BIDS(BIDS,'data', 'modality','anat', 'type','T1w');
    % ...
else
    % Second level analysis
    
    % The name of the directory containing first level outputs is stored in:
    % BIDS_App.outdir
    % ...
end
```

## Error Reporting

If you have a specific problem with the SPM BIDS App, please open an [issue](https://github.com/BIDS-Apps/SPM/issues) on GitHub.

If your issue concerns SPM more generally, please use the [SPM mailing list](https://www.jiscmail.ac.uk/cgi-bin/webadmin?A0=spm).

## Acknowledgement

Please refer to:

```
@Book{spm,
  editor = {K.J. Friston and J. Ashburner and S.J. Kiebel and T.E. Nichols and W.D. Penny},
  title = {Statistical Parametric Mapping: The Analysis of Functional Brain Images},
  publisher = {Academic Press},
  year = {2007},
  url = {http://store.elsevier.com/product.jsp?isbn=9780123725608} 
}
```
