# SPM BIDS App

## Description

[BIDS App](http://bids-apps.neuroimaging.io/) containing an instance of the [SPM12 software](http://www.fil.ion.ucl.ac.uk/spm/).

## Documentation

Extensive documentation can be found in the [SPM manual](http://www.fil.ion.ucl.ac.uk/spm/doc/manual.pdf).

## Usage

To launch an instance of the container and analyse some data in BIDS format, type:

```
$ docker run bids/spm bids_dir output_dir level [--participant_label PARTICIPANT_LABEL [PARTICIPANT_LABEL ...]] [--config CFG_FILE]
```

For example, to run an analysis in ```participant``` level mode, type:

```
$ docker run -ti --rm \
  -v /tmp:/tmp \
  -v /var/tmp:/var/tmp \
  -v /path/to/local/bids/input/dataset/:/data \
  -v /path/to/local/output/:/output \
  bids/spm \
  /data /output participant --participant_label 01
```

For example, to run an analysis in ```group``` level mode with a user-defined pipeline, type:

```
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

```
$ docker build -t <yourhandle>/spm12 .
```

## Error Reporting

If you have a specific problem with the SPM BIDS App, please open an [issue](https://github.com/BIDS-Apps/SPM/issues) on GitHub.

If your issue concerns SPM more generally, please use the [SPM mailing list](https://www.jiscmail.ac.uk/cgi-bin/webadmin?A0=spm)

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
