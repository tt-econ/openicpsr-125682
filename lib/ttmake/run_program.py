# -*- coding: utf-8 -*-
from __future__ import absolute_import, division, print_function, unicode_literals
from builtins import *
from future.utils import raise_from
from ttmake.write_logs import write_to_makelog
from ttmake.private.utility import get_path, format_message, norm_path
from ttmake.private.programdirective import Directive, ProgramDirective, SASDirective, LyXDirective
from ttmake.private.exceptionclasses import CritError, ColoredError, ProgramError
import ttmake.private.metadata as metadata
import ttmake.private.messages as messages

import os
import re
import traceback
import shutil
import fileinput
import sys
import nbformat
from nbconvert.preprocessors import ExecutePreprocessor
# See https://github.com/jupyter/nbconvert/issues/1372
# See https://bugs.python.org/issue37373 :(
if sys.version_info[0] == 3 and sys.version_info[1] >= 8 and sys.platform.startswith('win'):
    import asyncio
    asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())

from termcolor import colored
import colorama
colorama.init()


def run_latex(paths, program, program_cwd=True, clean=False, **kwargs):
    """.. Run LaTeX script using system command.

    An alternative wrapper of the :py:func:`run_tex` command
    """

    run_tex(paths, program, program_cwd, clean, **kwargs)


def run_tex(paths, program, program_cwd=True, clean=False, **kwargs):
    """.. Run LaTeX script using system command.

    Compiles document ``program`` using system command, with document specified
    in the form of ``script.tex``. Status messages are appended to file ``makelog``.
    PDF outputs are written in directory ``output_local_dir``.

    Parameters
    ----------
    paths : dict
        Dictionary of paths. Dictionary should contain values for all keys listed below.
    clean : `bool`
        If True will clean existing auxiliary files without compiling a new PDF file
        Defaults to ``False``.
    program : str
        Path of script to run.
    program_cwd : `bool`
        If True will change the working directory to that of the program before
        running the program, and otherwise use the current working directory
        where the function is called.
        Defaults to ``True``.

    Path Keys
    ---------
    makelog : str
        Path of makelog.
    output_local_dir : str
        Directory to write PDFs.

    Note
    ----
    We recommend leaving all other parameters to their defaults.

    Other Parameters
    ----------------
    osname : str, optional
        Name of OS. Used to determine syntax of system command. Defaults to ``os.name``.
    shell : `bool`, optional
        See `here <https://docs.python.org/3/library/subprocess.html#frequently-used-arguments>`_.
        Defaults to ``True``.
    log : str, optional
        Path of program log. Program log is only written if specified.
        Defaults to ``''`` (i.e., not written).
    executable : str, optional
        Executable to use for system command.
        Defaults to executable specified in :ref:`default settings<default settings>`.
    option : str, optional
        Options for system command. Defaults to options specified in :ref:`default settings<default settings>`.
    args : str, optional
        Not applicable.

    Returns
    -------
    None

    Example
    -------
    .. code-block:: python

        run_tex(paths, program='script.tex')
    """

    try:
        makelog = get_path(paths, 'makelog')
        direct = ProgramDirective(application='tex',
                                  program=program,
                                  makelog=makelog,
                                  program_cwd=program_cwd,
                                  **kwargs)

        # Execute

        if not clean:
            option = direct.option + ' -output-directory="' + \
                get_path(paths, 'output_local_dir') + '"'
            command = metadata.commands[direct.osname][direct.application] % (
                direct.executable, option, direct.script)
            exit_code, stderr = direct.execute_command(command)
            direct.write_log()
            if exit_code != 0:
                error_message = messages.program_error_message % 'TeX'
                error_message = format_message(error_message)
                raise_from(ProgramError(error_message, stderr), None)
        else:
            option = direct.option + ' -c -output-directory="' + \
                get_path(paths, 'output_local_dir') + '"'
            command = metadata.commands[direct.osname][direct.application] % (
                direct.executable, option, direct.script)
            exit_code, stderr = direct.execute_command(command)
            direct.write_log()
            if exit_code != 0:
                error_message = messages.program_error_message % 'TeX'
                error_message = format_message(error_message)
                raise_from(ProgramError(error_message, stderr), None)

    except ProgramError:
        raise
    except:
        error_message = messages.error_message % 'run_tex'
        error_message = format_message(error_message)
        write_to_makelog(paths, error_message + '\n\n' + traceback.format_exc())
        raise_from(ColoredError(error_message, traceback.format_exc()), None)


