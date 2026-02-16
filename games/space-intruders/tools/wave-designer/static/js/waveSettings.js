/**
 * Wave Settings — entrance, march speed, color palette controls
 */

import { INTV_COLORS } from './state.js';

// Only colors 0-7 for alien foreground (Color Stack mode constraint)
const FG_COLORS = INTV_COLORS.slice(0, 8);

export class WaveSettings {
    constructor(state) {
        this.state = state;
        this._buildPalettePickers();
        this._bindControls();
    }

    _buildPalettePickers() {
        ['row0', 'row1', 'row2', 'row3', 'row4'].forEach(alienType => {
            const container = document.getElementById(`palette-${alienType}`);
            if (!container) return;
            container.innerHTML = '';

            FG_COLORS.forEach(color => {
                const swatch = document.createElement('div');
                swatch.className = 'color-swatch';
                swatch.dataset.color = color.id;
                swatch.dataset.alien = alienType;
                swatch.style.backgroundColor = color.hex;
                swatch.title = `${color.id}: ${color.name}`;

                swatch.addEventListener('click', () => {
                    this.state.setPaletteColor(alienType, color.id);
                });

                container.appendChild(swatch);
            });
        });
    }

    _bindControls() {
        // Entrance dropdown
        const entranceEl = document.getElementById('entrance-type');
        if (entranceEl) {
            entranceEl.addEventListener('change', (e) => {
                this.state.setEntrance(e.target.value);
            });
        }

        // Reinforcement toggle
        const reinforceEl = document.getElementById('reinforcement-toggle');
        if (reinforceEl) {
            reinforceEl.addEventListener('change', (e) => {
                this.state.setReinforcement(e.target.checked);
            });
        }

        // March speed slider
        const speedEl = document.getElementById('march-speed');
        const speedDisplay = document.getElementById('march-speed-value');
        if (speedEl) {
            speedEl.addEventListener('input', (e) => {
                this.state.setMarchSpeed(e.target.value);
                if (speedDisplay) speedDisplay.textContent = e.target.value;
            });
        }
    }

    render() {
        const wave = this.state.wave;

        // Update entrance dropdown
        const entranceEl = document.getElementById('entrance-type');
        if (entranceEl) entranceEl.value = wave.entrance;

        // Update reinforcement toggle
        const reinforceEl = document.getElementById('reinforcement-toggle');
        const reinforceBadge = document.getElementById('reinforce-badge');
        if (reinforceEl) reinforceEl.checked = wave.reinforcement || false;
        if (reinforceBadge) reinforceBadge.classList.toggle('active', wave.reinforcement || false);

        // Update speed slider
        const speedEl = document.getElementById('march-speed');
        const speedDisplay = document.getElementById('march-speed-value');
        if (speedEl) speedEl.value = wave.marchSpeed;
        if (speedDisplay) speedDisplay.textContent = wave.marchSpeed;

        // Update palette swatches
        ['row0', 'row1', 'row2', 'row3', 'row4'].forEach(alienType => {
            const container = document.getElementById(`palette-${alienType}`);
            if (!container) return;
            const selected = wave.palette[alienType];
            container.querySelectorAll('.color-swatch').forEach(swatch => {
                swatch.classList.toggle('selected', parseInt(swatch.dataset.color) === selected);
            });
        });

        // Update wave tabs (highlight reinforcement waves)
        document.querySelectorAll('.wave-tab').forEach((tab, i) => {
            tab.classList.toggle('active', i === this.state.currentWave);
            const hasReinforce = this.state.waves[i] && this.state.waves[i].reinforcement;
            tab.classList.toggle('reinforcement', hasReinforce || false);
        });
    }

    onStateChange(event) {
        this.render();
    }
}
