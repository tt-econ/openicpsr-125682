# -*- coding: utf-8 -*-
from __future__ import absolute_import, division, print_function, unicode_literals
from future.utils import raise_from
from builtins import (bytes, str, open, super, range,
                      zip, round, input, int, pow, object)

import os
import io
import shutil

import sys
if (sys.version_info < (3, 0)) and (os.name == 'nt'):
    import ttmake.private.subprocess_nt as subprocess
else:
    import subprocess


from termcolor import colored
import colorama
colorama.init()

import ttmake.private.messages as messages
import ttmake.private.metadata as metadata
from ttmake.private.exceptionclasses import CritError
from ttmake.private.utility import norm_path, format_list, format_traceback, decode


class Directive(object):
    """
    Directive.

    Note
    ----
    Contains instructions on how to run shell commands.

    Parameters
    ----------
    makelog : str
        Path of make log.
    log : str, optional
        Path of directive log. Directive log is only written if specified.
        Defaults to ``''`` (i.e., not written).
    osname : str, optional
        Name of OS. Defaults to ``os.name``.
    shell : bool, optional
        See `here <https://docs.python.org/3/library/subprocess.html#frequently-used-arguments>`_.
        Defaults to ``True``.

    Returns
    -------
    None
    """

    def __init__(self,
                 makelog,
                 log='',
                 osname=os.name,
                 shell=True):

        self.makelog = makelog
        self.log = log
        self.osname = osname
        self.shell = shell
        self.check_os()
        self.get_paths()

    def check_os(self):
        """Check OS is either POSIX or NT.

        Returns
        -------
        None
        """

        if self.osname not in ['posix', 'nt']:
            raise_from(CritError(messages.crit_error_unknown_system % self.osname), None)

    def get_paths(self):
        """Normalize paths.

        Returns
        -------
        None
        """

        self.makelog = norm_path(self.makelog)
        self.log = norm_path(self.log)

    def execute_command(self, command):
        """Execute shell command.

        Parameters
        ----------
        command : str
            Shell command to execute.

        Returns
        -------
        exit : tuple
            Tuple (exit code, error message) for shell command.
        """

        current_dir = os.getcwd()
        if hasattr(self, 'program_cwd'):
            if self.program_cwd:
                os.chdir(self.program_dir)

        self.output = 'Working directory: `%s`' % os.getcwd()
        self.output += '\n' + 'Executing command: `%s`' % command
        print(colored(self.output, metadata.color_message))

        try:
            if not self.shell:
                command = command.split()

            process = subprocess.Popen(command,
                                       stdout=subprocess.PIPE,
                                       stderr=subprocess.PIPE,
                                       shell=self.shell,
                                       universal_newlines=True)
            process.wait()
            stdout, stderr = process.communicate()
            exit = (process.returncode, stderr)

            if stdout:
                self.output += '\n' + decode(stdout)
            if stderr:
                self.output += '\n' + decode(stderr)
                pass
            if hasattr(self, 'program_cwd'):
                if self.program_cwd:
                    os.chdir(current_dir)

            return(exit)
        except:
            if hasattr(self, 'program_cwd'):
                if self.program_cwd:
                    os.chdir(current_dir)
            error_message = messages.crit_error_bad_command % command
            error_message = error_message + format_traceback()
            raise_from(CritError(error_message), None)

    def write_log(self):
        """Write logs for shell command.

        Returns
        -------
        None
        """

        if self.makelog:
            if not (metadata.makelog_started and os.path.isfile(self.makelog)):
                raise_from(CritError(messages.crit_error_no_makelog % self.makelog), None)
            with io.open(self.makelog, 'a', encoding='utf-8', errors='ignore') as f:
                print(self.output, file=f)

        if self.log:
            with io.open(self.log, 'w', encoding='utf-8', errors='ignore') as f:
                f.write(self.output)


