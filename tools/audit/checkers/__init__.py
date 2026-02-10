"""Auto-discovery for audit checker modules.

Each checker module must define:
    NAME: str           - Short kebab-case name (e.g., 'duplicate-code')
    DESCRIPTION: str    - One-line description
    run(source, lst_info) -> list[Finding]
"""

import importlib
import pkgutil


def discover_checkers():
    """Discover all checker modules in this package.

    Returns dict of {name: module}.
    """
    checkers = {}
    package_path = __path__
    for importer, modname, ispkg in pkgutil.iter_modules(package_path):
        if modname.startswith('_'):
            continue
        module = importlib.import_module(f'.{modname}', package=__name__)
        if hasattr(module, 'NAME') and hasattr(module, 'run'):
            checkers[module.NAME] = module
    return checkers