def run_jupyter(paths, program, program_cwd=True, timeout=None, kernel_name=''):
    """.. Run Jupyter notebook using Python.

    Runs notebook ``program`` using Python API, with notebook specified
    in the form of ``notebook.ipynb``.
    Status messages are appended to file ``makelog``.

    Parameters
    ----------
    paths : dict
        Dictionary of paths. Dictionary should contain values for all keys listed below.
    program : str
        Path of script to run.
    program_cwd : `bool`
        If True will change the working directory to that of the program before
        running the program, and otherwise use the current working directory
        where the function is called.
        Defaults to ``True``.

    Path Keys
    ---------
    makelog : str
        Path of makelog.

    Note
    ----
    We recommend leaving all other parameters to their defaults.

    Other Parameters
    ----------------
    timeout : int, optional
        Time to wait (in seconds) to finish executing a cell before raising exception.
        Defaults to no timeout.
    kernel_name : str, optional
        Name of kernel to use for execution
        (e.g., ``python2`` for standard Python 2 kernel, ``python3`` for standard Python 3 kernel).
        Defaults to ``''`` (i.e., kernel specified in notebook).

    Returns
    -------
    None

    Example
    -------
    .. code-block:: python

        run_jupyter(paths, program='notebook.ipynb')
    """

    program = norm_path(program)
    current_dir = os.getcwd()
    if program_cwd:
        script = os.path.basename(program)
    else:
        script = program

    try:
        if program_cwd:
            os.chdir(os.path.dirname(program))
        with open(script) as f:
            message = 'Working directory  : `%s`' % os.getcwd()
            message += '\n' + 'Processing notebook: `%s`' % script
            print(colored(message, metadata.color_message))

            if not kernel_name:
                kernel_name = 'python%s' % sys.version_info[0]
            ep = ExecutePreprocessor(timeout=timeout, kernel_name=kernel_name)

            nb = nbformat.read(f, as_version=4)
            ep.preprocess(nb, {'metadata': {'path': '.'}})

            if program_cwd:
                os.chdir(current_dir)
            write_to_makelog(paths, message)
            if program_cwd:
                os.chdir(os.path.dirname(program))
        with open(script, 'wt') as f:
            nbformat.write(nb, f)
            if program_cwd:
                os.chdir(current_dir)
    except:
        if program_cwd:
            os.chdir(current_dir)
        error_message = messages.error_message % 'run_jupyter'
        error_message = format_message(error_message)
        write_to_makelog(paths, error_message +
                         '\n\n' + traceback.format_exc())
        raise_from(ColoredError(error_message, traceback.format_exc()), None)


