#!/usr/bin/env python
from os import environ

try:
    from setuptools import setup, Extension
    from setuptools.command.build_ext import build_ext
except ImportError:
    from distutils.core import setup, Extension
    from distutils.command.build_ext import build_ext


name = 'libnfs'
version = '1.0'
release = '4'
versrel = version + '-' + release
readme = 'README'
download_url = "https://github.com/sahlberg/libnfs-python/libnfs-" + \
                                                          versrel + ".tar.gz"
with open(readme, "r") as f:
    long_description = f.read()

_libnfs = Extension(name='libnfs._libnfs',
                   sources=['libnfs/libnfs_wrap.c'],
                   libraries=['nfs'],
)


setup(name = name,
      version = versrel,
      description = 'NFS client for Python.',
      long_description = long_description,
      license = 'LGPLv2.1',
      platforms = ['any'],
      author = 'Ronnie Sahlberg',
      author_email = 'ronniesahlberg@gmail.com',
      url = 'https://github.com/sahlberg/libnfs-python/',
      download_url = download_url,
      packages = ['libnfs'],
      classifiers = [
          'Development Status :: 4 - Beta',
          'Intended Audience :: Developers',
          'Operating System :: OS Independent',
          'Programming Language :: C',
          'Programming Language :: Python',
          'Topic :: Software Development :: Libraries :: Python Modules',
          'Topic :: Communications :: File Sharing',
          'Topic :: System :: Filesystems',
      ],
      ext_modules = [_libnfs],
      )
