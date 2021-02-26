# -*- coding: utf-8 -*-
from __future__ import absolute_import, division, print_function, unicode_literals
from builtins import *
from future.utils import raise_from
from ttmake.private.exceptionclasses import CritError, ColoredError
from ttmake.private.utility import norm_path, format_message, convert_to_list
import ttmake.private.metadata as metadata
import ttmake.private.messages as messages

import io
import re
import traceback
from itertools import chain

from termcolor import colored
import colorama
colorama.init()


def _parse_tag(tag):
    """.. Parse tag from input."""

    if not re.match('<tab:(.*)>\n', tag, flags=re.IGNORECASE):
        raise Exception
    else:
        tag = re.sub('<tab:(.*?)>\n', r'\g<1>', tag, flags=re.IGNORECASE)
        tag = tag.lower()

    return(tag)


def _parse_data(data, null):
    """.. Parse data from input.

    Parameters
    ----------
    data : list
        Input data to parse.
    null : dict
        Dictionary of null characters and their replacements.
        If replaced with ``None`` then remove value from data.

    Returns
    -------
    data : list
        List of data values from input.
    """
    data = [row.rstrip('\r\n') for row in data]
    data = [row for row in data if row]
    data = [row.split('\t') for row in data]
    data = chain(*data)
    data = list(data)
    data = [null[value] if value in null.keys() else value for value in data]
    data = [value for value in data if value]

    return(data)


def _parse_content(file, null):
    """.. Parse content from input."""

    with io.open(file, 'r', encoding='utf-8') as f:
        content = f.readlines()
    try:
        tag = _parse_tag(content[0])
    except:
        print(colored(messages.warning_no_tag % file, metadata.color_warning))
    data = _parse_data(content[1:], null)

    return(tag, data)


def _insert_value(line, value, type, null):
    """.. Insert value into line.

    Parameters
    ----------
    line : str
        Line of document to insert value.
    value : str
        Value to insert.
    type : str
        Formatting for value.
    null : dict
        Dictionary of null characters and their replacements.
        If replaced with ``None`` then remove value from data.

    Returns
    -------
    line : str
        Line of document with inserted value.
    """

    if (type == 'no change'):
        line = re.sub('\\\\?#\\\\?#\\\\?#', value, line)

    elif (type == 'round'):
        if value in null.values():
            line = re.sub('(.*?)\\\\?#[0-9]+\\\\?#', r'\g<1>' + value, line)
        else:
            try:
                value = float(value)
            except:
                raise_from(
                    CritError(messages.crit_error_not_float % value), None)
            digits = re.findall('\\\\?#([0-9]+)\\\\?#', line)[0]
            rounded_value = format(value, '.%sf' % digits)
            line = re.sub('(.*?)\\\\?#[0-9]+\\\\?#',
                          r'\g<1>' + rounded_value, line)

    elif (type == 'comma + round'):
        if value in null.values():
            line = re.sub('(.*?)\\\\?#[0-9]+,\\\\?#', r'\g<1>' + value, line)
        else:
            try:
                value = float(value)
            except:
                raise_from(
                    CritError(messages.crit_error_not_float % value), None)
            digits = re.findall('\\\\?#([0-9]+),\\\\?#', line)[0]
            rounded_value = format(value, ',.%sf' % digits)
            line = re.sub('(.*?)\\\\?#[0-9]+,\\\\?#',
                          r'\g<1>' + rounded_value, line)

    return(line)


def _insert_tables_lyx(template, tables, null):
    """.. Fill tables for LyX template.

    Parameters
    ----------
    template : str
        Path of LyX template to fill.
    tables : dict
        Dictionary ``{tag: values}`` of tables.
    null : dict
        Dictionary of null characters and their replacements.
        If replaced with ``None`` then remove value from data.

    Returns
    -------
    template : str
        Filled LyX template.
    """

    with io.open(template, 'r', encoding='utf-8') as f:
        doc = f.readlines()

    is_table = False

    for i in range(len(doc)):
        # Check if table
        if not is_table and re.match('name "tab:', doc[i]):
            tag = doc[i].replace('name "tab:', '').rstrip('"\n').lower()
            try:
                values = tables[tag]
                entry_count = 0
                is_table = True
            except KeyError:
                print(colored(messages.warning_no_input_table %
                              tag, metadata.color_warning))

        # Fill in values if table
        if is_table:
            try:
                if re.match('.*###', doc[i]):
                    doc[i] = _insert_value(
                        doc[i], values[entry_count], 'no change', null)
                    entry_count += 1
                elif re.match('.*#[0-9]+#', doc[i]):
                    doc[i] = _insert_value(
                        doc[i], values[entry_count], 'round', null)
                    entry_count += 1
                elif re.match('.*#[0-9]+,#', doc[i]):
                    doc[i] = _insert_value(
                        doc[i], values[entry_count], 'comma + round', null)
                    entry_count += 1
                elif re.match('</lyxtabular>', doc[i]):
                    is_table = False
                    if entry_count != len(values):
                        raise_from(
                            CritError(messages.crit_error_too_many_values % tag), None)
            except IndexError:
                raise_from(
                    CritError(messages.crit_error_not_enough_values % tag), None)

    doc = ''.join(doc)

    return(doc)


