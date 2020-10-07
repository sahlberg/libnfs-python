/*
   Copyright (C) 2014 by Ronnie Sahlberg <ronniesahlberg@gmail.com>

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU Lesser General Public License as published by
   the Free Software Foundation; either version 2.1 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public License
   along with this program; if not, see <http://www.gnu.org/licenses/>.
*/

/*
Update: 10/7/2020
   - Comment out nfs_mkdir2 and nfs_readlink2 to avoid build issues.
*/

%module libnfs

%{
#include <nfsc/libnfs.h>
%}

%include <stdint.i>
%include <cpointer.i>
%pointer_functions(struct nfsfh *, NFSFileHandle)
%pointer_functions(uint64_t, uint64_t_ptr)
%pointer_functions(struct nfsdir *, NFSDirHandle)
%include <carrays.i>
%array_functions(struct timeval, TimeValArray)

%include <pybuffer.i>
%pybuffer_mutable_string(char *buff);

/* Map char ** to Python list
 *
 * This is based on http://www.swig.org/Doc1.3/Python.html#Python_nn59
 * and is intended to deal with cases where a caller has a char *buf,
 * passes &buf in order to have the function return a pointer.
 *
 *  extern void nfs_getcwd(struct nfs_context *nfs, const char **cwd);
 *
 * The approach taken here is to retain the general form of the
 * function signature, and model the output parameter using a
 * Python list which will be modified to return the result.
 * This allows the caller to use the idiom:
 *
 *  cwd = []
 *  nfs_getcwd(nfs, cwd)
 *  print cwd[0]
 */
%typemap(in) char ** (char *buf = NULL) {
    if (!PyList_Check($input)) {
        PyErr_SetString(PyExc_TypeError,"not a list");
        SWIG_fail;
    } else {
        if (PyList_SetSlice($input, 0, PyList_Size($input), NULL)) {
            SWIG_fail;
        }
    }
    $1 = &buf;
}
%typemap(argout) char ** {
    if (*$1 != NULL) {
        int rc;
        PyObject *symlink = PyString_FromString(*$1);
        if (symlink == NULL)
            SWIG_fail;
        rc = PyList_Insert($input, 0, symlink);
        Py_DECREF(symlink);
        if (rc)
            SWIG_fail;
    }
}
%typemap(freearg) char ** {
    if ($1 != NULL)
        free(*$1);
}

struct rpc_context;
struct nfs_context;
struct AUTH;
struct nfsfh;

struct timeval {
        uint64_t tv_sec;
        uint64_t tv_usec;
};

struct nfs_url {
	char *server;
	char *path;
	char *file;
};

struct nfs_stat_64 {
	uint64_t nfs_dev;
	uint64_t nfs_ino;
	uint64_t nfs_mode;
	uint64_t nfs_nlink;
	uint64_t nfs_uid;
	uint64_t nfs_gid;
	uint64_t nfs_rdev;
	uint64_t nfs_size;
	uint64_t nfs_blksize;
	uint64_t nfs_blocks;
	uint64_t nfs_atime;
	uint64_t nfs_mtime;
	uint64_t nfs_ctime;
	uint64_t nfs_atime_nsec;
	uint64_t nfs_mtime_nsec;
	uint64_t nfs_ctime_nsec;
	uint64_t nfs_used;
};

struct nfsdir;

struct nfsdirent  {
       struct nfsdirent *next;
       char *name;
       uint64_t inode;

       /* Some extra fields we get for free through the READDIRPLUS3 call.
	  You need libnfs-raw-nfs.h for type/mode constants */
       uint32_t type; /* NF3REG, NF3DIR, NF3BLK, ... */
       uint32_t mode;
       uint64_t size;
       struct timeval atime;
       struct timeval mtime;
       struct timeval ctime;
       uint32_t uid;
       uint32_t gid;
       uint32_t nlink;
       uint64_t dev;
       uint64_t rdev;
       uint64_t blksize;
       uint64_t blocks;
       uint64_t used;
       uint32_t atime_nsec;
       uint32_t mtime_nsec;
       uint32_t ctime_nsec;
};

struct nfs_server_list {
       struct nfs_server_list *next;
       char *addr;
};

extern struct nfs_context *nfs_init_context(void);
extern void nfs_destroy_context(struct nfs_context *nfs);
extern char *nfs_get_error(struct nfs_context *nfs);
extern void nfs_set_auth(struct nfs_context *nfs, struct AUTH *auth);
extern struct nfs_url *nfs_parse_url_full(struct nfs_context *nfs, const char *url);
extern struct nfs_url *nfs_parse_url_dir(struct nfs_context *nfs, const char *url);
extern struct nfs_url *nfs_parse_url_incomplete(struct nfs_context *nfs, const char *url);
extern void nfs_destroy_url(struct nfs_url *url);
extern uint64_t nfs_get_readmax(struct nfs_context *nfs);
extern uint64_t nfs_get_writemax(struct nfs_context *nfs);
extern void nfs_set_tcp_syncnt(struct nfs_context *nfs, int v);
extern void nfs_set_uid(struct nfs_context *nfs, int uid);
extern void nfs_set_gid(struct nfs_context *nfs, int gid);
extern void nfs_set_readahead(struct nfs_context *nfs, uint32_t v);

