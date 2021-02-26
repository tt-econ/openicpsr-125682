# -*- coding: utf-8 -*-
from __future__ import absolute_import, division, print_function, unicode_literals
from builtins import *
from future.utils import raise_from
from ttmake.private.utility import norm_path, get_path, glob_recursive, format_message
from ttmake.private.exceptionclasses import CritError, ColoredError
import ttmake.private.metadata as metadata
import ttmake.private.messages as messages

import os
import io
import datetime
import traceback

from termcolor import colored
import colorama
colorama.init()


def start_makelog(paths):
    """.. Start make log.

    Writes file ``makelog``, recording start time.
    Sets make log status to boolean ``True``, which is used by other functions to confirm make log exists.

    Note
    ----
    The make log start condition is used by other functions to confirm a make log exists.

    Parameters
    ----------
    paths : dict
        Dictionary of paths. Dictionary should contain values for all keys listed below.

    Path Keys
    ---------
    makelog : str
        Path of makelog.

    Returns
    -------
    None
    """

    try:
        makelog = get_path(paths, 'makelog')
        metadata.makelog_started = True

        if makelog:
            makelog = norm_path(makelog)
            message = 'Starting makelog file at: `%s`' % makelog
            print(colored(message, metadata.color_success))

            with io.open(makelog, 'w', encoding='utf8',
                         errors='ignore') as MAKELOG:
                time_start = str(
                    datetime.datetime.now().replace(microsecond=0))
                working_dir = os.getcwd()
                print(messages.note_dash_line, file=MAKELOG)
                print(messages.note_makelog_start + time_start, file=MAKELOG)
                print(messages.note_working_directory +
                      working_dir, file=MAKELOG)
                print(messages.note_dash_line, file=MAKELOG)
    except:
        metadata.makelog_started = False
        error_message = messages.error_message % 'start_makelog'
        error_message = format_message(error_message)
        raise_from(ColoredError(error_message, traceback.format_exc()), None)


def end_makelog(paths):
    """.. End make log.

    Appends to file ``makelog``, recording end time.

    Note
    ----
    We technically allow for writing to a make log even after the make log has ended.
    We do not recommend this for best practice.

    Parameters
    ----------
    paths : dict
        Dictionary of paths. Dictionary should contain values for all keys listed below.

    Path Keys
    ---------
    makelog : str
        Path of makelog.

    Returns
    -------
    None
    """

    try:
        makelog = get_path(paths, 'makelog')

        if makelog:
            makelog = norm_path(makelog)
            message = 'Ending makelog file at: `%s`' % makelog
            print(colored(message, metadata.color_success))

            if not (metadata.makelog_started and os.path.isfile(makelog)):
                metadata.makelog_started = False
                raise_from(
                    CritError(messages.crit_error_no_makelog % makelog), None)

            with io.open(makelog, 'a', encoding='utf8',
                         errors='ignore') as MAKELOG:
                time_end = str(datetime.datetime.now().replace(microsecond=0))
                working_dir = os.getcwd()
                print(messages.note_dash_line, file=MAKELOG)
                print(messages.note_makelog_end + time_end, file=MAKELOG)
                print(messages.note_working_directory +
                      working_dir, file=MAKELOG)
                print(messages.note_dash_line, file=MAKELOG)
            metadata.makelog_started = False
    except:
        metadata.makelog_started = False
        error_message = messages.error_message % 'end_makelog'
        error_message = format_message(error_message)
        raise_from(ColoredError(error_message, traceback.format_exc()), None)


def write_to_makelog(paths, message):
    """.. Write to make log.

    Appends string ``message`` to file ``makelog``.

    Parameters
    ----------
    paths : dict
        Dictionary of paths. Dictionary should contain values for all keys listed below.
    message : str
        Message to append.

    Path Keys
    ---------
    makelog : str
        Path of makelog.

    Returns
    -------
    None
    """

    makelog = get_path(paths, 'makelog')

    if makelog:
        makelog = norm_path(makelog)

        if not (metadata.makelog_started and os.path.isfile(makelog)):
            metadata.makelog_started = False
            raise_from(CritError(messages.crit_error_no_makelog %
                                 makelog), None)

        with io.open(makelog, 'a', encoding='utf8', errors='ignore') as MAKELOG:
            print(message, file=MAKELOG)


