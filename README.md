# SPM BIDS App

BIDS App containing an instance of the [SPM12 software](http://www.fil.ion.ucl.ac.uk/spm/).

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
