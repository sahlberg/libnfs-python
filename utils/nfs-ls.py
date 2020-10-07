#!/usr/bin/env python
# coding: utf-8
#
# Example program to list content of NFS directory
#
# Update: 10/7/2020
#   - Update print statement to a function call to comply with Python 3
#     syntax.

import sys
import libnfs


def usage():
    print('Usage: nfs-ls.py <NFS-URL>')
    print('')
    print('Example: nfs-ls.py nfs://127.0.0.1/data')
    sys.exit()


def ls(dir):
    import libnfs

    nfs = libnfs.NFS(dir)
    print('nfs', nfs)
    for ent in nfs.listdir("."):
        if ent in ['.', '..']:
            continue
        st = nfs.lstat(ent)
        print(ent, st)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        usage()
    ls(sys.argv[1])
