# -*- coding: utf-8 -*-
from __future__ import absolute_import, division, print_function, unicode_literals
from builtins import *
from future.utils import raise_from
import ttmake.private.messages as messages
import ttmake.private.metadata as metadata
from ttmake.private.exceptionclasses import ColoredError
from ttmake.private.movedirective import MoveList
from ttmake.private.utility import get_path, format_message
from ttmake.write_logs import write_to_makelog

import os
import traceback

from termcolor import colored
import colorama
colorama.init()


def _create_links(paths,
                  file_list,
                  makedirs=True):
    """.. Create symlinks from list of files containing linking instructions.

    Create symbolic links using instructions contained in files of list ``file_list``.
    Instructions are `string formatted <https://docs.python.org/3.4/library/string.html#format-string-syntax>`__
    using paths dictionary ``paths``. Symbolic links are written in directory ``move_dir``.
    Status messages are appended to file ``makelog``.

    Parameters
    ----------
    paths : dict
        Dictionary of paths. Dictionary should contain values for all keys listed below.
        Dictionary additionally used to string format linking instructions.
    file_list : str, list
        File or list of files containing linking instructions.

    Path Keys
    ---------
    move_dir : str
        Directory to write links.
    makelog : str
        Path of makelog.

    Returns
    -------
    move_map : list
        List of (source, destination) for each symlink created.
    """

    move_dir = get_path(paths, 'move_dir')

    move_list = MoveList(file_list, move_dir, paths)
    if move_list.move_directive_list:
        if makedirs:
            os.makedirs(move_dir)
        move_map = move_list.create_symlinks()
    else:
        move_map = []

    return(move_map)


def _create_copies(paths,
                   file_list):
    """.. Create copies from list of files containing copying instructions.

    Create copies using instructions contained in files of list ``file_list``.
    Instructions are `string formatted <https://docs.python.org/3.4/library/string.html#format-string-syntax>`__
    using paths dictionary ``paths``. Copies are written in directory ``move_dir``.
    Status messages are appended to file ``makelog``.

    Parameters
    ----------
    paths : dict
        Dictionary of paths. Dictionary should contain values for all keys listed below.
        Dictionary additionally used to string format copying instructions.
    file_list : str, list
        File or list of files containing copying instructions.

    Path Keys
    ---------
    move_dir : str
        Directory to write copies.
    makelog : str
        Path of makelog.

    Returns
    -------
    move_map : list
        List of (source, destination) for each copy created.
    """

    move_dir = get_path(paths, 'move_dir')

    move_list = MoveList(file_list, move_dir, paths)
    if move_list.move_directive_list:
        os.makedirs(move_dir)
        move_map = move_list.create_copies()
    else:
        move_map = []

    return(move_map)


def _create_link_copies(paths,
                        file_list):
    """.. Create copies from destination to source and then symlink back
    to destination from list of files containing copying instructions.

    Create copies and symlinks using instructions contained in files of list ``file_list``.
    Instructions are `string formatted <https://docs.python.org/3.4/library/string.html#format-string-syntax>`__
    using paths dictionary ``paths``. Copies are written in directory ``move_dir``.
    Status messages are appended to file ``makelog``.

    Parameters
    ----------
    paths : dict
        Dictionary of paths. Dictionary should contain values for all keys listed below.
        Dictionary additionally used to string format copying instructions.
    file_list : str, list
        File or list of files containing copying instructions.

    Path Keys
    ---------
    move_dir : str
        Directory to write copies.
    makelog : str
        Path of makelog.

    Returns
    -------
    move_map : list
        List of (source, destination) for each copy created.
    """

    move_dir = get_path(paths, 'move_dir')

    move_list = MoveList(file_list, move_dir, paths, reverse=True)
    if move_list.move_directive_list:
        move_map = move_list.create_link_copies()
    else:
        move_map = []

    return(move_map)


