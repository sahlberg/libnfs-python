#!/usr/bin/env python

# Update: 10/7/2020
#   - Package name
#   - Change release and version number


from os import environ
try:
    from setuptools import setup, Extension
    from setuptools.command.build_ext import build_ext
except ImportError:
    from distutils.core import setup, Extension
    from distutils.command.build_ext import build_ext

# Although setuptools supports swig, it fails to copy the generated
# Python wrapper: http://stackoverflow.com/questions/12491328

cmdclass = {}

try:
    from setuptools.command.install import install
except ImportError:
    pass
else:
    class Install(install):
        def run(self):
            self.run_command('build_ext')
            install.run(self)
    cmdclass['install'] = Install


from distutils.command.build import build


class Build(build):
    def run(self):
        self.run_command('build_ext')
        build.run(self)


cmdclass['build'] = Build


name = 'dcc-libnfs-python'
version = '1.0'
release = '5'
versrel = version + '.' + release
readme = 'README'
download_url = "https://github.com/sahlberg/libnfs-python/libnfs-" + \
                                                          versrel + ".tar.gz"
with open(readme, "r") as f:
    long_description = f.read()

_libnfs = Extension(
    name='libnfs._libnfs',
    sources=['libnfs/libnfs.i'],
    swig_opts=['-shadow', '-threads'],
    extra_link_args=['-g'],
    extra_compile_args=['-g'],
    libraries=['nfs'],
)


setup(
    name=name,
    version=versrel,
    description='NFS client for Python.',
    long_description=long_description,
    license='LGPLv2.1',
    platforms=['any'],
    author='Ronnie Sahlberg',
    author_email='ronniesahlberg@gmail.com',
    url='https://github.com/sahlberg/libnfs-python/',
    download_url=download_url,
    packages=['libnfs'],
    classifiers=[
      'Development Status :: 4 - Beta',
      'Intended Audience :: Developers',
      'Operating System :: OS Independent',
      'Programming Language :: C',
      'Programming Language :: Python',
      'Topic :: Software Development :: Libraries :: Python Modules',
      'Topic :: Communications :: File Sharing',
      'Topic :: System :: Filesystems',
    ],
    ext_modules=[_libnfs],
    cmdclass=cmdclass,
)
