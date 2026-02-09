"""
Wave Designer Configuration

Env-based settings adapted from the Intellivision Overlay Editor.
"""

import os
from pathlib import Path


def _get_bool(key: str, default: bool = False) -> bool:
    val = os.environ.get(key, str(default)).lower()
    return val in ('1', 'true', 'yes', 'on')


def _get_int(key: str, default: int) -> int:
    try:
        return int(os.environ.get(key, default))
    except (ValueError, TypeError):
        return default


class Config:
    BASE_DIR = Path(__file__).parent
    HOST = os.environ.get('WD_HOST', '0.0.0.0')
    PORT = _get_int('WD_PORT', 5001)
    DEBUG = _get_bool('WD_DEBUG', False)
    LOG_LEVEL = os.environ.get('WD_LOG_LEVEL', 'INFO')
    LOG_FORMAT = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
