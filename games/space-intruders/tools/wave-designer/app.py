"""
Space Intruders Wave Designer

Minimal Flask backend serving the single-page wave editor.
"""

import logging
import os
import subprocess

from flask import Flask, render_template, jsonify
from config import Config

logging.basicConfig(
    level=getattr(logging, Config.LOG_LEVEL),
    format=Config.LOG_FORMAT
)
logger = logging.getLogger(__name__)

app = Flask(__name__)


def get_git_info():
    """Get git version info for display in the header."""
    info = {
        'commit_hash': os.environ.get('GIT_COMMIT_HASH', ''),
        'commit_date': os.environ.get('GIT_COMMIT_DATE', ''),
    }
    if not info['commit_hash']:
        try:
            info['commit_hash'] = subprocess.check_output(
                ['git', 'rev-parse', '--short', 'HEAD'],
                stderr=subprocess.DEVNULL
            ).decode().strip()
        except Exception:
            info['commit_hash'] = 'dev'
    return info


@app.route('/')
def index():
    return render_template('wave_designer.html', git_info=get_git_info())


@app.route('/health')
def health():
    return jsonify({'status': 'ok'}), 200


if __name__ == '__main__':
    logger.info(f"Starting Wave Designer on {Config.HOST}:{Config.PORT}")
    app.run(debug=Config.DEBUG, host=Config.HOST, port=Config.PORT)