def link_inputs(paths,
                file_list):
    """.. Create symlinks to inputs from list of files containing linking instructions.

    Create symbolic links using instructions contained in files of list ``file_list``.
    Instructions are `string formatted <https://docs.python.org/3.4/library/string.html#format-string-syntax>`__
    using paths dictionary ``paths``. Symbolic links are written in directory ``input_dir``.
    Status messages are appended to file ``makelog``.

    Instruction files on how to create symbolic links (destinations) from targets (sources)
    should be formatted in the following way.

    .. code-block:: md

        # Each line of instruction should contain a destination and source delimited by a `|`
        # Lines beginning with # are ignored
        destination | source

    .. Note::
        Symbolic links can be created to both files and directories.

    .. Note::
        Instruction files can be specified with the * shell pattern
        (see `here <https://www.gnu.org/software/findutils/manual/html_node/find_html/Shell-Pattern-Matching.html>`__).
        Destinations and their sources can also be specified with the * shell pattern.
        The number of wildcards must be the same for both destinations and sources.

    Parameters
    ----------
    paths : dict
        Dictionary of paths. Dictionary should contain values for all keys listed below.
        Dictionary additionally used to string format linking instructions.
    file_list : str, list
        File or list of files containing linking instructions.

    Path Keys
    ---------
    input_dir : str
       Directory to write symlinks.
    makelog : str
       Path of makelog.

    Returns
    -------
    move_map : list
        List of (source, destination) for each symlink created.

    Example
    -------
    Suppose you call the following function.

    .. code-block:: python

        link_inputs(paths, ['file1'])

    Suppose ``paths`` contained the following values.

    .. code-block:: md

        paths = {'root': '/User/root/',
                 'makelog': 'make.log',
                 'input_dir': 'input'}

    Now suppose instruction file ``file1`` contained the following text.

    .. code-block:: md

        destination1 | {root}/source1

    The ``{root}`` in the instruction file would be string formatted using ``paths``.
    Therefore, the function would parse the instruction as:

    .. code-block:: md

        destination1 | /User/root/source1

    Symbolic link ``destination1`` would be created in directory ``paths['input_dir']``.
    Its target would be ``/User/root/source1``.

    Example
    -------
    The following code would use instruction files ``file1`` and ``file2`` to create symbolic links.

    .. code-block:: python

        link_inputs(paths, ['file1', 'file2'])

    Suppose instruction file ``file1`` contained the following text.

    .. code-block:: md

        destination1 | source1
        destination2 | source2

    Symbolic links ``destination1`` and ``destination2`` would be created in directory ``paths['input_dir']``.
    Their targets would be ``source1`` and ``source2``, respectively.

    Example
    -------
    Suppose you have the following targets.

    .. code-block:: md

        source1
        source2
        source3

    Specifying ``destination* | source*`` in one of your instruction files would
    create the following symbolic links in ``paths['input_dir']``.

    .. code-block:: md

        destination1
        destination2
        destination3
    """

    try:
        paths['move_dir'] = get_path(paths, 'input_dir')
        move_map = _create_links(paths, file_list)

        if move_map:
            message = messages.success_link_inputs
            write_to_makelog(paths, message)
            print(colored(message, metadata.color_success))
        else:
            print(colored(messages.no_move_map % file_list))

        return(move_map)
    except:
        error_message = format_message(messages.error_message % 'link_inputs')
        write_to_makelog(paths, error_message +
                         '\n\n' + traceback.format_exc())
        raise_from(ColoredError(error_message, traceback.format_exc()), None)