def run_lyx(paths, program, doctype='', **kwargs):
    """.. Run LyX script using system command.

    Compiles document ``program`` using system command, with document specified
    in the form of ``script.lyx``. Status messages are appended to file ``makelog``.
    PDF outputs are written in directory ``output_local_dir``.

    Parameters
    ----------
    paths : dict
        Dictionary of paths. Dictionary should contain values for all keys listed below.
    program : str
        Path of script to run.
    doctype : str, optional
        Type of LyX document. Takes either ``'handout'`` and ``'comments'``.
        All other strings will default to standard document type.
        Defaults to ``''`` (i.e., standard document type).

    Path Keys
    ---------
    makelog : str
        Path of makelog.
    output_local_dir : str
        Directory to write PDFs.

    Note
    ----
    We recommend leaving all other parameters to their defaults.

    Other Parameters
    ----------------
    osname : str, optional
        Name of OS. Used to determine syntax of system command. Defaults to ``os.name``.
    shell : `bool`, optional
        See `here <https://docs.python.org/3/library/subprocess.html#frequently-used-arguments>`_.
        Defaults to ``True``.
    log : str, optional
        Path of program log. Program log is only written if specified.
        Defaults to ``''`` (i.e., not written).
    executable : str, optional
        Executable to use for system command.
        Defaults to executable specified in :ref:`default settings<default settings>`.
    option : str, optional
        Options for system command. Defaults to options specified in :ref:`default settings<default settings>`.
    args : str, optional
        Not applicable.

    Returns
    -------
    None

    Example
    -------
    .. code-block:: python

        run_lyx(paths, program='script.lyx')
    """

    try:
        makelog = get_path(paths, 'makelog')
        pdf_dir = get_path(paths, 'output_local_dir')
        direct = LyXDirective(pdf_dir=pdf_dir,
                              doctype=doctype,
                              application='lyx',
                              program=program,
                              makelog=makelog,
                              **kwargs)

        # Make handout/comments LyX file
        if direct.doctype:
            temp_name = os.path.join(
                direct.program_name + '_' + direct.doctype)
            temp_program = os.path.join(direct.program_dir, temp_name + '.lyx')

            beamer = False
            shutil.copy2(direct.program, temp_program)

            for line in fileinput.input(temp_program, inplace=True, backup='.bak'):
                if r'\textclass beamer' in line:
                    beamer = True
                if direct.doctype == 'handout' and beamer and (r'\options' in line):
                    line = line.rstrip('\n') + ', handout\n'
                elif direct.doctype == 'comments' and (r'\begin_inset Note Note' in line):
                    line = line.replace('Note Note', 'Note Greyedout')

                print(line)
        else:
            temp_name = direct.program_name
            temp_program = direct.script

        # Execute
        command = metadata.commands[direct.osname][direct.application] % (
            direct.executable, direct.option, temp_program)
        exit_code, stderr = direct.execute_command(command)
        direct.write_log()
        if exit_code != 0:
            error_message = messages.program_error_message % 'LyX'
            error_message = format_message(error_message)
            raise_from(ProgramError(error_message, stderr), None)

        # Move PDF output
        temp_pdf = os.path.join(direct.program_dir, temp_name + '.pdf')
        output_pdf = os.path.join(
            direct.pdf_dir, direct.program_name + '.pdf')

        if temp_pdf != output_pdf:
            shutil.copy2(temp_pdf, output_pdf)
            os.remove(temp_pdf)

        # Remove handout/comments LyX file
        if direct.doctype:
            os.remove(temp_program)
    except ProgramError:
        raise
    except:
        error_message = messages.error_message % 'run_lyx'
        error_message = format_message(error_message)
        write_to_makelog(paths, error_message +
                         '\n\n' + traceback.format_exc())
        raise_from(ColoredError(error_message, traceback.format_exc()), None)


def run_mathematica(paths, program, program_cwd=True, **kwargs):
    """.. Run Mathematica script using system command.

    Runs script ``program`` using system command, with script specified
    in the form of ``script.m``. Status messages are appended to file ``makelog``.

    Parameters
    ----------
    paths : dict
        Dictionary of paths. Dictionary should contain values for all keys listed below.
    program : str
        Path of script to run.
    program_cwd : `bool`
        If True will change the working directory to that of the program before
        running the program, and otherwise use the current working directory
        where the function is called.
        Defaults to ``True``.

    Path Keys
    ---------
    makelog : str
        Path of makelog.

    Note
    ----
    We recommend leaving all other parameters to their defaults.

    Other Parameters
    ----------------
    osname : str, optional
        Name of OS. Used to determine syntax of system command. Defaults to ``os.name``.
    shell : `bool`, optional
        See `here <https://docs.python.org/3/library/subprocess.html#frequently-used-arguments>`_.
        Defaults to ``True``.
    log : str, optional
        Path of program log. Program log is only written if specified.
        Defaults to ``''`` (i.e., not written).
    executable : str, optional
        Executable to use for system command.
        Defaults to executable specified in :ref:`default settings<default settings>`.
    option : str, optional
        Options for system command. Defaults to options specified in :ref:`default settings<default settings>`.
    args : str, optional
        Not applicable.

    Returns
    -------
    None

    Example
    -------
    .. code-block:: python

        run_mathematica(paths, program='script.m')
    """

    try:
        makelog = get_path(paths, 'makelog')
        direct = ProgramDirective(application='math',
                                  program=program,
                                  makelog=makelog,
                                  program_cwd=program_cwd,
                                  **kwargs)

        # Execute
        command = metadata.commands[direct.osname][direct.application] % (
            direct.executable, direct.script, direct.option)
        exit_code, stderr = direct.execute_command(command)
        direct.write_log()
        if exit_code != 0:
            error_message = messages.program_error_message % 'Mathematica'
            error_message = format_message(error_message)
            raise_from(ProgramError(error_message, stderr), None)
    except ProgramError:
        raise
    except:
        error_message = messages.error_message % 'run_mathematica'
        error_message = format_message(error_message)
        write_to_makelog(paths, error_message +
                         '\n\n' + traceback.format_exc())
        raise_from(ColoredError(error_message, traceback.format_exc()), None)