def _insert_tables_latex(template, tables, null):
    """.. Fill tables for LaTeX template.

    Parameters
    ----------
    template : str
        Path of LaTeX template to fill.
    tables : dict
        Dictionary ``{tag: values}`` of tables.
    null : dict
        Dictionary of null characters and their replacements.
        If replaced with ``None`` then remove value from data.

    Returns
    -------
    template : str
        Filled LaTeX template.
    """

    with io.open(template, 'r', encoding='utf-8') as f:
        doc = f.readlines()

    is_table = False

    for i in range(len(doc)):
        # Check if table
        if (not is_table and (re.search('(?<!ref)\{tab:', doc[i], flags=re.IGNORECASE)
                              or re.search('(?<!ref)\{atab:', doc[i], flags=re.IGNORECASE))):
            tag = doc[i].split('tab:')[1].rstrip('}\n').strip('"').lower()
            try:
                values = tables[tag]
                entry_count = 0
                is_table = True
            except KeyError:
                print(colored(messages.warning_no_input_table %
                              tag, metadata.color_warning))

        # Fill in values if table
        if is_table:
            try:
                line = doc[i].split("&")

                for j in range(len(line)):
                    if re.search('.*\\\\#\\\\#\\\\#', line[j]):
                        line[j] = _insert_value(line[j], values[entry_count], 'no change', null)
                        entry_count += 1
                    elif re.search('.*\\\\#[0-9]+\\\\#', line[j]):
                        line[j] = _insert_value(line[j], values[entry_count], 'round', null)
                        entry_count += 1
                    elif re.search('.*\\\\#[0-9]+,\\\\#', line[j]):
                        line[j] = _insert_value(line[j], values[entry_count], 'comma + round', null)
                        entry_count += 1

                doc[i] = "&".join(line)

                if re.search('end\{tabular\}', doc[i], flags=re.IGNORECASE):
                    is_table = False
                    if entry_count != len(values):
                        raise_from(CritError(messages.crit_error_too_many_values % tag), None)
            except IndexError:
                raise_from(CritError(messages.crit_error_not_enough_values % tag), None)

    doc = ''.join(doc)

    return(doc)


def _insert_tables(template, tables, null):
    """.. Fill tables for template.

    Parameters
    ----------
    template : str
        Path of template to fill.
    tables : dict
        Dictionary ``{tag: values}`` of tables.
    null : dict
        Dictionary of null characters and their replacements.
        If replaced with ``None`` then remove value from data.

    Returns
    -------
    template : str
        Filled template.
    """

    template = norm_path(template)

    if re.search('\.lyx', template):
        doc = _insert_tables_lyx(template, tables, null)
    elif re.search('\.tex', template):
        doc = _insert_tables_latex(template, tables, null)

    return(doc)