def link_externals(paths,
                   file_list):
    """.. Create symlinks to externals from list of files containing linking instructions.

    Create symbolic links using instructions contained in files of list ``file_list``.
    Instructions are `string formatted <https://docs.python.org/3.4/library/string.html#format-string-syntax>`__
    using paths dictionary ``paths``. Symbolic links are written in directory ``external_dir``.
    Status messages are appended to file ``makelog``.

    Instruction files on how to create symbolic links (destinations) from targets (sources)
    should be formatted in the following way.

    .. code-block:: md

        # Each line of instruction should contain a destination and source delimited by a `|`
        # Lines beginning with # are ignored
        destination | source

    .. Note::
        Symbolic links can be created to both files and directories.

    .. Note::
        Instruction files can be specified with the * shell pattern
        (see `here <https://www.gnu.org/software/findutils/manual/html_node/find_html/Shell-Pattern-Matching.html>`__).
        Destinations and their sources can also be specified with the * shell pattern.
        The number of wildcards must be the same for both destinations and sources.

    Parameters
    ----------
    paths : dict
        Dictionary of paths. Dictionary should contain values for all keys listed below.
        Dictionary additionally used to string format linking instructions.
    file_list : str, list
        File or list of files containing linking instructions.

    Path Keys
    ---------
    external_dir : str
       Directory to write symlinks.
    makelog : str
       Path of makelog.

    Returns
    -------
    source_map : list
        List of (source, destination) for each symlink created.

    Example
    -------
    Suppose you call the following function.

    .. code-block:: python

        link_externals(paths, ['file1'])

    Suppose ``paths`` contained the following values.

    .. code-block:: md

        paths = {'root': '/User/root/',
                 'makelog': 'make.log',
                 'external_dir': 'external'}

    Now suppose instruction file ``file1`` contained the following text.

    .. code-block:: md

        destination1 | {root}/source1

    The ``{root}`` in the instruction file would be string formatted using ``paths``.
    Therefore, the function would parse the instruction as:

    .. code-block:: md

        destination1 | /User/root/source1

    Symbolic link ``destination1`` would be created in directory ``paths['external_dir']``.
    Its target would be ``/User/root/source1``.

    Example
    -------
    The following code would use instruction files ``file1`` and ``file2`` to create symbolic links.

    .. code-block:: python

        link_externals(paths, ['file1', 'file2'])

    Suppose instruction file ``file1`` contained the following text.

    .. code-block:: md

        destination1 | source1
        destination2 | source2

    Symbolic links ``destination1`` and ``destination2`` would be created in directory ``paths['external_dir']``.
    Their targets would be ``source1`` and ``source2``, respectively.

    Example
    -------
    Suppose you have the following targets.

    .. code-block:: md

        source1
        source2
        source3

    Specifying ``destination* | source*`` in one of your instruction files would
    create the following symbolic links in ``paths['external_dir']``.

    .. code-block:: md

        destination1
        destination2
        destination3
    """

    try:
        paths['move_dir'] = get_path(paths, 'external_dir')
        move_map = _create_links(paths, file_list)

        if move_map:
            message = messages.success_link_externals
            write_to_makelog(paths, message)
            print(colored(message, metadata.color_success))
        else:
            print(colored(messages.no_move_map % file_list))

        return(move_map)
    except:
        error_message = format_message(
            messages.error_message % 'link_externals')
        write_to_makelog(paths, error_message +
                         '\n\n' + traceback.format_exc())
        raise_from(ColoredError(error_message, traceback.format_exc()), None)


def link_outputs(paths,
                 file_list):
    """.. Create symlinks to outputs from list of files containing linking instructions.

    Create symbolic links using instructions contained in files of list ``file_list``.
    Instructions are `string formatted <https://docs.python.org/3.4/library/string.html#format-string-syntax>`__
    using paths dictionary ``paths``. Symbolic links are written in directory ``output_local_dir``.
    Status messages are appended to file ``makelog``.

    Instruction files on how to create symbolic links (destinations) from targets (sources)
    should be formatted in the following way.

    .. code-block:: md

        # Each line of instruction should contain a destination and source delimited by a `|`
        # Lines beginning with # are ignored
        destination | source

    .. Note::
        Symbolic links can be created to both files and directories.

    .. Note::
        Instruction files can be specified with the * shell pattern
        (see `here <https://www.gnu.org/software/findutils/manual/html_node/find_html/Shell-Pattern-Matching.html>`__).
        Destinations and their sources can also be specified with the * shell pattern.
        The number of wildcards must be the same for both destinations and sources.

    Parameters
    ----------
    paths : dict
        Dictionary of paths. Dictionary should contain values for all keys listed below.
        Dictionary additionally used to string format linking instructions.
    file_list : str, list
        File or list of files containing linking instructions.

    Path Keys
    ---------
    output_local_dir : str
       Directory to write symlinks.
    makelog : str
       Path of makelog.

    Returns
    -------
    source_map : list
        List of (source, destination) for each symlink created.

    Example
    -------
    Suppose you call the following function.

    .. code-block:: python

        link_outputs(paths, ['file1'])

    Suppose ``paths`` contained the following values.

    .. code-block:: md

        paths = {'root': '/User/root/',
                 'makelog': 'make.log',
                 'output_local_dir': 'output_local'}

    Now suppose instruction file ``file1`` contained the following text.

    .. code-block:: md

        destination1 | {root}/source1

    The ``{root}`` in the instruction file would be string formatted using ``paths``.
    Therefore, the function would parse the instruction as:

    .. code-block:: md

        destination1 | /User/root/source1

    Symbolic link ``destination1`` would be created in directory ``paths['output_local_dir']``.
    Its target would be ``/User/root/source1``.

    Example
    -------
    The following code would use instruction files ``file1`` and ``file2`` to create symbolic links.

    .. code-block:: python

        link_outputs(paths, ['file1', 'file2'])

    Suppose instruction file ``file1`` contained the following text.

    .. code-block:: md

        destination1 | source1
        destination2 | source2

    Symbolic links ``destination1`` and ``destination2`` would be created in directory ``paths['output_local_dir']``.
    Their targets would be ``source1`` and ``source2``, respectively.

    Example
    -------
    Suppose you have the following targets.

    .. code-block:: md

        source1
        source2
        source3

    Specifying ``destination* | source*`` in one of your instruction files would
    create the following symbolic links in ``paths['output_local_dir']``.

    .. code-block:: md

        destination1
        destination2
        destination3
    """

    try:
        paths['move_dir'] = get_path(paths, 'output_local_dir')
        move_map = _create_links(paths, file_list)

        if move_map:
            message = messages.success_link_outputs
            write_to_makelog(paths, message)
            print(colored(message, metadata.color_success))
        else:
            print(colored(messages.no_move_map % file_list))

        return(move_map)
    except:
        error_message = format_message(
            messages.error_message % 'link_outputs')
        write_to_makelog(paths, error_message +
                         '\n\n' + traceback.format_exc())
        raise_from(ColoredError(error_message, traceback.format_exc()), None)


