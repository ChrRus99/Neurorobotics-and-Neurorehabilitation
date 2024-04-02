# encoding: utf-8
#
# Copyright (C) 2016-2020 Alois Schlögl <alois.schloegl@gmail.com>
#
#    This file is part of the BioSig repository
#    at https://biosig.sourceforge.io/
#
#    BioSig is free software; you can redistribute it and/or
#    modify it under the terms of the GNU General Public License
#    as published by the Free Software Foundation; either version 3
#    of the License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# You need to edit setup.py.in (setup.py is autogenerated) #

# TODO:
#   windows, how to add libbiosig.dll.a and alike
#   https://github.com/lebigot/uncertainties/blob/master/setup.py

try:
    from setuptools import setup, Extension
    from setuptools.command.build_ext import build_ext
except ImportError:
    from distutils.core import setup
    from distutils.extension import Extension

import os
import numpy.distutils.misc_util

link_args = ['-static-libgcc',
             '-static-libstdc++',
             '-Wl,-Bstatic,--whole-archive',
             '-lwinpthread',
             '-Wl,--no-whole-archive']

class Build(build_ext):
    def build_extensions(self):
        if self.compiler.compiler_type == 'mingw32':
            for e in self.extensions:
                e.extra_link_args = link_args
        super(Build, self).build_extensions()

module_biosig = Extension('biosig',
        define_macros = [('MAJOR_VERSION', '1'), ('MINOR_VERSION', '9')],
        include_dirs = ['./..', numpy.distutils.misc_util.get_numpy_include_dirs()[0]],
        libraries    = ['biosig'],
        library_dirs = ['./..','../lib','../win64'],
        sources      = ['biosigmodule.c'])

def read(fname):
    return open(os.path.join(os.path.dirname(__file__), fname)).read()

setup (name = 'Biosig',
        version = '2.4.2',
        description = 'BioSig - tools for biomedical signal processing',
        author = 'Alois Schlögl',
        author_email = 'alois.schloegl@gmail.com',
        license = 'GPLv3+',
        url = 'https://biosig.sourceforge.io',
        #long_description='Import filters of biomedical signal formats',
        long_description=read('README.md'),
        long_description_content_type="text/markdown",
        include_package_data = True,
        keywords = 'EEG ECG EKG EMG EOG Polysomnography ECoG biomedical signals SCP EDF GDF HEKA CFS ABF',
        install_requires=['numpy','setuptools>=6.0'],
        classifiers=[
          'Programming Language :: Python',
          'License :: OSI Approved :: GNU General Public License v3 or later (GPLv3+)',
          'Operating System :: OS Independent'
        ],
        cmdclass={'build_ext': Build},
        ext_modules = [module_biosig]
)