def run_matlab(paths, program, program_cwd=True, **kwargs):
    """.. Run Matlab script using system command.

    Runs script ``program`` using system command, with script specified
    in the form of ``script.m``. Status messages are appended to file ``makelog``.

    Parameters
    ----------
    paths : dict
        Dictionary of paths. Dictionary should contain values for all keys listed below.
    program : str
        Path of script to run.
    program_cwd : `bool`
        If True will change the working directory to that of the program before
        running the program, and otherwise use the current working directory
        where the function is called.
        Defaults to ``True``.

    Path Keys
    ---------
    makelog : str
        Path of makelog.

    Note
    ----
    We recommend leaving all other parameters to their defaults.

    Other Parameters
    ----------------
    osname : str, optional
        Name of OS. Used to determine syntax of system command. Defaults to ``os.name``.
    shell : `bool`, optional
        See `here <https://docs.python.org/3/library/subprocess.html#frequently-used-arguments>`_.
        Defaults to ``True``.
    log : str, optional
        Path of program log. Program log is only written if specified.
        Defaults to ``''`` (i.e., not written).
    executable : str, optional
        Executable to use for system command.
        Defaults to executable specified in :ref:`default settings<default settings>`.
    option : str, optional
        Options for system command. Defaults to options specified in :ref:`default settings<default settings>`.
    args : str, optional

    Returns
    -------
    None

    Example
    -------
    .. code-block:: python

        run_matlab(paths, program='script.m')
        run_matlab(paths, program='script.m', args='arg1 arg2')
    """

    try:
        makelog = get_path(paths, 'makelog')
        direct = ProgramDirective(application='matlab',
                                  program=program,
                                  makelog=makelog,
                                  program_cwd=program_cwd,
                                  **kwargs)

        # Get program output
        if direct.program_cwd:
            current_path = direct.program_dir
        else:
            current_path = os.getcwd()

        if direct.log:
            program_log = direct.log
        else:
            program_log = os.path.join(
                current_path, direct.program_name + '.log')

        # Get program arguments
        direct.args = re.split(r'[;,\s]\s*', direct.args)
        direct.args = ",".join(direct.args)

        # Execute
        if direct.args:
            command = metadata.commands[direct.osname][direct.application] % (
                direct.executable, direct.option, direct.program_dir,
                direct.program_name + '(' + direct.args + ')', program_log)
        else:
            command = metadata.commands[direct.osname][direct.application] % (
                direct.executable, direct.option, direct.program_dir,
                direct.program_name, program_log)
        exit_code, stderr = direct.execute_command(command)
        direct.move_program_output(program_log, direct.log)
        if exit_code != 0:
            error_message = messages.program_error_message % 'Matlab'
            error_message = format_message(error_message)
            raise_from(ProgramError(error_message, stderr), None)
    except ProgramError:
        raise
    except:
        error_message = messages.error_message % 'run_matlab'
        error_message = format_message(error_message)
        write_to_makelog(paths, error_message +
                         '\n\n' + traceback.format_exc())
        raise_from(ColoredError(error_message, traceback.format_exc()), None)


def run_perl(paths, program, program_cwd=True, **kwargs):
    """.. Run Perl script using system command.

    Runs script ``program`` using system command, with script specified
    in the form of ``script.pl``. Status messages are appended to file ``makelog``.

    Parameters
    ----------
    paths : dict
        Dictionary of paths. Dictionary should contain values for all keys listed below.
    program : str
        Path of script to run.
    program_cwd : `bool`
        If True will change the working directory to that of the program before
        running the program, and otherwise use the current working directory
        where the function is called.
        Defaults to ``True``.

    Path Keys
    ---------
    makelog : str
        Path of makelog.

    Note
    ----
    We recommend leaving all other parameters to their defaults.

    Other Parameters
    ----------------
    osname : str, optional
        Name of OS. Used to determine syntax of system command. Defaults to ``os.name``.
    shell : `bool`, optional
        See `here <https://docs.python.org/3/library/subprocess.html#frequently-used-arguments>`_.
        Defaults to ``True``.
    log : str, optional
        Path of program log. Program log is only written if specified.
        Defaults to ``''`` (i.e., not written).
    executable : str, optional
        Executable to use for system command.
        Defaults to executable specified in :ref:`default settings<default settings>`.
    option : str, optional
        Options for system command. Defaults to options specified in :ref:`default settings<default settings>`.
    args : str, optional
        Arguments for system command. Defaults to no arguments.

    Returns
    -------
    None

    Example
    -------
    .. code-block:: python

        run_perl(paths, program='script.pl')
    """

    try:
        makelog = get_path(paths, 'makelog')
        direct = ProgramDirective(application='perl',
                                  program=program,
                                  makelog=makelog,
                                  program_cwd=program_cwd,
                                  **kwargs)

        # Execute
        command = metadata.commands[direct.osname][direct.application] % (
            direct.executable, direct.option, direct.script, direct.args)
        exit_code, stderr = direct.execute_command(command)
        direct.write_log()
        if exit_code != 0:
            error_message = messages.program_error_message % 'Perl'
            error_message = format_message(error_message)
            raise_from(ProgramError(error_message, stderr), None)
    except ProgramError:
        raise
    except:
        error_message = messages.error_message % 'run_perl'
        error_message = format_message(error_message)
        write_to_makelog(paths, error_message +
                         '\n\n' + traceback.format_exc())
        raise_from(ColoredError(error_message, traceback.format_exc()), None)