def copy_inputs(paths,
                file_list):
    """.. Create copies to inputs from list of files containing copying instructions.

    Create copies using instructions contained in files of list ``file_list``.
    Instructions are `string formatted <https://docs.python.org/3.4/library/string.html#format-string-syntax>`__
    using paths dictionary ``paths``. Copies are written in directory ``input_dir``.
    Status messages are appended to file ``makelog``.

    Instruction files on how to create copies (destinations) from targets (sources)
    should be formatted in the following way.

    .. code-block:: md

        # Each line of instruction should contain a destination and source delimited by a `|`
        # Lines beginning with # are ignored
        destination | source

    .. Note::
        Instruction files can be specified with the * shell pattern
        (see `here <https://www.gnu.org/software/findutils/manual/html_node/find_html/Shell-Pattern-Matching.html>`__).
        Destinations and their sources can also be specified with the * shell pattern.
        The number of wildcards must be the same for both destinations and sources.

    Parameters
    ----------
    paths : dict
        Dictionary of paths. Dictionary should contain values for all keys listed below.
        Dictionary additionally used to string format copying instructions.
    file_list : str, list
        File or list of files containing copying instructions.

    Path Keys
    ---------
    input_dir : str
       Directory to write copies.
    makelog : str
       Path of makelog.

    Returns
    -------
    source_map : list
        List of (source, destination) for each copy created.

    Example
    -------
    Suppose you call the following function.

    .. code-block:: python

        copy_inputs(paths, ['file1'])

    Suppose ``paths`` contained the following values.

    .. code-block:: md

        paths = {'root': '/User/root/',
                 'makelog': 'make.log',
                 'input_dir': 'input'}

    Now suppose instruction file ``file1`` contained the following text.

    .. code-block:: md

        destination1 | {root}/source1

    The ``{root}`` in the instruction file would be string formatted using ``paths``.
    Therefore, the function would parse the instruction as:

    .. code-block:: md

        destination1 | /User/root/source1

    A copy of ``/User/root/source1`` will be created as ``destination1``
    in directory ``paths['input_dir']``.

    Example
    -------
    The following code would use instruction files ``file1`` and ``file2`` to create copies.

    .. code-block:: python

        copy_inputs(paths, ['file1', 'file2'])

    Suppose instruction file ``file1`` contained the following text.

    .. code-block:: md

        destination1 | source1
        destination2 | source2

    Copies ``destination1`` and ``destination2`` would be created in directory ``paths['input_dir']``.
    Their targets would be ``source1`` and ``source2``, respectively.

    Example
    -------
    Suppose you have the following targets.

    .. code-block:: md

        source1
        source2
        source3

    Specifying ``destination* | source*`` in one of your instruction files would
    create the following copies in ``paths['input_dir']``.

    .. code-block:: md

        destination1
        destination2
        destination3
    """

    try:
        paths['move_dir'] = get_path(paths, 'input_dir')
        move_map = _create_copies(paths, file_list)

        if move_map:
            message = messages.success_copy_inputs
            write_to_makelog(paths, message)
            print(colored(message, metadata.color_success))
        else:
            print(colored(messages.no_move_map % file_list))

        return(move_map)
    except:
        error_message = format_message(
            messages.error_message % 'copy_inputs')
        write_to_makelog(paths, error_message +
                         '\n\n' + traceback.format_exc())
        raise_from(ColoredError(error_message, traceback.format_exc()), None)


