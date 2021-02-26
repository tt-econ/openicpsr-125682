# -*- coding: utf-8 -*-
from __future__ import absolute_import, division, print_function, unicode_literals
from future.utils import string_types
from builtins import (bytes, str, open, super, range,
                      zip, round, input, int, pow, object)

import sys
import codecs

from termcolor import colored
import colorama
colorama.init()

import ttmake.private.metadata as metadata


def _decode(string):
    """Decode string."""

    if (sys.version_info < (3, 0)) and isinstance(string, string_types):
        string = codecs.decode(string, 'latin1')

    return(string)


def _encode(string):
    """Clean string for encoding."""

    if (sys.version_info < (3, 0)) and isinstance(string, str):
        string = codecs.encode(string, 'utf-8')

    return(string)


class CritError(Exception):
    pass


class UseError(Exception):
    pass


class ColoredError(Exception):
    """Colorized error messages."""

    def __init__(self, message='', trace=''):
        if message:
            message = _decode(message)
            message = '\n\n' + colored(message, color=metadata.color_failure)
        if trace:
            trace = _decode(trace)
            message += '\n\n' + colored(trace, color=metadata.color_failure)

        super(ColoredError, self).__init__(_encode(message))


class ProgramError(ColoredError):
    """Program execution exception."""

    pass