def tablefill(inputs, template, output, null={'.': 'NA',
                                              'NA': 'NA',
                                              'NaN': 'NA',
                                              '---': ' ',
                                              '': None}):
    """.. Fill tables for template using inputs.

    Fills tables in document ``template`` using files in list ``inputs``.
    Writes filled document to file ``output``.
    Null characters in ``inputs`` are replaced with value ``null``.

    **Input data format**

    The data needs to be tab-delimited rows of numbers (or characters),
    preceeded by  `<tab>`.  The < and > are mandatory. The numbers can be
    arbitrarily long, can be negative, and can also be in scientific notation.

    *Examples:*

    .. code-block::

        <tab:Test>
        1	2	3
        2	3	1
        3	1	2

    .. code-block::

        <tab:FunnyMat>
        1	2	3	23	2
        2	3
        3	1	2	2
        1

    .. Note::

        Having multiple tables with the same name in the input files will cause errors.

    .. Note::

        The rows do not need to be of equal length.

        Completely blank (no tab) lines are ignored.

    .. Note::

        The scientific notation has to be of the form:
        [numbers].[numbers]e(+/-)[numbers]

        *Example:*

        .. code-block::

            23.2389e+23
            -2.23e-2
            -0.922e+3

    **LyX/TeX template format**

    The LyX/TeX template file determines where the numbers from the input files are placed.

    Every table in the template file (if it is to be filled) must appear within a float.
    There must be one, and only one, table object inside the float, and the table name
    must start with ``tab`` or ``atab`` and must correspond to the label of the data table in
    the input file.

    .. Note::

        Having multiple tables with the same name in the template file will cause errors.

    .. Note::

        Labels are NOT case-sensitive. That is, <TAB:Table1> is considered the same as `<tab:table1>`.

    In LyX tables, "cells" to be filled with entries from the input text files are
    indicated by the following tags:

    .. code-block::

        ###

    or

    .. code-block::

        #[number][,]#

    In TeX tables, "cells" to be filled with entries from the input text files are
    indicated by the following tags:

    .. code-block::

        \#\#\#

    or

    .. code-block::

        \#[number][,]\#

    The first case will result in a literal substitution.  I.e. whatever is in the text
    tables for that  cell will be copied over. The second case will convert the data
    table's number (if in scientific notation) and will truncate this converted number
    to [number] decimal places. It will automatically round while doing so.

    If a comma appears after the number, then it will add commas to the digits to the left of the decimal place.

    **Common mistakes which can lead to errors include**

    1. Mismatch between the length of the template table and the corresponding data table. If the template table has more entries to be filled than the data table has entries to fill from, this will cause an error and the table will not be filled.
    2. Use of numerical tags (e.g. #1#) to fill non-numerical data. Non-numerical data can only be filled using "###" or through the null dictionary ``null``, as it does not make sense to round or truncate this data.
    3. Multiple table objects in the same float. Each table float in the template file can only contain one table object. If a float contains a second table object, this table will not be filled.

    Parameters
    ----------
    inputs : list
        Input or list of inputs to fill into template.
    template : str
        Path of template to fill.
    output : str
        Path of output.
    null : dict
        Dictionary of null characters and their replacements.
        If replaced with ``None`` then remove value from data.
        Defaults to map ``'.'``, ``'NA'``, ``'NaN'`` to ``'NA'``, to map ``'---'``` to ``' '```,
        and to map ``''`` to ``None`` which will then be removed.

    Returns
    -------
    None

    Example
    -------

    With LyX templates (For TeX, replace ``#`` with ``\#``):

    .. code-block::

        2309.2093 + ### = 2309.2093
        2309.2093 + #4# = 2309.2093
        2309.2093 + #5# = 2309.20930
        2309.2093 + #20# = 2309.20930000000000000000
        2309.2093 + #3# = 2309.209
        2309.2093 + #2# = 2309.21
        2309.2093 + #0# = 2309
        2309.2093 + #0,# = 2,309

    .. code-block::

        -2.23e-2  + #2# = -0.0223 + #2# = -0.02
        -2.23e-2  + #7# = -0.0223 + #7# = -0.0223000
        -2.23e+10 + #7,# = -22300000000 + #7,# = -22,300,000,000.000000

    Only ``###/#num#`` will be replaced, allowing you to put things around
    ``###/#num#`` to alter the final output:

    .. code-block::

        2309.2093 + (#2#) = (2309.21)
        2309.2093 + #2#** = 2309.21**
        2309.2093 + ab#2#cd = ab2309.21cd

    If you are doing exact substitution, then you can use characters:

    .. code-block::

        abc + ### = abc

    Special substitutions can be done via the ``null`` option. By default, ``'---'``` is mapped to ``''```,
    so if you would like to display a blank cell, you can use "---":

    .. code-block::

        --- + ### = " "
        --- + #3# = " "

    Example
    -------

    Input:

    .. code-block::

        <tab:Test>
        1	2	3
        2	1	3
        3	1	2

    TeX template:

    .. code-block::

        \label{tab:Test}

        \#\#\# \#\#\# \#\#\#
        \#\#\# \#\#\# \#\#\#
        \#\#\# \#\#\# \#\#\#

    Result:

    .. code-block::

        \label{tab:Test}

        1   2   3
        2   1   3
        3   1   2

    The function doesn't "know" where the numbers should be placed within a row, only what
    the next number to place should be.

    Input:

    .. code-block::

        <tab:Test>
        1	1	2
        1	1	3
        2	-1	2

    TeX template:

    .. code-block::

        \label{tab:Test}

        \#\#\# \#\#\# \#\#\#
        abc abc abc
        \#\#\# \#2\# \#3\#
        \#\#\# \#\#\# \#\#\#

    Result:

    .. code-block::

        \label{tab:Test}

        1   1   2
        abc abc abc
        1   1.00    3.000
        2   -1  2

    If a row in the template has no substitutions, then it's not really a row from
    the program's point of view.
    """

    try:
        inputs = convert_to_list(inputs, 'file')
        inputs = [norm_path(file) for file in inputs]
        content = [_parse_content(file, null) for file in inputs]
        tables = {tag: data for (tag, data) in content}
        if (len(content) != len(tables)):
            raise_from(CritError(messages.crit_error_duplicate_tables), None)

        doc = _insert_tables(template, tables, null)

        with io.open(output, 'w', encoding='utf-8') as f:
            f.write(doc)
        message = messages.success_tablefill % (template)
        print(colored(message, metadata.color_success))
    except:
        error_message = messages.error_message % 'tablefill'
        error_message = format_message(error_message)
        raise_from(ColoredError(error_message, traceback.format_exc()), None)


__all__ = ['tablefill']