def copy_externals(paths,
                   file_list):
    """.. Create copies to externals from list of files containing copying instructions.

    Create copies using instructions contained in files of list ``file_list``.
    Instructions are `string formatted <https://docs.python.org/3.4/library/string.html#format-string-syntax>`__
    using paths dictionary ``paths``. Copies are written in directory ``external_dir``.
    Status messages are appended to file ``makelog``.

    Instruction files on how to create copies (destinations) from targets (sources)
    should be formatted in the following way.

    .. code-block:: md

        # Each line of instruction should contain a destination and source delimited by a `|`
        # Lines beginning with # are ignored
        destination | source

    .. Note::
        Instruction files can be specified with the * shell pattern
        (see `here <https://www.gnu.org/software/findutils/manual/html_node/find_html/Shell-Pattern-Matching.html>`__).
        Destinations and their sources can also be specified with the * shell pattern.
        The number of wildcards must be the same for both destinations and sources.

    Parameters
    ----------
    paths : dict
        Dictionary of paths. Dictionary should contain values for all keys listed below.
        Dictionary additionally used to string format copying instructions.
    file_list : str, list
        File or list of files containing copying instructions.

    Path Keys
    ---------
    external_dir : str
       Directory to write copies.
    makelog : str
       Path of makelog.

    Returns
    -------
    source_map : list
        List of (source, destination) for each copy created.

    Example
    -------
    Suppose you call the following function.

    .. code-block:: python

        copy_externals(paths, ['file1'])

    Suppose ``paths`` contained the following values.

    .. code-block:: md

        paths = {'root': '/User/root/',
                 'makelog': 'make.log',
                 'input_dir': 'input'}

    Now suppose instruction file ``file1`` contained the following text.

    .. code-block:: md

        destination1 | {root}/source1

    The ``{root}`` in the instruction file would be string formatted using ``paths``.
    Therefore, the function would parse the instruction as:

    .. code-block:: md

        destination1 | /User/root/source1

    A copy of ``/User/root/source1`` will be created as ``destination1``
    in directory ``paths['external_dir']``.

    Example
    -------
    The following code would use instruction files ``file1`` and ``file2`` to create copies.

    .. code-block:: python

        copy_externals(paths, ['file1', 'file2'])

    Suppose instruction file ``file1`` contained the following text.

    .. code-block:: md

        destination1 | source1
        destination2 | source2

    Copies ``destination1`` and ``destination2`` would be created in directory ``paths['external_dir']``.
    Their targets would be ``source1`` and ``source2``, respectively.

    Example
    -------
    Suppose you have the following targets.

    .. code-block:: md

        source1
        source2
        source3

    Specifying ``destination* | source*`` in one of your instruction files would
    create the following copies in ``paths['external_dir']``.

    .. code-block:: md

        destination1
        destination2
        destination3
    """

    try:
        paths['move_dir'] = get_path(paths, 'external_dir')
        move_map = _create_copies(paths, file_list)

        if move_map:
            message = messages.success_copy_externals
            write_to_makelog(paths, message)
            print(colored(message, metadata.color_success))
        else:
            print(colored(messages.no_move_map % file_list))

        return(move_map)
    except:
        error_message = format_message(
            messages.error_message % 'copy_externals')
        write_to_makelog(paths, error_message +
                         '\n\n' + traceback.format_exc())
        raise_from(ColoredError(error_message, traceback.format_exc()), None)