def run_python(paths, program, program_cwd=True, **kwargs):
    """.. Run Python script using system command.

    Runs script ``program`` using system command, with script specified
    in the form of ``script.py``. Status messages are appended to file ``makelog``.

    Parameters
    ----------
    paths : dict
        Dictionary of paths. Dictionary should contain values for all keys listed below.
    program : str
        Path of script to run.
    program_cwd : `bool`
        If True will change the working directory to that of the program before
        running the program, and otherwise use the current working directory
        where the function is called.
        Defaults to ``True``.

    Path Keys
    ---------
    makelog : str
        Path of makelog.

    Note
    ----
    We recommend leaving all other parameters to their defaults.

    Other Parameters
    ----------------
    osname : str, optional
        Name of OS. Used to determine syntax of system command. Defaults to ``os.name``.
    shell : `bool`, optional
        See `here <https://docs.python.org/3/library/subprocess.html#frequently-used-arguments>`_.
        Defaults to ``True``.
    log : str, optional
        Path of program log. Program log is only written if specified.
        Defaults to ``''`` (i.e., not written).
    executable : str, optional
        Executable to use for system command.
        Defaults to executable specified in :ref:`default settings<default settings>`.
    option : str, optional
        Options for system command. Defaults to options specified in :ref:`default settings<default settings>`.
    args : str, optional
        Arguments for system command. Defaults to no arguments.

    Returns
    -------
    None

    Example
    -------
    .. code-block:: python

        run_python(paths, program='script.py')
    """


    try:
        makelog = get_path(paths, 'makelog')
        direct = ProgramDirective(application='python',
                                  program=program,
                                  makelog=makelog,
                                  program_cwd=program_cwd,
                                  **kwargs)

        # Execute
        command = metadata.commands[direct.osname][direct.application] % (
            direct.executable, direct.option, direct.script, direct.args)
        exit_code, stderr = direct.execute_command(command)
        direct.write_log()
        if exit_code != 0:
            error_message = messages.program_error_message % 'Python'
            error_message = format_message(error_message)
            raise_from(ProgramError(error_message, stderr), None)
    except ProgramError:
        raise
    except:
        error_message = messages.error_message % 'run_python'
        error_message = format_message(error_message)
        write_to_makelog(paths, error_message +
                         '\n\n' + traceback.format_exc())
        raise_from(ColoredError(error_message, traceback.format_exc()), None)


def run_r(paths, program, program_cwd=True, **kwargs):
    """.. Run R script using system command.

    Runs script ``program`` using system command, with script specified
    in the form of ``script.R``. Status messages are appended to file ``makelog``.

    Parameters
    ----------
    paths : dict
        Dictionary of paths. Dictionary should contain values for all keys listed below.
    program : str
        Path of script to run.
    program_cwd : `bool`
        If True will change the working directory to that of the program before
        running the program, and otherwise use the current working directory
        where the function is called.
        Defaults to ``True``.

    Path Keys
    ---------
    makelog : str
        Path of makelog.

    Note
    ----
    We recommend leaving all other parameters to their defaults.

    Other Parameters
    ----------------
    osname : str, optional
        Name of OS. Used to determine syntax of system command. Defaults to ``os.name``.
    shell : `bool`, optional
        See `here <https://docs.python.org/3/library/subprocess.html#frequently-used-arguments>`_.
        Defaults to ``True``.
    log : str, optional
        Path of program log. Program log is only written if specified.
        Defaults to ``''`` (i.e., not written).
    executable : str, optional
        Executable to use for system command.
        Defaults to executable specified in :ref:`default settings<default settings>`.
    option : str, optional
        Options for system command. Defaults to options specified in :ref:`default settings<default settings>`.
    args : str, optional
        Arguments for Rscript command. Defaults to no arguments.

    Returns
    -------
    None

    Example
    -------
    .. code-block:: python

        run_r(paths, program='script.R')
    """

    try:
        makelog = get_path(paths, 'makelog')
        direct = ProgramDirective(application='r',
                                  program=program,
                                  makelog=makelog,
                                  program_cwd=program_cwd,
                                  **kwargs)

        # Execute
        command = metadata.commands[direct.osname][direct.application] % (
            direct.executable, direct.option, direct.script, direct.args)
        exit_code, stderr = direct.execute_command(command)
        direct.write_log()
        if exit_code != 0:
            error_message = messages.program_error_message % 'R'
            error_message = format_message(error_message)
            raise_from(ProgramError(error_message, stderr), None)
    except ProgramError:
        raise
    except:
        error_message = messages.error_message % 'run_r'
        error_message = format_message(error_message)
        write_to_makelog(paths, error_message +
                         '\n\n' + traceback.format_exc())
        raise_from(ColoredError(error_message, traceback.format_exc()), None)


