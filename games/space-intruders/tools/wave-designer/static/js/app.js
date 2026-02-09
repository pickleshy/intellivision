/**
 * Space Intruders Wave Designer — Entry Point
 *
 * Initializes all modules and wires state changes.
 */

import { state, TOTAL_WAVES } from './state.js';
import { GridEditor } from './gridEditor.js';
import { WaveSettings } from './waveSettings.js';
import { ConstraintEngine } from './constraints.js';
import { Exporter } from './exporter.js';

document.addEventListener('DOMContentLoaded', () => {

    // Build wave tabs (32 waves, grouped in rows of 8)
    const tabContainer = document.getElementById('wave-tabs');
    for (let i = 0; i < TOTAL_WAVES; i++) {
        if (i > 0 && i % 8 === 0) {
            tabContainer.appendChild(document.createElement('br'));
        }
        const tab = document.createElement('button');
        tab.className = 'wave-tab';
        tab.textContent = `${i + 1}`;
        tab.dataset.wave = i;
        tab.addEventListener('click', () => state.setCurrentWave(i));
        tabContainer.appendChild(tab);
    }

    // Initialize modules
    const gridEditor = new GridEditor(
        document.getElementById('grid-container'),
        document.getElementById('grid-col-labels'),
        state
    );
    const waveSettings = new WaveSettings(state);
    const constraintEngine = new ConstraintEngine(
        document.getElementById('constraints'),
        state
    );
    const exporter = new Exporter(state);

    // Subscribe all modules to state changes
    state.subscribe((event, data) => {
        gridEditor.onStateChange(event, data);
        waveSettings.onStateChange(event, data);
        constraintEngine.onStateChange(event, data);
    });

    // Header buttons
    document.getElementById('btn-export').addEventListener('click', () => exporter.showExportModal());
    document.getElementById('btn-import').addEventListener('click', () => exporter.showImportModal());
    document.getElementById('btn-save-json').addEventListener('click', () => exporter.saveJSON());
    document.getElementById('btn-load-json').addEventListener('click', () => exporter.loadJSON());

    // Modal buttons
    document.getElementById('btn-copy-export').addEventListener('click', () => exporter.copyToClipboard());
    document.getElementById('btn-do-import').addEventListener('click', () => exporter.doImport());

    // Modal close buttons
    document.querySelectorAll('.modal-close').forEach(btn => {
        btn.addEventListener('click', () => btn.closest('.modal').classList.add('hidden'));
    });

    // Close modals on backdrop click
    document.querySelectorAll('.modal').forEach(modal => {
        modal.addEventListener('click', (e) => {
            if (e.target === modal) modal.classList.add('hidden');
        });
    });

    // JSON file input
    document.getElementById('json-file-input').addEventListener('change', (e) => {
        exporter.handleFileLoad(e);
    });

    // Initialize UI with wave 1
    state.setCurrentWave(0);
});
