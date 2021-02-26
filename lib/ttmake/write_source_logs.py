# -*- coding: utf-8 -*-
from __future__ import absolute_import, division, print_function, unicode_literals
from builtins import *
from future.utils import raise_from
import ttmake.private.messages as messages
import ttmake.private.metadata as metadata
from ttmake.private.exceptionclasses import ColoredError
from ttmake.private.utility import norm_path, get_path, glob_recursive, format_message
from ttmake.write_logs import write_to_makelog, _write_stats_log, _write_heads_log, _write_maplog

import os
import io
import traceback

from termcolor import colored
import colorama
colorama.init()


def write_source_logs(paths,
                      source_map,
                      depth=float('inf')):
    """.. Write source logs.

    Logs the following information for sources contained in list ``source_map``
    (returned by :ref:`moving source/output functions<moving source/output functions>`).

    - Mapping of symlinks/copies to sources (in file ``source_maplog``)
    - Details on files contained in sources:

        - File name (in file ``source_statslog``)
        - Last modified (in file ``source_statslog``)
        - File size (in file ``source_statslog``)
        - File head (in file ``source_headlog``, optional)

    When walking through sources, float ``depth`` determines level of depth to walk.
    Status messages are appended to file ``makelog``.

    Parameters
    ----------
    paths : dict
        Dictionary of paths. Dictionary should contain values for all keys listed below.
    source_map : list
        Mapping of symlinks/copies (destination) to sources (returned by :ref:`moving source/output functions<moving source/output functions>`).
    depth : float, optional
        Level of depth when walking through source directories. Defaults to infinite.

    Path Keys
    ---------
    source_statslog : str
       Path to write source statistics log.
    source_headslog : str, optional
       Path to write source headers log.
    source_maplog : str
       Path to write source map log.
    makelog : str
       Path of makelog.

    Returns
    -------
    None

    Example
    -------
    The following code will log information for all files listed in ``source_map``.
    Therefore, files contained in subdirectories listed in ``source_map`` will be ignored.

    .. code-block:: python

        write_source_logs(paths, source_map, depth=1)

    The following code will log information for all files listed in ``source_map``
    and any file in all directories listed in ``source_map``, regardless of level of subdirectory.

    .. code-block :: python

        write_source_logs(paths, source_map, depth=float('inf'))
    """

    try:
        source_statslog = get_path(paths, 'source_statslog')
        source_headslog = get_path(paths, 'source_headslog', throw_error=False)
        source_maplog = get_path(paths, 'source_maplog')

        source_list = [source for source, destination in source_map]
        source_list = [glob_recursive(source, depth) for source in source_list]
        source_files = [f for source in source_list for f in source]
        source_files = set(source_files)

        # TODO: DECIDE WHETHER TO ALLOW FOR RAW DIRECTORY
        raw_dir = get_path(paths, 'raw_dir', throw_error=False)
        if raw_dir:
            raw_files = glob_recursive(raw_dir)
            source_files = set(source_files + raw_files)

        source_files = sorted(source_files)

        if source_statslog:
            source_statslog = norm_path(source_statslog)
            _write_stats_log(source_statslog, source_files)

        if source_headslog:
            source_headslog = norm_path(source_headslog)
            _write_heads_log(source_headslog, source_files)

        if source_maplog:
            source_maplog = norm_path(source_maplog)
            _write_maplog(source_maplog, source_map)

        if source_statslog or source_headslog or source_maplog:
            write_to_makelog(paths, messages.success_source_logs)
            print(colored(messages.success_source_logs, metadata.color_success))
    except:
        error_message = 'Error with `write_source_logs`. Traceback can be found below.'
        error_message = format_message(error_message)
        write_to_makelog(paths, error_message +
                         '\n\n' + traceback.format_exc())
        raise_from(ColoredError(error_message, traceback.format_exc()), None)


__all__ = ['write_source_logs']