def run_sas(paths, program, program_cwd=True, lst='', **kwargs):
    """.. Run SAS script using system command.

    Runs script ``program`` using system command, with script specified
    in the form of ``script.sas``. Status messages are appended to file ``makelog``.

    Parameters
    ----------
    paths : dict
        Dictionary of paths. Dictionary should contain values for all keys listed below.
    program : str
        Path of script to run.
    lst : str, optional
        Path of program lst. Program lst is only written if specified.
        Defaults to ``''`` (i.e., not written).
    program_cwd : `bool`
        If True will change the working directory to that of the program before
        running the program, and otherwise use the current working directory
        where the function is called.
        Defaults to ``True``.

    Path Keys
    ---------
    makelog : str
        Path of makelog.

    Note
    ----
    We recommend leaving all other parameters to their defaults.

    Other Parameters
    ----------------
    osname : str, optional
        Name of OS. Used to determine syntax of system command. Defaults to ``os.name``.
    shell : `bool`, optional
        See `here <https://docs.python.org/3/library/subprocess.html#frequently-used-arguments>`_.
        Defaults to ``True``.
    log : str, optional
        Path of program log. Program log is only written if specified.
        Defaults to ``''`` (i.e., not written).
    executable : str, optional
        Executable to use for system command.
        Defaults to executable specified in :ref:`default settings<default settings>`.
    option : str, optional
        Options for system command. Defaults to options specified in :ref:`default settings<default settings>`.
    args : str, optional
        Not applicable.

    Returns
    -------
    None

    Example
    -------
    .. code-block:: python

        run_sas(paths, program='script.sas')
    """

    try:
        makelog = get_path(paths, 'makelog')
        direct = SASDirective(application='sas',
                              program=program,
                              makelog=makelog,
                              program_cwd=program_cwd,
                              **kwargs)

        # Get program outputs
        if direct.program_cwd:
            current_path = direct.program_dir
        else:
            current_path = os.getcwd()
        program_log = os.path.join(
            current_path, direct.program_name + '.log')
        program_lst = os.path.join(current_path, direct.program_name + '.lst')

        # Execute
        command = metadata.commands[direct.osname][direct.application] % (
            direct.executable, direct.option, direct.script)
        exit_code, stderr = direct.execute_command(command)
        if exit_code != 0:
            error_message = messages.program_error_message % 'SAS'
            error_message = format_message(error_message)
            raise_from(ProgramError(error_message, stderr), None)
        direct.move_program_output(program_log)
        direct.move_program_output(program_lst)
    except ProgramError:
        raise
    except:
        error_message = messages.error_message % 'run_sas'
        error_message = format_message(error_message)
        write_to_makelog(paths, error_message +
                         '\n\n' + traceback.format_exc())
        raise_from(ColoredError(error_message, traceback.format_exc()), None)