class ProgramDirective(Directive):
    """
    Program directive.

    Notes
    -----
    Contains instructions on how to run a program through shell command.

    Parameters
    ----------
    See :class:`.Directive`.

    application : str
        Name of application to run program.
    program : str
        Path of program to run.
    program_cwd : `bool`
        If True will change the working directory to that of the program before
        running the program, and otherwise use the current working directory
        where the function is called.
        Defaults to ``True``.
    executable : str, optional
        Executable to use for shell command. Defaults to executable specified in metadata.
    option : str, optional
        Options for shell command. Defaults to options specified in metadata.
    args : str, optional
        Arguments for shell command. Defaults to no arguments.

    Attributes
    ----------
    program_dir : str
        Directory of program parsed from program.
    program_base : str
        ``program_name.program_ext`` of program parsed from program.
    program_name : str
        Name of program parsed from program.
    program_ext : str
        Extension of program parsed from program.
    script : str
        The program/script to be run after taking into account the path and
        current working directory (can be changed by ``program_cwd``).

    Returns
    -------
    None
    """

    def __init__(self,
                 application,
                 program,
                 program_cwd=True,
                 executable='',
                 option='',
                 args='',
                 **kwargs):

        self.application = application
        self.program = program
        self.program_cwd = program_cwd
        self.executable = executable
        self.option = option
        self.args = args
        super(ProgramDirective, self).__init__(**kwargs)
        self.parse_program()
        self.check_program()
        self.get_executable()
        self.get_option()

    def parse_program(self):
        """Parse program for directory, name, and extension.

        Returns
        -------
        None
        """

        self.program = norm_path(self.program)
        self.program_dir = os.path.dirname(self.program)
        self.program_base = os.path.basename(self.program)
        self.program_name, self.program_ext = os.path.splitext(
            self.program_base)


        if self.program_cwd:
            self.script = self.program_base
        else:
            self.script = self.program

    def check_program(self):
        """Check program exists and has correct extension given application.

        Returns
        -------
        None
        """

        if not os.path.isfile(self.program):
            raise_from(CritError(messages.crit_error_no_file %
                                 self.program), None)

        if self.program_ext not in metadata.extensions[self.application]:
            extensions = format_list(metadata.extensions[self.application])
            raise_from(CritError(messages.crit_error_extension %
                       (self.program, extensions)), None)

    def get_executable(self):
        """Set executable to default from metadata if unspecified.

        Returns
        -------
        None
        """

        if not self.executable:
            self.executable = metadata.default_executables[self.osname][self.application]

    def get_option(self):
        """Set options to default from metadata if unspecified.

        Returns
        -------
        None
        """

        if not self.option:
            self.option = metadata.default_options[self.osname][self.application]

    def move_program_output(self, program_output, log_file=''):
        """Move program outputs.

        Notes
        -----
        Certain applications create program outputs that need to be moved to
        appropriate logging files.

        Parameters
        ----------
        program_output : str
             Path of program output.
        log_file : str, optional
             Path of log file. Log file is only written if specified.
             Defaults to ``''`` (i.e., not written).
        """

        program_output = norm_path(program_output)

        try:
            with io.open(program_output, 'r', encoding='utf-8', errors='ignore') as f:
                out = f.read()
        except:
            error_message = messages.crit_error_no_program_output % (
                program_output, self.program)
            error_message = error_message + format_traceback()
            raise_from(CritError(error_message), None)

        if self.makelog:
            if not (metadata.makelog_started and os.path.isfile(self.makelog)):
                raise_from(CritError(messages.crit_error_no_makelog % self.makelog), None)
            with io.open(self.makelog, 'a', encoding='utf-8', errors='ignore') as f:
                print(out, file=f)

        if log_file:
            if program_output != log_file:
                shutil.copy2(program_output, log_file)
                os.remove(program_output)
        else:
            os.remove(program_output)

        return(out)


class SASDirective(ProgramDirective):
    """
    SAS directive.

    Notes
    -----
    Contains instructions on how to run a SAS program through shell command.

    Parameters
    ----------
    See :class:`.ProgramDirective`.

    lst : str, optional
        Path of directive lst. Directive lst is only written if specified.
        Defaults to ``''`` (i.e., not written).
    """

    def __init__(self,
                 lst='',
                 **kwargs):

        self.lst = lst
        super(SASDirective, self).__init__(**kwargs)


class LyXDirective(ProgramDirective):
    """
    LyX directive.

    Notes
    -----
    Contains instructions on how to run a LyX program through shell command.

    Parameters
    ----------
    See :class:`.ProgramDirective`.

    pdf_dir : str
        Directory to write PDFs.
    doctype : str, optional
        Type of LyX document. Takes either ``'handout'`` and ``'comments'``.
        All other strings will default to standard document type.
        Defaults to ``''`` (i.e., standard document type).
    """

    def __init__(self,
                 pdf_dir,
                 doctype='',
                 **kwargs):

        self.pdf_dir = pdf_dir
        self.doctype = doctype
        super(LyXDirective, self).__init__(**kwargs)
        self.check_doctype()

    def check_doctype(self):
        """Check document type is valid.

        Returns
        -------
        None
        """

        if self.doctype not in ['handout', 'comments', '']:
            print(colored(messages.warning_lyx_type % self.doctype, 'red'))
            self.doctype = ''
