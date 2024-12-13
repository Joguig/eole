#!/usr/bin/env python

# Unix SMB/CIFS implementation.
# Copyright (C) Jelmer Vernooij <jelmer@samba.org> 2011
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

"""The main samba-tool command implementation."""

from samba import getopt as options

from samba.netcmd import SuperCommand


class cache_loader(dict):
    """
    We only load subcommand tools if they are actually used.
    This significantly reduces the amount of time spent starting up
    samba-tool
    """

    def __getitem__(self, attr):
        item = dict.__getitem__(self, attr)
        if item is None:
            package = 'nettime' if attr == 'time' else attr
            self[attr] = getattr(__import__('gpo_utils.%s' % package,
                                            fromlist=['cmd_%s' % attr]),
                                 'cmd_%s' % attr)()
        return dict.__getitem__(self, attr)

    def iteritems(self):
        for key in self:
            yield (key, self[key])

    def items(self):
        return list(self.iteritems())


class cmd_gpo_tool(SuperCommand):
    """Eole Samba administration tool."""

    takes_optiongroups = {
        "versionopts": options.VersionOptions,
        }

    subcommands = cache_loader()

    subcommands["policy"] = None
    subcommands["importation"] = None
    subcommands["gpo"] = None