def run_stat_transfer(paths, program, program_cwd=True, **kwargs):
    """.. Run StatTransfer script using system command.

    Runs script ``program`` using system command, with script specified
    in the form of ``script.stc`` or ``script.stcmd``.
    Status messages are appended to file ``makelog``.

    Parameters
    ----------
    paths : dict
        Dictionary of paths. Dictionary should contain values for all keys listed below.
    program : str
        Path of script to run.
    program_cwd : `bool`
        If True will change the working directory to that of the program before
        running the program, and otherwise use the current working directory
        where the function is called.
        Defaults to ``True``.

    Path Keys
    ---------
    makelog : str
        Path of makelog.

    Note
    ----
    We recommend leaving all other parameters to their defaults.

    Other Parameters
    ----------------
    osname : str, optional
        Name of OS. Used to determine syntax of system command. Defaults to ``os.name``.
    shell : `bool`, optional
        See `here <https://docs.python.org/3/library/subprocess.html#frequently-used-arguments>`_.
        Defaults to ``True``.
    log : str, optional
        Path of program log. Program log is only written if specified.
        Defaults to ``''`` (i.e., not written).
    executable : str, optional
        Executable to use for system command.
        Defaults to executable specified in :ref:`default settings<default settings>`.
    option : str, optional
        Options for system command. Defaults to options specified in :ref:`default settings<default settings>`.
    args : str, optional
        Not applicable.

    Returns
    -------
    None

    Example
    -------
    .. code-block:: python

        run_stat_transfer(paths, program='script.stc')
    """

    try:
        makelog = get_path(paths, 'makelog')
        direct = ProgramDirective(application='st',
                                  program=program,
                                  makelog=makelog,
                                  program_cwd=program_cwd,
                                  **kwargs)

        # Execute
        command = metadata.commands[direct.osname][direct.application] % (
            direct.executable, direct.script)
        exit_code, stderr = direct.execute_command(command)
        direct.write_log()
        if exit_code != 0:
            error_message = messages.program_error_message % 'StatTransfer'
            error_message = format_message(error_message)
            raise_from(ProgramError(error_message, stderr), None)
    except ProgramError:
        raise
    except:
        error_message = messages.error_message % 'run_stat_transfer'
        error_message = format_message(error_message)
        write_to_makelog(paths, error_message +
                         '\n\n' + traceback.format_exc())
        raise_from(ColoredError(error_message, traceback.format_exc()), None)


def run_stata(paths, program, program_cwd=True, **kwargs):
    """.. Run Stata script using system command.

    Runs script ``program`` using system command, with script specified
    in the form of ``script.do``. Status messages are appended to file ``makelog``.

    Parameters
    ----------
    paths : dict
        Dictionary of paths. Dictionary should contain values for all keys listed below.
    program : str
        Path of script to run.
    program_cwd : `bool`
        If True will change the working directory to that of the program before
        running the program, and otherwise use the current working directory
        where the function is called.
        Defaults to ``True``.

    Path Keys
    ---------
    makelog : str
        Path of makelog.

    Note
    ----
    We recommend leaving all other parameters to their defaults.

    Note
    ----
    When a do-file contains a space in its name, different version of Stata save the
    corresponding log file with different names. Some versions of Stata truncate the
    name to everything before the first space of the do-file name.

    Other Parameters
    ----------------
    osname : str, optional
        Name of OS. Used to determine syntax of system command. Defaults to ``os.name``.
    shell : `bool`, optional
        See `here <https://docs.python.org/3/library/subprocess.html#frequently-used-arguments>`_.
        Defaults to ``True``.
    log : str, optional
        Path of program log. Program log is only written if specified.
        Defaults to ``''`` (i.e., not written).
    executable : str, optional
        Executable to use for system command.
        Defaults to executable specified in :ref:`default settings<default settings>`.
    option : str, optional
        Options for system command. Defaults to options specified in :ref:`default settings<default settings>`.
    args : str, optional
        Not applicable.

    Returns
    -------
    None

    Example
    -------
    .. code-block:: python

        run_stata(paths, program='script.do')
    """

    try:
        makelog = get_path(paths, 'makelog')
        direct = ProgramDirective(application='stata',
                                  program=program,
                                  makelog=makelog,
                                  program_cwd=program_cwd,
                                  **kwargs)

        # Get program output (partial)
        program_name = direct.program.split(" ")[0]
        program_name = os.path.split(program_name)[-1]
        program_name = os.path.splitext(program_name)[0]
        if direct.program_cwd:
            current_path = direct.program_dir
        else:
            current_path = os.getcwd()

        program_log_partial = os.path.join(
            current_path, program_name + '.log')

        # Get program output (full)
        program_log_full = os.path.join(
            current_path, direct.program_name + '.log')

        # Sanitize program
        if direct.osname == "posix":
            direct.script = re.escape(direct.script)

        # Execute
        command = metadata.commands[direct.osname]['stata'] % (
            direct.executable, direct.option, direct.script)
        exit_code, stderr = direct.execute_command(command)
        if exit_code != 0:
            error_message = messages.program_error_message % 'Stata'
            error_message = format_message(error_message)
            raise_from(ProgramError(error_message, stderr), None)
        try:
            output = direct.move_program_output(
                program_log_partial, direct.log)
        except:
            output = direct.move_program_output(program_log_full, direct.log)
        _check_stata_output(output)
    except ProgramError:
        raise
    except:
        error_message = messages.error_message % 'run_stata'
        error_message = format_message(error_message)
        write_to_makelog(paths, error_message +
                         '\n\n' + traceback.format_exc())
        raise_from(ColoredError(error_message, traceback.format_exc()), None)


