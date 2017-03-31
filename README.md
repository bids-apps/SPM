# SPM BIDS App

The [SPM](http://www.fil.ion.ucl.ac.uk/spm/) BIDS App contains an instance of the [SPM12 software](http://www.fil.ion.ucl.ac.uk/spm/software/spm12/).

## Description

The available pipeline is for the preprocessing of fMRI data, and can implement implement any or all of the following steps: 

  * Slice Timing Correction - Correct differences in image acquisition time between slices (before or after realignment).
  * Field Map - Generate  unwrapped  field  maps  which  are converted to voxel displacement maps (VDM) that can be used to unwarp geometrically distorted EPI images.
  * Realign (& Unwarp) - Within-subject registration and unwarping of time series.
  * Coregistration - Place realigned time series in register with (bias corrected) structural image.
  * Segmentation - Segments,  bias  corrects  and  spatially normalises (all in the same model) based on the unified segmentation approach as implemented by `spm_preproc`.
  * Smooth - Smoothing (or convolving) image volumes with a Gaussian kernel of a specified width.

## Documentation

To build the container, type:

```
$ docker build -t <yourhandle>/spm12 .
```

To launch an instance of the container and analyse some data, type:

```
$ docker run <yourhandle>/spm12 bids_dir output_dir level [--participant_label PARTICIPANT_LABEL [PARTICIPANT_LABEL ...]]
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
