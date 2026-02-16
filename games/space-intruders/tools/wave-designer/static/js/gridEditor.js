/**
 * Grid Editor — 9x5 alien formation editor with boss placement
 */

import {
    GRID_COLS, GRID_ROWS, ALIEN_TYPES, INTV_COLORS,
    SKULL_TYPE, BOMB_TYPE, MAX_BOSSES
} from './state.js';

// Unicode glyphs for alien types (5 rows)
const ALIEN_GLYPHS = [
    '\u{1F47E}',  // Row 0: alien emoji
    '\u{1F577}',  // Row 1: spider
    '\u{1F41E}',  // Row 2: beetle
    '\u{1F997}',  // Row 3: cricket
    '\u{1FABC}',  // Row 4: jellyfish
];

export class GridEditor {
    constructor(container, colLabelContainer, state) {
        this.container = container;
        this.colLabelContainer = colLabelContainer;
        this.state = state;
        this.cells = [];
        this._buildColLabels();
        this._buildGrid();
        this._bindToolbar();
    }

    _buildColLabels() {
        // Empty cell for row label column
        const spacer = document.createElement('div');
        spacer.className = 'grid-label';
        this.colLabelContainer.appendChild(spacer);

        for (let c = 0; c < GRID_COLS; c++) {
            const label = document.createElement('div');
            label.className = 'grid-label';
            label.textContent = c;
            this.colLabelContainer.appendChild(label);
        }
    }

    _buildGrid() {
        this.container.innerHTML = '';
        this.cells = [];

        for (let r = 0; r < GRID_ROWS; r++) {
            const rowEl = document.createElement('div');
            rowEl.className = 'grid-row';

            // Row label
            const label = document.createElement('div');
            label.className = 'row-label';
            label.textContent = `R${r}`;
            rowEl.appendChild(label);

            const rowCells = [];
            for (let c = 0; c < GRID_COLS; c++) {
                const cell = document.createElement('div');
                cell.className = 'grid-cell dead';
                cell.dataset.row = r;
                cell.dataset.col = c;

                cell.addEventListener('click', (e) => this._onCellClick(r, c, e));
                cell.addEventListener('contextmenu', (e) => {
                    e.preventDefault();
                    this.state.removeBossAt(r, c);
                });

                rowEl.appendChild(cell);
                rowCells.push(cell);
            }
            this.cells.push(rowCells);
            this.container.appendChild(rowEl);
        }
    }

    _onCellClick(row, col) {
        const tool = this.state.activeTool;
        switch (tool) {
            case 'toggle':
                this.state.toggleCell(row, col);
                break;
            case 'skull':
                this.state.addBoss(col, row, SKULL_TYPE);
                break;
            case 'bomb':
                this.state.addBoss(col, row, BOMB_TYPE);
                break;
            case 'remove-boss':
                this.state.removeBossAt(row, col);
                break;
        }
    }

    _bindToolbar() {
        const toolbar = document.getElementById('boss-toolbar');
        if (!toolbar) return;
        toolbar.addEventListener('click', (e) => {
            const btn = e.target.closest('.boss-tool');
            if (!btn) return;
            this.state.setActiveTool(btn.dataset.tool);
        });
    }