def copy_link_outputs(paths,
                      file_list):
    """.. Create external copies of outputs from output_local and symlinks back to output_local from list of files containing linking instructions.

    Create copies and symbolic links using instructions contained in files of list ``file_list``.
    Instructions are `string formatted <https://docs.python.org/3.4/library/string.html#format-string-syntax>`__
    using paths dictionary ``paths``. Copies are created in the specified external locations
    and symbolic links are re-written in directory ``output_local_dir``.
    Status messages are appended to file ``makelog``.

    Instruction files on how to create targets/external copies to (sources) and
    create symbolic links (destinations) back from targets (sources) should be
    formatted in the following way.

    .. code-block:: md

        # Each line of instruction should contain a destination and source delimited by a `|`
        # Lines beginning with # are ignored
        destination | source

    .. Note::
        Symbolic links can be created to both files and directories.

    .. Note::
        Instruction files can be specified with the * shell pattern
        (see `here <https://www.gnu.org/software/findutils/manual/html_node/find_html/Shell-Pattern-Matching.html>`__).
        Destinations and their sources can also be specified with the * shell pattern.
        The number of wildcards must be the same for both destinations and sources.

    Parameters
    ----------
    paths : dict
        Dictionary of paths. Dictionary should contain values for all keys listed below.
        Dictionary additionally used to string format linking instructions.
    file_list : str, list
        File or list of files containing linking instructions.

    Path Keys
    ---------
    output_local_dir : str
       Directory to write symlinks.
    makelog : str
       Path of makelog.

    Returns
    -------
    move_map : list
        List of (source, destination) for each copy/symlink created.

    Example
    -------
    Suppose you call the following function.

    .. code-block:: python

        link_outputs(paths, ['file1'])

    Suppose ``paths`` contained the following values.

    .. code-block:: md

        paths = {'root': '/User/root/',
                 'makelog': 'make.log',
                 'output_local_dir': 'output_local'}

    Now suppose instruction file ``file1`` contained the following text.

    .. code-block:: md

        destination1 | {root}/source1

    The ``{root}`` in the instruction file would be string formatted using ``paths``.
    Therefore, the function would parse the instruction as:

    .. code-block:: md

        destination1 | /User/root/source1

    A copy of ``destination1`` in ``paths['output_local_dir']`` will be created as ``User/root/source1`` and
    symbolic link ``destination1`` would be created in directory ``paths['output_local_dir']``.
    The target of the symbolic link would be ``/User/root/source1``.

    Example
    -------
    The following code would use instruction files ``file1`` and ``file2`` to
    create copies and replace with symbolic links.

    .. code-block:: python

        link_outputs(paths, ['file1', 'file2'])

    Suppose instruction file ``file1`` contained the following text.

    .. code-block:: md

        destination1 | source1
        destination2 | source2

    Copies of ``destination1`` and ``destination1`` from ``paths['output_local_dir']``
    will be created as ``source1`` and ``source2`` respectively.
    Symbolic links ``destination1`` and ``destination1`` would be created in
    directory ``paths['output_local_dir']``.
    Their targets would be ``source1`` and ``source2``, respectively.

    Example
    -------
    Suppose you have the following files in ``paths['output_local_dir']``:

    .. code-block:: md

        destination1
        destination2
        destination3

    Specifying ``destination* | source*`` in one of your instruction files would
    copy all ``destination1`` as ``source1``, ``destination2`` as ``source2``
    and ``destination3`` as ``source3`` and replace them with the following
    symbolic links in ``paths['output_local_dir']``.

    .. code-block:: md

        destination1
        destination2
        destination3
    """

    try:
        paths['move_dir'] = get_path(paths, 'output_local_dir')
        move_map = _create_link_copies(paths, file_list)

        if move_map:
            message = messages.success_copy_link_outputs
            write_to_makelog(paths, message)
            print(colored(message, metadata.color_success))
        else:
            print(colored(messages.no_move_map % file_list))

        return(move_map)
    except:
        error_message = format_message(
            messages.error_message % 'copy_link_outputs')
        write_to_makelog(paths, error_message +
                         '\n\n' + traceback.format_exc())
        raise_from(ColoredError(error_message, traceback.format_exc()), None)


__all__ = ['link_inputs', 'link_externals', 'link_outputs',
           'copy_inputs', 'copy_externals', 'copy_link_outputs']
