#   Copyright (C) 2014 by Ronnie Sahlberg <ronniesahlberg@gmail.com>
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU Lesser General Public License as published by
#   the Free Software Foundation; either version 2.1 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Lesser General Public License for more details.
#
#   You should have received a copy of the GNU Lesser General Public License
#   along with this program; if not, see <http://www.gnu.org/licenses/>.

import os
from libnfs import *

def _stat_to_dict(stat):
        return {'dev': stat.nfs_dev,
                'ino': stat.nfs_ino,
                'mode': stat.nfs_mode,
                'nlink': stat.nfs_nlink,
                'uid': stat.nfs_uid,
                'gid': stat.nfs_gid,
                'rdev': stat.nfs_rdev,
                'size': stat.nfs_size,
                'blksize': stat.nfs_blksize,
                'blocks': stat.nfs_blocks,
                'atime': {'sec':  stat.nfs_atime,
                          'nsec': stat.nfs_atime_nsec},
                'ctime': {'sec':  stat.nfs_ctime,
                          'nsec': stat.nfs_ctime_nsec},
                'mtime': {'sec':  stat.nfs_mtime,
                          'nsec': stat.nfs_mtime_nsec}
                }


class NFSFH(object):
    def __init__(self, nfs, path, mode='r'):

        self._nfs = nfs
        self._name = path

        if path[:6] == "nfs://":
            _pos = path.rfind('/')
            _dir = path[:_pos]
            path = path[_pos:]
            self._private_context = NFS(_dir)
            self._nfs = self._private_context._nfs

        _plus = True if '+' in mode else False
        _mode = 0
        if 'r' in mode:
            _mode = os.O_RDWR if _plus else os.O_RDONLY
        if 'w' in mode:
            _mode = os.O_RDWR if _plus else os.O_WRONLY
            _mode |= os.O_CREAT|os.O_TRUNC
        if 'a' in mode:
            _mode = os.O_RDWR if _plus else os.O_WRONLY
            _mode |= os.O_CREAT|os.O_APPEND

        self._nfsfh = new_NFSFileHandle()
        if _mode & os.O_CREAT:
            nfs_create(self._nfs, path, _mode, 0664, self._nfsfh)
        else:
            nfs_open(self._nfs, path, _mode, self._nfsfh)
        self._nfsfh = NFSFileHandle_value(self._nfsfh)
        self._closed = False
        self._need_flush = False
        self._writing = True if _mode & (os.O_RDWR|os.O_WRONLY) else False

    def __del__(self):
        pass

    def close(self):
        if self._need_flush:
            self.flush()
        nfs_close(self._nfs, self._nfsfh)
        self._closed = True

    def write(self, str):
        if self._closed:
            raise ValueError('I/O operation on closed file');
        if not self._writing:
            raise IOError('Trying to write on file open for reading');
        nfs_write(self._nfs, self._nfsfh, len(str), str)
        self._need_flush = True

    def read(self, size=-1):
        if size < 0:
            _pos = self.tell()

            _st = nfs_stat_64()
            nfs_fstat64(self._nfs, self._nfsfh, _st)

            size = _st.nfs_size - _pos

        buf = str(bytearray(size))
        count = nfs_read(self._nfs, self._nfsfh, len(buf), buf)
        return buf[:count]

    def fstat(self):
        _stat = nfs_stat_64()
        nfs_fstat64(self._nfs, self._nfsfh, _stat)
        return _stat_to_dict(_stat)

    def tell(self):
        _pos = new_uint64_t_ptr()
        nfs_lseek(self._nfs, self._nfsfh, 0, os.SEEK_CUR, _pos)
        _pos = uint64_t_ptr_value(_pos)
        return _pos

    def seek(self, offset, whence=os.SEEK_CUR):
        _pos = new_uint64_t_ptr()
        nfs_lseek(self._nfs, self._nfsfh, offset, whence, _pos)

    def truncate(self, offset=-1):
        if offset < 0:
            offset = self.tell()
        nfs_ftruncate(self._nfs, self._nfsfh, offset)

    def fileno(self):
        _st = nfs_stat_64()
        nfs_fstat64(self._nfs, self._nfsfh, _st)
        return _st.nfs_ino

    def flush(self):
        if self._closed:
            raise ValueError('I/O operation on closed file');
        nfs_fsync(self._nfs, self._nfsfh)
        self._need_flush = False

    def isatty(self):
        return False

    @property
    def name(self):
        return self._name

    @property
    def closed(self):
        return self._closed


class NFS(object):
    def __init__(self, url):
        self._nfs = nfs_init_context()
        self._url = nfs_parse_url_dir(self._nfs, url)
        nfs_mount(self._nfs, self._url.server, self._url.path)

    def __del__(self):
        nfs_destroy_url(self._url)
        nfs_destroy_context(self._nfs)

    def open(self, path, mode='r'):
        return NFSFH(self._nfs, path, mode=mode)

    def stat(self, path):
        _stat = nfs_stat_64()
        nfs_stat64(self._nfs, path, _stat)
        return _stat_to_dict(_stat)

    def lstat(self, path):
        _stat = nfs_stat_64()
        nfs_lstat64(self._nfs, path, _stat)
        return _stat_to_dict(_stat)

def open(url, mode='r'):
    return NFSFH(None, url, mode=mode)

