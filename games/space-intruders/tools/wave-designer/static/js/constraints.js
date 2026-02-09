/**
 * Constraint Engine — real-time validation for wave designs
 */

import { GRID_COLS, GRID_ROWS, MAX_BOSSES, SKULL_TYPE, BOMB_TYPE } from './state.js';

export class ConstraintEngine {
    constructor(container, state) {
        this.container = container;
        this.state = state;
    }

    validate() {
        const wave = this.state.wave;
        const rows = wave.patternB.rows;
        const bosses = wave.patternB.bosses;
        const warnings = [];

        // 1. Dead formation
        const aliveCount = this.state.getAliveCount();
        if (aliveCount === 0) {
            warnings.push({ level: 'error', msg: 'No alive aliens in formation' });
        } else if (aliveCount < 5) {
            warnings.push({ level: 'warn', msg: `Very sparse formation (${aliveCount} aliens)` });
        } else {
            warnings.push({ level: 'ok', msg: `${aliveCount}/45 aliens alive` });
        }

        // 2. Boss count
        if (bosses.length > MAX_BOSSES) {
            warnings.push({ level: 'error', msg: `Too many bosses: ${bosses.length}/${MAX_BOSSES}` });
        } else {
            warnings.push({ level: 'ok', msg: `Boss count: ${bosses.length}/${MAX_BOSSES}` });
        }

        // 3. Per-boss validation
        let orbiterCount = 0;
        bosses.forEach((b, i) => {
            // Column range
            if (b.col >= GRID_COLS - 1) {
                warnings.push({ level: 'error', msg: `Boss ${i + 1}: col ${b.col} needs col ${b.col + 1} (out of range)` });
            }

            // Alive cells
            if (!this.state.isCellAlive(b.row, b.col)) {
                warnings.push({ level: 'error', msg: `Boss ${i + 1}: cell (${b.col},${b.row}) is dead` });
            }
            if (b.col < GRID_COLS - 1 && !this.state.isCellAlive(b.row, b.col + 1)) {
                warnings.push({ level: 'error', msg: `Boss ${i + 1}: cell (${b.col + 1},${b.row}) is dead` });
            }

            // Orbiter checks
            if (b.orbiter) {
                orbiterCount++;
                if (b.type !== BOMB_TYPE) {
                    warnings.push({ level: 'error', msg: `Boss ${i + 1}: only bomb bosses can have orbiters` });
                }
                if (i >= 2) {
                    warnings.push({ level: 'warn', msg: `Boss ${i + 1}: orbiter only works on boss slots 0-1 (indices 0-1)` });
                }
            }
        });

        // 4. Boss overlap check
        for (let i = 0; i < bosses.length; i++) {
            for (let j = i + 1; j < bosses.length; j++) {
                if (bosses[i].row === bosses[j].row) {
                    const a0 = bosses[i].col, a1 = bosses[i].col + 1;
                    const b0 = bosses[j].col, b1 = bosses[j].col + 1;
                    if (a0 <= b1 && b0 <= a1) {
                        warnings.push({ level: 'error', msg: `Bosses ${i + 1} and ${j + 1} overlap on row ${bosses[i].row}` });
                    }
                }
            }
        }

        // 5. Orbiter count
        if (orbiterCount > 2) {
            warnings.push({ level: 'error', msg: `Too many orbiters: ${orbiterCount}/2` });
        } else if (orbiterCount > 0) {
            warnings.push({ level: 'ok', msg: `Orbiters: ${orbiterCount}/2` });
        }

        // 6. Black alien warning
        const pal = wave.palette;
        if (pal.squid === 0 || pal.crab === 0 || pal.octopus === 0) {
            warnings.push({ level: 'warn', msg: 'Black aliens invisible on black background' });
        }

        // 7. Reinforcement status
        const reinforceCount = this.state.waves.filter(w => w.reinforcement).length;
        if (wave.reinforcement) {
            warnings.push({ level: 'ok', msg: `Second horde enabled (${reinforceCount} waves total)` });
        } else if (reinforceCount > 0) {
            warnings.push({ level: 'ok', msg: `Second horde: off (${reinforceCount} other waves have it)` });
        }

        // 8. Palette MOD 6 conflict (waves sharing same MOD 6 slot have same colors)
        const mod6Slot = this.state.currentWave % 6;
        for (let other = 0; other < this.state.waves.length; other++) {
            if (other === this.state.currentWave) continue;
            if (other % 6 !== mod6Slot) continue;
            const otherPal = this.state.waves[other].palette;
            const currentPal = wave.palette;
            if (currentPal.squid !== otherPal.squid ||
                currentPal.crab !== otherPal.crab ||
                currentPal.octopus !== otherPal.octopus) {
                warnings.push({
                    level: 'warn',
                    msg: `Wave ${this.state.currentWave + 1} shares palette slot with Wave ${other + 1} (MOD 6) — colors differ`
                });
                break;  // One warning is enough
            }
        }

        return warnings;
    }

    render() {
        const itemsEl = document.getElementById('constraint-items');
        if (!itemsEl) return;

        const warnings = this.validate();
        itemsEl.innerHTML = '';

        warnings.forEach(w => {
            const item = document.createElement('div');
            item.className = `constraint-item constraint-${w.level}`;

            const icon = w.level === 'ok' ? '\u2713' : w.level === 'warn' ? '\u26A0' : '\u2717';
            item.innerHTML = `<span class="constraint-icon">${icon}</span> ${w.msg}`;
            itemsEl.appendChild(item);
        });
    }

    onStateChange(event) {
        this.render();
    }
}