extern int nfs_mount(struct nfs_context *nfs, const char *server, const char *exportname);
extern int nfs_stat64(struct nfs_context *nfs, const char *path, struct nfs_stat_64 *st);
extern int nfs_lstat64(struct nfs_context *nfs, const char *path, struct nfs_stat_64 *st);
extern int nfs_fstat64(struct nfs_context *nfs, struct nfsfh *nfsfh, struct nfs_stat_64 *st);
extern int nfs_open(struct nfs_context *nfs, const char *path, int flags, struct nfsfh **nfsfh);
extern int nfs_close(struct nfs_context *nfs, struct nfsfh *nfsfh);
extern int nfs_pread(struct nfs_context *nfs, struct nfsfh *nfsfh, uint64_t offset, uint64_t count, char *buff);
extern int nfs_read(struct nfs_context *nfs, struct nfsfh *nfsfh, uint64_t count, char *buff);
extern int nfs_pwrite(struct nfs_context *nfs, struct nfsfh *nfsfh, uint64_t offset, uint64_t count, char *buff);
extern int nfs_write(struct nfs_context *nfs, struct nfsfh *nfsfh, uint64_t count, char *buff);
extern int nfs_lseek(struct nfs_context *nfs, struct nfsfh *nfsfh, int64_t offset, int whence, uint64_t *current_offset);
extern int nfs_fsync(struct nfs_context *nfs, struct nfsfh *nfsfh);
extern int nfs_truncate(struct nfs_context *nfs, const char *path, uint64_t length);
extern int nfs_ftruncate(struct nfs_context *nfs, struct nfsfh *nfsfh, uint64_t length);
extern int nfs_mkdir(struct nfs_context *nfs, const char *path);
/* extern int nfs_mkdir2(struct nfs_context *nfs, const char *path, int mode); */
extern int nfs_rmdir(struct nfs_context *nfs, const char *path);
extern int nfs_creat(struct nfs_context *nfs, const char *path, int mode, struct nfsfh **nfsfh);
extern int nfs_create(struct nfs_context *nfs, const char *path, int flags, int mode, struct nfsfh **nfsfh);
extern int nfs_mknod(struct nfs_context *nfs, const char *path, int mode, int dev);
extern int nfs_unlink(struct nfs_context *nfs, const char *path);
extern int nfs_opendir(struct nfs_context *nfs, const char *path, struct nfsdir **nfsdir);
extern struct nfsdirent *nfs_readdir(struct nfs_context *nfs, struct nfsdir *nfsdir);
extern void nfs_closedir(struct nfs_context *nfs, struct nfsdir *nfsdir);
extern int nfs_chdir(struct nfs_context *nfs, const char *path);
extern void nfs_getcwd(struct nfs_context *nfs, const char **cwd);
extern int nfs_readlink(struct nfs_context *nfs, const char *path, char *buff, int bufsize);
/* extern int nfs_readlink2(struct nfs_context *nfs, const char *path, char **buf); */
extern int nfs_chmod(struct nfs_context *nfs, const char *path, int mode);
extern int nfs_lchmod(struct nfs_context *nfs, const char *path, int mode);
extern int nfs_fchmod(struct nfs_context *nfs, struct nfsfh *nfsfh, int mode);
extern int nfs_chown(struct nfs_context *nfs, const char *path, int uid, int gid);
extern int nfs_lchown(struct nfs_context *nfs, const char *path, int uid, int gid);
extern int nfs_fchown(struct nfs_context *nfs, struct nfsfh *nfsfh, int uid, int gid);
extern int nfs_utimes(struct nfs_context *nfs, const char *path, struct timeval times[2]);
extern int nfs_lutimes(struct nfs_context *nfs, const char *path, struct timeval times[2]);
extern int nfs_utime(struct nfs_context *nfs, const char *path, struct utimbuf *times);
extern int nfs_access(struct nfs_context *nfs, const char *path, int mode);
extern int nfs_symlink(struct nfs_context *nfs, const char *oldpath, const char *newpath);
extern int nfs_rename(struct nfs_context *nfs, const char *oldpath, const char *newpath);
extern int nfs_link(struct nfs_context *nfs, const char *oldpath, const char *newpath);
extern struct exportnode *mount_getexports(const char *server);
extern void mount_free_export_list(struct exportnode *exports);
extern struct nfs_server_list *nfs_find_local_servers(void);
extern void free_nfs_srvr_list(struct nfs_server_list *srv);
extern void nfs_set_timeout(struct nfs_context *nfs, int milliseconds);
extern int nfs_get_timeout(struct nfs_context *nfs);
