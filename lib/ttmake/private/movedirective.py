# -*- coding: utf-8 -*-
from __future__ import absolute_import, division, print_function, unicode_literals
from future.utils import raise_from
from builtins import (bytes, str, open, super, range,
                      zip, round, input, int, pow, object)

import os
import re
import glob
from itertools import chain
import sys
if (sys.version_info < (3, 0)) and (os.name == 'nt'):
    import ttmake.private.subprocess_nt as subprocess
else:
    import subprocess

import ttmake.private.messages as messages
import ttmake.private.metadata as metadata
from ttmake.private.exceptionclasses import CritError
from ttmake.private.utility import convert_to_list, norm_path, file_to_array, format_traceback, decode


class MoveDirective(object):
    """
    Directive for creating symbolic link or copy of data.

    Notes
    -----
    Parse line of text containing linking/copying instructions and represent as directive.
    Takes glob-style wildcards.

    Parameters
    ----------
    file: str
        File containing linking/copying instructions (used for error messaging).
    raw_line : str
        Raw text of line containing linking/copying instructions (used for error messaging).
    line : str
        Line of text containing linking/copying instructions.
    move_dir : str
        Directory to write symlink/copy.
    osname : str, optional
        Name of OS. Defaults to `os.name`.
    reverse : boolean, optional
        Whether the source files are listed as destination instead. Defaults to `False`.

    Attributes
    ----------
    source : list
        List of sources parsed from line.
    destination : list
        List of destinations parsed from line.
    move_list : list
        List of (source, destination) mappings parsed from line.
    """

    def __init__(self, raw_line, file, line, move_dir, osname=os.name, reverse=False):
        self.raw_line = raw_line
        self.file = file
        self.line = line
        self.move_dir = move_dir
        self.osname = osname
        self.reverse = reverse
        self.check_os()
        self.get_paths()
        self.check_paths()
        self.get_move_list()

    def check_os(self):
        """Check OS is either POSIX or NT.

        Returns
        -------
        None
        """

        if self.osname not in ['posix', 'nt']:
            raise_from(CritError(messages.crit_error_unknown_system % self.osname), None)

    def get_paths(self):
        """Parse sources and destinations from line.

        Returns
        -------
        None
        """

        try:
            self.line = self.line.split('|')
            self.line = [l.strip() for l in self.line]
            self.line = [l.strip('"\'') for l in self.line]
            self.destination, self.source = self.line
        except Exception:
            error_message = messages.crit_error_bad_move % (
                self.raw_line, self.file)
            error_message = error_message + format_traceback()
            raise_from(CritError(error_message), None)

        self.source = norm_path(self.source)
        self.destination = norm_path(
            os.path.join(self.move_dir, self.destination))

    def check_paths(self):
        """Check sources and destination exist and have same number of wildcards.

        Returns
        -------
        None
        """

        if re.findall('\*', self.source) != re.findall('\*', self.destination):
            raise_from(SyntaxError(messages.syn_error_wildcard %
                       (self.raw_line, self.file)), None)

        if re.search('\*', self.source):
            if not self.reverse:
                if not glob.glob(self.source):
                    raise_from(CritError(
                        messages.crit_error_no_path_wildcard % self.source), None)
            else:
                if not glob.glob(self.destination):
                    raise_from(CritError(
                        messages.crit_error_no_path_wildcard % self.destination), None)
        else:
            if not self.reverse:
                if not os.path.exists(self.source):
                    raise_from(CritError(messages.crit_error_no_path % self.source), None)
            else:
                if not os.path.exists(self.destination):
                    raise_from(CritError(messages.crit_error_no_path %
                               self.destination), None)

    def get_move_list(self):
        """Interpret wildcards to get list of paths that meet criteria.

        Returns
        -------
        None
        """
        if re.search('\*', self.source):
            if not self.reverse:
                self.source_list = glob.glob(self.source)
                self.destination_list = [
                    self.extract_wildcards(t) for t in self.source_list]
                self.destination_list = [self.fill_in_wildcards(
                    s) for s in self.destination_list]
            else:
                self.destination_list = glob.glob(self.destination)
                self.source_list = [
                    self.extract_wildcards(t) for t in self.destination_list]
                self.source_list = [self.fill_in_wildcards(
                    s) for s in self.source_list]
        else:
            self.source_list = [self.source]
            self.destination_list = [self.destination]

        self.move_list = list(zip(self.source_list, self.destination_list))

    def extract_wildcards(self, f):
        """Extract wildcard characters from source/destination path.

        Notes
        -----
        Suppose path `foo.py` and glob pattern `*.py`.
        The wildcard characters would therefore be `foo`.

        Parameters
        ----------
        f : str
           Source/destination path from which to extract wildcard characters.

        Returns
        -------
        wildcards : iter
           Iterator of extracted wildcard characters.
        """

        if not self.reverse:
            regex = re.escape(self.source)
        else:
            regex = re.escape(self.destination)
        regex = regex.split('\*')
        regex = '(.*)'.join(regex)

        # Returns list if single match, list of set if multiple matches
        wildcards = re.findall(regex, f)
        wildcards = [(w, ) if isinstance(w, str) else w for w in wildcards]
        wildcards = chain(*wildcards)

        return wildcards

    def fill_in_wildcards(self, wildcards):
        """Fill in wildcards for destination path.

        Notes
        -----
        Use extracted wildcard characters from a source/destination path to create
        corresponding destination/source path.

        Parameters
        ----------
        wildcards: iterator
           Extracted wildcard characters (returned from `extract_wildcards`).

        Returns
        -------
        f : str
           Destination/source path
        """

        if not self.reverse:
            f = self.destination
        else:
            f = self.source
        for w in wildcards:
            f = re.sub('\*', w, f, 1)

        return f

    def create_symlinks(self):
        """Create symlinks from destination to source.

        Parameters
        ----------
        None

        Returns
        -------
        None
        """

        if self.osname == 'posix':
            self.move_posix(movetype='symlink')
        elif self.osname == 'nt':
            self.move_nt(movetype='symlink')

        return(self.move_list)

    def create_copies(self):
        """Create copies from source to destination.

        Parameters
        ----------
        None

        Returns
        -------
        None
        """

        if self.osname == 'posix':
            self.move_posix(movetype='copy')
        elif self.osname == 'nt':
            self.move_nt(movetype='copy')

        return(self.move_list)

    def create_link_copies(self):
        """Create copies from source to destination.

        Parameters
        ----------
        None

        Returns
        -------
        None
        """

        if self.osname == 'posix':
            self.move_link_posix()
        elif self.osname == 'nt':
            self.move_link_nt()

        return(self.move_list)

    def move_posix(self, movetype):
        """Create symlinks/copies using POSIX shell command specified in metadata.

        Parameters
        ----------
        movetype : str
            Type of file movement. Takes either `copy` or `symlink`.

        Returns
        -------
        None
        """

        for source, destination in self.move_list:
            if movetype == 'copy':
                command = metadata.commands[self.osname]['makecopy'] % (
                    source, destination)
            elif movetype == 'symlink':
                command = metadata.commands[self.osname]['makelink'] % (
                    source, destination)

            process = subprocess.Popen(command,
                                       shell=True,
                                       stdout=subprocess.PIPE,
                                       stderr=subprocess.PIPE,
                                       universal_newlines=True)
            stdout, stderr = process.communicate()

            if process.returncode != 0:
                error_message = messages.crit_error_move_command % command
                error_message = error_message + format_traceback(stderr)
                raise_from(CritError(error_message), None)

    def move_nt(self, movetype):
        """Create symlinks/copies using NT shell command specified in metadata.

        Parameters
        ----------
        movetype : str
            Type of file movement. Takes either `copy` or `symlink`.

        Returns
        -------
        None
        """
        for source, destination in self.move_list:
            if os.path.isdir(source):
                link_option = '/d'
                copy_option = ''
            elif os.path.isfile(source):
                link_option = ''
                copy_option = 'cmd /c echo F | '

            if movetype == 'copy':
                command = metadata.commands[self.osname]['makecopy'] % (
                    copy_option, source, destination)
            elif movetype == 'symlink':
                command = metadata.commands[self.osname]['makelink'] % (
                    link_option, destination, source)

            process = subprocess.Popen(command,
                                       shell=True,
                                       stdout=subprocess.PIPE,
                                       stderr=subprocess.PIPE,
                                       universal_newlines=True)
            stdout, stderr = process.communicate()

            if process.returncode != 0:
                error_message = messages.crit_error_move_command % command
                error_message = error_message + format_traceback(stderr)
                raise_from(CritError(error_message), None)

    def move_link_posix(self):
        """Create copies from destination to source then symlink them back
        using POSIX shell command specified in metadata.

        Parameters
        ----------
        None

        Returns
        -------
        None
        """

        for source, destination in self.move_list:
            command_move = metadata.commands[self.osname]['move'] % (
                    destination, source)
            command_link = metadata.commands[self.osname]['makelink'] % (
                    source, destination)

            process = subprocess.Popen(command_move,
                                       shell=True,
                                       stdout=subprocess.PIPE,
                                       stderr=subprocess.PIPE,
                                       universal_newlines=True)
            stdout, stderr = process.communicate()

            if process.returncode != 0:
                error_message = messages.crit_error_move_command % command_move
                error_message = error_message + format_traceback(stderr)
                raise_from(CritError(error_message), None)

            process = subprocess.Popen(command_link,
                                       shell=True,
                                       stdout=subprocess.PIPE,
                                       stderr=subprocess.PIPE,
                                       universal_newlines=True)
            stdout, stderr = process.communicate()

            if process.returncode != 0:
                error_message = messages.crit_error_move_command % command_link
                error_message = error_message + format_traceback(stderr)
                raise_from(CritError(error_message), None)

    def move_link_nt(self):
        """Create copies from destination to source then symlink them back
        using NT shell command specified in metadata.

        Parameters
        ----------
        None

        Returns
        -------
        None
        """
        for source, destination in self.move_list:
            if os.path.isdir(destination):
                link_option = '/d'
            elif os.path.isfile(destination):
                link_option = ''

            command_move = metadata.commands[self.osname]['move'] % (
                    destination, source)
            command_link = metadata.commands[self.osname]['makelink'] % (
                    link_option, destination, source)

            process = subprocess.Popen(command_move,
                                       shell=True,
                                       stdout=subprocess.PIPE,
                                       stderr=subprocess.PIPE,
                                       universal_newlines=True)
            stdout, stderr = process.communicate()

            if process.returncode != 0:
                error_message = messages.crit_error_move_command % command_move
                error_message = error_message + format_traceback(stderr)
                raise_from(CritError(error_message), None)

            process = subprocess.Popen(command_link,
                                       shell=True,
                                       stdout=subprocess.PIPE,
                                       stderr=subprocess.PIPE,
                                       universal_newlines=True)
            stdout, stderr = process.communicate()

            if process.returncode != 0:
                error_message = messages.crit_error_move_command % command_link
                error_message = error_message + format_traceback(stderr)
                raise_from(CritError(error_message), None)


