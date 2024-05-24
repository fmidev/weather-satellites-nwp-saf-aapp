# Recipe to build NWP SAF AAPP as a container

## Existing files

The files present in the repository are:

 * `README.md` - this file
 * `Dockerfile` - build recipe
 * `entrypoint.sh` - file to be run when the container is started
 * `install_aapp8.patch` - a patch to make some changes to the original installation. FMI specific changes, adjust as necessary.

## External files needed

The following files and packages are needed for the installation:

* `install_aapp8.sh` - Installation script available from https://nwp-saf.eumetsat.int/site/software/aapp/download/
* `AAPP_8.12.tgz` the installation package for AAPP. Available from https://nwp-saf.eumetsat.int/site/ . Requires registration.
* `kai_1_12_e8b74685d1.zip` - available from https://user.eumetsat.int/search-view?term=kai&sort=score%20desc


## Building

```bash
podman build -t aapp -f Dockerfile .
```

## Usage

TODO