def _check_stata_output(output):
    """.. Check Stata output"""

    regex = "end of do-file[\s]*r\([0-9]*\);"
    if re.search(regex, output):
        error_message = 'Stata program executed with errors.'
        error_message = format_message(error_message)
        raise_from(ProgramError(error_message,
                                'See makelog for more detail.'), None)


def execute_command(paths, command, **kwargs):
    """.. Run system command.

    Runs system command `command` with shell execution boolean ``shell``.
    Outputs are appended to file ``makelog`` and written to system command log file ``log``.
    Status messages are appended to file ``makelog``.

    Parameters
    ----------
    paths : dict
        Dictionary of paths. Dictionary should contain values for all keys listed below.
    command : str
        System command to run.
    shell : `bool`, optional
        See `here <https://docs.python.org/3/library/subprocess.html#frequently-used-arguments>`_.
        Defaults to ``True``.
    log : str, optional
        Path of system command log. System command log is only written if specified.
        Defaults to ``''`` (i.e., not written).

    Path Keys
    ---------
    makelog : str
        Path of makelog.

    Note
    ----
    We recommend leaving all other parameters to their defaults.

    Other Parameters
    ----------------
    osname : str, optional
        Name of OS. Used to check if OS is supported. Defaults to ``os.name``.


    Returns
    -------
    None

    Example
    -------
    The following code executes the ``ls`` command,
    writes outputs to system command log file ``'file'``,
    and appends outputs and/or status messages to ``paths['makelog']``.

    .. code-block:: python

        execute_command(paths, 'ls', log='file')
    """

    try:
        makelog = get_path(paths, 'makelog')
        direct = Directive(makelog=makelog, **kwargs)

        # Execute
        exit_code, stderr = direct.execute_command(command)
        direct.write_log()
        if exit_code != 0:
            error_message = 'Command executed with errors. Traceback can be found below.'
            error_message = format_message(error_message)
            raise_from(ProgramError(error_message, stderr), None)
    except ProgramError:
        raise
    except:
        error_message = messages.error_message % 'execute_command'
        error_message = format_message(error_message)
        write_to_makelog(paths, error_message +
                         '\n\n' + traceback.format_exc())
        raise_from(ColoredError(error_message, traceback.format_exc()), None)


def run_module(root, module, build_script='make.py', osname=None):
    """.. Run module.

    Runs script `build_script` in module directory `module` relative to root of repository `root`.

    Parameters
    ----------
    root : str
        Directory of root.
    module: str
        Name of module.
    build_script : str
        Name of build script. Defaults to ``make.py``.
    osname : str, optional
        Name of OS. Used to determine syntax of system command. Defaults to ``os.name``.

    Returns
    -------
    None

    Example
    -------
    The following code runs the script ``root/module/make.py``.

    .. code-block:: python

        run_module(root='root', module='module')
    """

    # https://github.com/sphinx-doc/sphinx/issues/759
    osname = osname if osname else os.name

    try:
        module_dir = os.path.join(root, module)
        os.chdir(module_dir)

        build_script = norm_path(build_script)
        if not os.path.isfile(build_script):
            raise CritError(messages.crit_error_no_file % build_script)

        message = 'Running module `%s`' % module
        message = format_message(message)
        message = colored(message, attrs=['bold'])
        print('\n' + message)

        status = os.system('%s %s' % (
            metadata.default_executables[osname]['python'], build_script))
        if status != 0:
            raise ProgramError()
    except ProgramError:
        sys.exit()
    except:
        error_message = messages.error_message % 'run_module'
        error_message = format_message(error_message)
        raise_from(ColoredError(error_message, traceback.format_exc()), None)


__all__ = ['run_stata', 'run_matlab', 'run_perl', 'run_python',
           'run_jupyter', 'run_mathematica', 'run_stat_transfer',
           'run_lyx', 'run_latex', 'run_tex', 'run_r', 'run_sas',
           'execute_command', 'run_module']
