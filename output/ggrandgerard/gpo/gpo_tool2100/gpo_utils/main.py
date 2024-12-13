#!/usr/bin/env python3

"""The main samba-tool command implementation."""

from samba import getopt as options
from samba.netcmd import SuperCommand
from samba.netcmd.gpo import cmd_gpo


class cache_loader(dict):
    """
    We only load subcommand tools if they are actually used.
    This significantly reduces the amount of time spent starting up
    gpo-tool
    """
    def __getitem__(self, attr):
        item = dict.__getitem__(self, attr)
        if item is None:
            package = 'nettime' if attr == 'time' else attr
            self[attr] = getattr(__import__(f'gpo_utils.{package}',
                                            fromlist=[f'cmd_{attr}']),
                                 f'cmd_{attr}')()
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
    subcommands["helper"] = None
    subcommands["gpo"] = cmd_gpo()
