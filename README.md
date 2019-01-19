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

To create a patch:

```console
$ cd top
$ cp folder/file folder/file.patched
$ vi folder/file.patched
$ diff -u folder/file folder/file.patched >my.patch
```

To apply the patch:

```console
$ cd top
$ patch -p0 <my.patch
```
