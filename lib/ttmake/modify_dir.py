# -*- coding: utf-8 -*-
from __future__ import absolute_import, division, print_function, unicode_literals
from builtins import *
from future.utils import raise_from
from termcolor import colored
import ttmake.private.metadata as metadata
import ttmake.private.messages as messages
from ttmake.private.exceptionclasses import ColoredError, CritError
from ttmake.private.utility import convert_to_list, norm_path, format_message, format_traceback

import os
import sys
if (sys.version_info < (3, 0)) and (os.name == 'nt'):
    import ttmake.private.subprocess_nt as subprocess
else:
    import subprocess
import zipfile
import traceback
import glob

import colorama
colorama.init()


def remove_path(path, option='', quiet=False):
    """.. Remove path using system command.

    Remove path ``path`` using system command. Safely removes symbolic links.
    Path can be specified with the * shell pattern
    (see `here <https://www.gnu.org/software/findutils/manual/html_node/find_html/Shell-Pattern-Matching.html>`__).

    Parameters
    ----------
    path : str
        Path to remove.
    option : str, optional
        Options for system command. Defaults to ``-rf`` for POSIX and ``/s /q`` for NT.
    quiet : bool, optional
        Suppress printing of path removed. Defaults to ``False``.

    Returns
    -------
    None

    Example
    -------
    The following code removes path ``path``.

    .. code-block:: python

        remove_path('path')

    The following code removes all paths beginning with ``path``.

    .. code-block:: python

        remove_path('path*')
    """

    path = norm_path(path)

    if not option:
        option = metadata.default_options[os.name]['rmdir']

    command = metadata.commands[os.name]['rmdir'] % (option, path)
    process = subprocess.Popen(command,
                               shell=True,
                               stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE,
                               universal_newlines=True)
    stdout, stderr = process.communicate()

    if process.returncode != 0:
        error_message = messages.crit_error_remove_path_command % command
        error_message += format_traceback(stderr)
        raise_from(CritError(error_message), None)
    else:
        if not quiet:
            message = 'Removed: `%s`' % path
            print(colored(message, metadata.color_success))


def remove_dir(dir_list, quiet=False):
    """.. Remove directory using system command.

    Remove directories in list ``dir_list`` using system command.
    Safely removes symbolic links. Directories can be specified with the * shell pattern
    (see `here <https://www.gnu.org/software/findutils/manual/html_node/find_html/Shell-Pattern-Matching.html>`__).
    Non-existent paths in list ``dir_list`` are ignored.

    Parameters
    ----------
    dir_list : str, list
        Directory or list of directories to remove.
    quiet : bool, optional
        Suppress printing of directories removed. Defaults to ``False``.

    Returns
    -------
    None

    Example
    -------
    The following code removes directories ``dir1`` and ``dir2``.

    .. code-block:: python

        remove_dir(['dir1', 'dir2'])

    The following code removes directories beginning with ``dir``.

    .. code-block:: python

        remove_dir(['dir1*'])
    """

    try:
        dir_list = convert_to_list(dir_list, 'dir')
        dir_list = [norm_path(dir_path) for dir_path in dir_list]
        dir_list = [d for directory in dir_list for d in glob.glob(directory)]

        for dir_path in dir_list:
            if os.path.isdir(dir_path):
                remove_path(dir_path, quiet=quiet)
            elif os.path.isfile(dir_path):
                raise_from(TypeError(messages.type_error_not_dir %
                                     dir_path), None)
    except:
        error_message = messages.error_message % 'remove_dir'
        error_message = format_message(error_message)
        raise_from(ColoredError(error_message, traceback.format_exc()), None)


def clear_dir(dir_list):
    """.. Clear directory. Create directory if nonexistent.

    Clears all directories in list ``dir_list`` using system command.
    Safely clears symbolic links. Directories can be specified with the * shell pattern
    (see `here <https://www.gnu.org/software/findutils/manual/html_node/find_html/Shell-Pattern-Matching.html>`__).

    Note
    ----
    To clear a directory means to remove all contents of a directory.
    If the directory is nonexistent, the directory is created,
    unless the directory is specified via shell pattern.

    Parameters
    ----------
    dir_list : str, list
        Directory or list of directories to clear.

    Returns
    -------
    None

    Example
    -------
    The following code clears directories ``dir1`` and ``dir2``.

    .. code-block:: python

        clear_dir(['dir1', 'dir2'])

    The following code clears directories beginning with ``dir``.

    .. code-block:: python

        clear_dir(['dir*'])
    """

    try:
        dir_list = convert_to_list(dir_list, 'dir')
        dir_glob = []

        for dir_path in dir_list:
            expand = glob.glob(dir_path)
            expand = expand if expand else [dir_path]
            dir_glob.extend(expand)

        remove_dir(dir_glob, quiet=True)

        for dir_path in dir_glob:
            option = metadata.default_options[os.name]['mkdir']
            command = metadata.commands[os.name]['mkdir'] % (option, dir_path)
            process = subprocess.Popen(command,
                                       shell=True,
                                       stdout=subprocess.PIPE,
                                       stderr=subprocess.PIPE,
                                       universal_newlines=True)
            stdout, stderr = process.communicate()

            if process.returncode != 0:
                error_message = messages.crit_error_mkdir_command % command
                error_message += format_traceback(stderr)
                raise_from(CritError(error_message), None)
            else:
                message = 'Cleared: `%s`' % dir_path
                print(colored(message, metadata.color_success))
    except:
        error_message = messages.error_message % 'clear_dir'
        error_message = format_message(error_message)
        raise_from(ColoredError(error_message, traceback.format_exc()), None)


def unzip(zip_path, output_dir):
    """.. Unzip file to directory.

    Unzips file ``zip_path`` to directory ``output_dir``.

    Parameters
    ----------
    zip_path : str
        Path of file to unzip.
    output_dir : str
        Directory to write outputs of unzipped file.

    Returns
    -------
    None
    """

    try:
        with zipfile.ZipFile(zip_path, allowZip64=True) as z:
            z.extractall(output_dir)
    except:
        error_message = messages.error_message % 'zip_path'
        error_message = format_message(error_message)
        raise_from(ColoredError(error_message, traceback.format_exc()), None)


def zip_dir(source_dir, zip_dest):
    """.. Zip directory to file.

    Zips directory ``source_dir`` to file ``zip_dest``.

    Parameters
    ----------
    source_dir : str
        Path of directory to zip.
    zip_dest : str
        Destination of zip file.

    Returns
    -------
    None
    """

    try:
        with zipfile.ZipFile('%s' % (zip_dest), 'w', zipfile.ZIP_DEFLATED, allowZip64=True) as z:
            source_dir = norm_path(source_dir)

            for root, dirs, files in os.walk(source_dir):
                for f in files:
                    file_path = os.path.join(root, f)
                    file_name = os.path.basename(file_path)
                    z.write(file_path, file_name)

                    message = 'Zipped: `%s` as `%s`' % (file_path, file_name)
                    print(colored(message, metadata.color_success))
    except:
        error_message = messages.error_message % 'zip_dir'
        error_message = format_message(error_message)
        raise_from(ColoredError(error_message, traceback.format_exc()), None)


__all__ = ['remove_dir', 'clear_dir', 'unzip', 'zip_dir']
