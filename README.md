# build-helper

Common script used in other build scripts.

- `host-functions-source.sh`: to be included with `source` in the host build script
- `container-functions-source.sh`: to be included with `source` in the container build script

Deprecated:

- `builder-helper.sh`: used in the first generation of build scripts.

# Patches

The code used to download and extract archives can also be used
to post-patch the downloaded files. For this a patch file must be
placed in the `patches` folder, and the name must be passed as the
third param to `extract()`.

## Memo

The patch is applied from the top build folder, so it must be created
with the full path.

For example, to create a binutils patch, use:

```console
$ cd top
$ cp binutils/bfd/ihex.c binutils/bfd/ihex.c.patched
$ vi binutils/bfd/ihex.c.patched
$ diff -u binutils/bfd/ihex.c binutils/bfd/ihex.c.patched > patches/binutils-2.31.patch
```

The code to apply the patch (`extract()`) does the following:

```console
$ cd top
$ patch -p0 < "binutils-2.31.patch"
```
