# -*- coding: utf-8 -*-

import sys
try:
    import config
    import fonctions
    import registre
except ImportError:  # pragma: no cover
    err = sys.exc_info()[1]
    raise ImportError(str(err) + '''A critical module was not found. Probably this operating system does not support it. Joineole is intended for UNIX-like operating systems.''')

__version__ = '1.0'
__revision__ = ''
__all__ = [ 'config', 'fonctions', 'registre', '__version__', '__revision__']

PY3 = (sys.version_info[0] >= 3)