    render() {
        const wave = this.state.wave;
        const palette = wave.palette;
        const bosses = wave.patternB.bosses;

        // Build boss lookup for fast cell check
        const bossMap = new Map();
        bosses.forEach((b, idx) => {
            bossMap.set(`${b.row},${b.col}`, { boss: b, idx, side: 'left' });
            bossMap.set(`${b.row},${b.col + 1}`, { boss: b, idx, side: 'right' });
        });

        for (let r = 0; r < GRID_ROWS; r++) {
            for (let c = 0; c < GRID_COLS; c++) {
                const cell = this.cells[r][c];
                const alive = this.state.isCellAlive(r, c);
                const rowKey = `row${r}`;  // Palette uses row0, row1, row2, row3, row4
                const colorIdx = palette[rowKey];
                const bossInfo = bossMap.get(`${r},${c}`);

                // Reset classes
                cell.className = 'grid-cell';
                cell.innerHTML = '';

                if (alive) {
                    cell.classList.add('alive');
                    cell.style.backgroundColor = INTV_COLORS[colorIdx].hex;
                    // Ensure text is visible
                    cell.style.color = colorIdx === 0 ? '#333' : '#000';
                    cell.textContent = ALIEN_GLYPHS[r] || '\u25A0';
                } else {
                    cell.classList.add('dead');
                    cell.style.backgroundColor = '';
                    cell.style.color = '';
                }

                if (bossInfo) {
                    const typeName = bossInfo.boss.type === SKULL_TYPE ? 'skull' : 'bomb';
                    cell.classList.add(`boss-${typeName}`, `boss-${bossInfo.side}`);
                    // Boss icon overlay
                    const icon = document.createElement('span');
                    icon.className = 'boss-icon';
                    icon.textContent = bossInfo.boss.type === SKULL_TYPE ? '\u2620' : '\u{1F4A3}';
                    cell.appendChild(icon);

                    // Tint with boss color
                    if (alive) {
                        cell.style.backgroundColor = INTV_COLORS[bossInfo.boss.color].hex;
                    }
                }
            }
        }

        // Update alive count
        const countEl = document.getElementById('alive-count');
        if (countEl) {
            const total = this.state.getAliveCount();
            countEl.textContent = `${total}/45 alive`;
        }

        // Update tool buttons
        document.querySelectorAll('.boss-tool').forEach(btn => {
            btn.classList.toggle('active', btn.dataset.tool === this.state.activeTool);
        });

        // Render boss list
        this._renderBossList(bosses);

        // Update boss count display
        const bossCountEl = document.getElementById('boss-count-display');
        if (bossCountEl) {
            bossCountEl.textContent = `${bosses.length}/${MAX_BOSSES} bosses`;
        }
    }

    _renderBossList(bosses) {
        const list = document.getElementById('boss-list');
        if (!list) return;
        list.innerHTML = '';

        if (bosses.length === 0) {
            list.innerHTML = '<div class="helper-text">No bosses placed. Use toolbar to place.</div>';
            return;
        }

        bosses.forEach((boss, idx) => {
            const card = document.createElement('div');
            card.className = 'boss-card';

            const typeName = boss.type === SKULL_TYPE ? 'skull' : 'bomb';
            const typeLabel = boss.type === SKULL_TYPE ? 'Skull' : 'Bomb';

            card.innerHTML = `
                <span class="boss-type-badge ${typeName}">${typeLabel}</span>
                <span class="boss-detail">Col ${boss.col}-${boss.col + 1}, Row ${boss.row}</span>
                <label>HP:
                    <select class="boss-hp" data-idx="${idx}">
                        <option value="1" ${boss.hp === 1 ? 'selected' : ''}>1</option>
                        <option value="2" ${boss.hp === 2 ? 'selected' : ''}>2</option>
                        <option value="3" ${boss.hp === 3 ? 'selected' : ''}>3</option>
                    </select>
                </label>
                <label>Color:
                    <select class="boss-color" data-idx="${idx}">
                        ${INTV_COLORS.map(c =>
                            `<option value="${c.id}" ${boss.color === c.id ? 'selected' : ''}>${c.id}: ${c.name}</option>`
                        ).join('')}
                    </select>
                </label>
                ${boss.type === BOMB_TYPE ? `
                    <label>
                        <input type="checkbox" class="boss-orbiter" data-idx="${idx}"
                            ${boss.orbiter ? 'checked' : ''}>
                        Orbiter
                    </label>
                ` : ''}
                <button class="btn btn-danger boss-remove" data-idx="${idx}">X</button>
            `;

            // Wire events
            card.querySelector('.boss-hp')?.addEventListener('change', (e) => {
                this.state.updateBoss(idx, { hp: parseInt(e.target.value) });
            });
            card.querySelector('.boss-color')?.addEventListener('change', (e) => {
                this.state.updateBoss(idx, { color: parseInt(e.target.value) });
            });
            card.querySelector('.boss-orbiter')?.addEventListener('change', (e) => {
                this.state.updateBoss(idx, { orbiter: e.target.checked });
            });
            card.querySelector('.boss-remove')?.addEventListener('click', () => {
                this.state.removeBoss(idx);
            });

            list.appendChild(card);
        });
    }

    onStateChange(event) {
        this.render();
    }
}