class MoveList(object):
    """
    List of move directives.

    Notes
    -----
    Parse files containing linking/copying instructions and represent as move directives.

    Parameters
    ----------
    file_list : list
        List of files from which to parse linking/copying instructions.
    move_dir : str
        Directory to write symlink/copy.
    mapping_dict : dict, optional
        Dictionary of path mappings used to parse linking/copying instructions.
        Defaults to no mappings.
    reverse: binary
        Whether the source file is listed as destination instead. Defaults to `False`.

    Attributes
    ----------
    move_directive_list : list
        List of move directives.
    """

    def __init__(self,
                 file_list,
                 move_dir,
                 mapping_dict={},
                 reverse=False):

        self.file_list = file_list
        self.move_dir = move_dir
        self.mapping_dict = mapping_dict
        self.reverse = reverse
        self.parse_file_list()
        self.get_paths()
        self.get_move_directive_list()

    def parse_file_list(self):
        """Parse wildcards in list of files.

        Returns
        -------
        None
        """

        if self.file_list:
            self.file_list = convert_to_list(self.file_list, 'file')
            self.file_list = [norm_path(file) for file in self.file_list]

            file_list_parsed = [
                f for file in self.file_list for f in glob.glob(file)]
            if file_list_parsed:
                self.file_list = file_list_parsed
            else:
                error_list = [decode(f) for f in self.file_list]
                raise_from(CritError(messages.crit_error_no_files % error_list), None)

    def get_paths(self):
        """Normalize paths.

        Returns
        -------
        None
        """

        self.move_dir = norm_path(self.move_dir)
        self.file_list = [norm_path(f) for f in self.file_list]

    def get_move_directive_list(self):
        """Parse list of files to create symlink directives.

        Returns
        -------
        None
        """
        lines = []
        for file in self.file_list:
            for raw_line in file_to_array(file):
                try:
                    line = raw_line.format(**self.mapping_dict)
                    lines.append((file, raw_line, line))
                except KeyError as e:
                    key = decode(e).lstrip("u'").rstrip("'")
                    error_message = messages.crit_error_path_mapping % (
                        key, key, file, raw_line, key)
                    error_message = error_message + format_traceback()
                    raise_from(CritError(error_message), None)

        self.move_directive_list = [MoveDirective(
            file, raw_line, line, self.move_dir, reverse=self.reverse) for (file, raw_line, line) in lines]

    def create_symlinks(self):
        """Create symlinks according to directives.

        Returns
        -------
        move_map : list
            List of (source, destination) for each symlink created.
        """

        move_map = []
        for move in self.move_directive_list:
            move_map.extend(move.create_symlinks())

        return move_map

    def create_copies(self):
        """Create copies according to directives.

        Returns
        -------
        move_map : list
            List of (source, destination) for each copy created.
        """

        move_map = []
        for move in self.move_directive_list:
            move_map.extend(move.create_copies())

        return move_map

    def create_link_copies(self):
        """Create reverse copies from destination to source
        then link the copies back to destination according to directives.

        Returns
        -------
        move_map : list
            List of (source, destination) for each copy created.
        """

        move_map = []
        for move in self.move_directive_list:
            move_map.extend(move.create_link_copies())

        return move_map