def log_files_in_output(paths,
                        output_map={},
                        depth=float('inf')):
    """.. Log files in output directories.

    - Logs the following information for all files contained in directory ``output_dir`` and directory ``output_local_dir`` (optional).

        - File name (in file ``output_statslog``)
        - Last modified (in file ``output_statslog``)
        - File size (in file ``output_statslog``)
        - File head (in file ``output_headslog``, optional)

    - Mapping of symlinks/copies from directory ``output_local_dir`` (optional) typically stored externally using :std:ref:`copy_link_outputs` (in file ``output_maplog``, optional)

    When walking through directories ``output_dir`` and ``output_local_dir``, float ``depth`` determines level of depth to walk.
    Status messages are appended to file ``makelog``.

    Parameters
    ----------
    paths : dict
        Dictionary of paths. Dictionary should contain values for all keys listed below.
    output_map : dict, optional
        Mapping of ``output_local_dir`` (optional) symlinks to external copies (returned by :std:ref:`copy_link_outputs`).
        Defaults to no mappings.
    depth : float, optional
        Level of depth when walking through output directory. Defaults to infinite.

    Path Keys
    ---------
    output_dir : str
       Path of output directory.
    output_local_dir : str, optional
       Path of local output directory (typically for large files to be kept local).
    output_statslog : str
       Path to write output statistics log.
    output_maplog : str, optional
       Path to write output map log.
    output_headslog : str, optional
       Path to write output headers log.
    makelog : str
       Path of makelog.

    Returns
    -------
    None

    Example
    -------
    The following code will log information for all files contained in
    only the first level of ``paths['output_dir']``.
    Therefore, files contained in subdirectories will be ignored.

    .. code-block:: python

        log_files_in_outputs(paths, depth=1)

    The following code will log information for any file in ``paths['output_dir']``,
    regardless of level of subdirectory.

    .. code-block :: python

        log_files_in_outputs(paths, depth=float('inf'))
    """

    try:
        output_dir = get_path(paths, 'output_dir')
        output_statslog = get_path(paths, 'output_statslog')
        output_maplog = get_path(paths, 'output_maplog', throw_error=False)
        output_headslog = get_path(paths, 'output_headslog', throw_error=False)

        output_files = glob_recursive(output_dir, depth)

        if 'output_local_dir' in paths.keys():
            output_local_dir = get_path(paths, 'output_local_dir')
            if output_local_dir:
                output_local_files = glob_recursive(output_local_dir, depth)
                output_files = set(output_files + output_local_files)

        output_files = sorted(output_files)

        if output_statslog:
            output_statslog = norm_path(output_statslog)
            _write_stats_log(output_statslog, output_files)

        if output_maplog:
            output_maplog = norm_path(output_maplog)
            _write_maplog(output_maplog, output_map)

        if output_headslog:
            output_headslog = norm_path(output_headslog)
            _write_heads_log(output_headslog, output_files)

        if output_statslog or output_maplog or output_headslog:
            write_to_makelog(paths, messages.success_output_logs)
            print(colored(messages.success_output_logs, metadata.color_success))
    except:
        error_message = messages.error_message % 'log_files_in_output'
        error_message = format_message(error_message)
        write_to_makelog(paths, error_message + '\n\n' + traceback.format_exc())
        raise_from(ColoredError(error_message, traceback.format_exc()), None)


def _write_stats_log(statslog_file, output_files):
    """.. Write statistics log.

    Logs the following information to ``statslog_file`` for all files contained in list ``output_files``.

    - File name
    - Last modified
    - File size

    Parameters
    ----------
    statslog_file : str
        Path to write statistics log.
    output_files : list
        List of output files to log statistics.

    Returns
    -------
    None
    """

    header = "file name | last modified | file size"

    with io.open(statslog_file, 'w', encoding='utf8',
                 errors='ignore') as STATSLOG:
        print(header, file=STATSLOG)

        for file_name in output_files:
            stats = os.stat(file_name)
            last_mod = datetime.datetime.utcfromtimestamp(round(stats.st_mtime))
            file_size = stats.st_size

            print("%s | %s | %s" %
                  (file_name, last_mod, file_size), file=STATSLOG)


def _write_heads_log(headslog_file, output_files, num_lines=10):
    """.. Write headers log.

    Logs the following information to ``headslog_file`` for all files contained in file list ``output_files``:

    Parameters
    ----------
    headslog_file : str
        Path to write headers log.
    output_files list
        List of output files to log headers.
    num_lines: ``int``, optional
        Number of lines for headers. Default is ``10``.

    Returns
    -------
    None
    """

    header = "File headers"

    with io.open(headslog_file, 'w', encoding='utf8',
                 errors='ignore') as HEADSLOG:
        print(header, file=HEADSLOG)
        print(messages.note_dash_line, file=HEADSLOG)

        for file_name in output_files:
            print("%s" % file_name, file=HEADSLOG)
            print(messages.note_dash_line, file=HEADSLOG)

            try:
                with io.open(file_name, 'r', encoding='utf8',
                             errors='ignore') as f:
                    for i in range(num_lines):
                        line = f.readline().rstrip('\n')
                        print(line, file=HEADSLOG)
            except:
                print("Head not readable or less than %s lines" %
                      num_lines, file=HEADSLOG)
            print(messages.note_dash_line, file=HEADSLOG)


def _write_maplog(maplog, maplist):
    """.. Write link map log.

    Parameters
    ----------
    maplog : str
        Path to write link map log.
    maplist : list
        Mapping of symlinks (returned by `sourcing functions`_).

    Returns
    -------
    None
    """

    header = 'destination | source'

    with io.open(maplog, 'w', encoding='utf-8', errors='ignore') as MAPLOG:
        print(header, file=MAPLOG)

        for source, destination in maplist:
            destination = os.path.relpath(destination)
            print("%s | %s" % (destination, source), file=MAPLOG)


__all__ = ['start_makelog', 'end_makelog',
           'write_to_makelog', 'log_files_in_output']
