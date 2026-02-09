/**
 * Space Intruders Wave Designer — State Management
 *
 * Central data model with observer pattern. All game defaults
 * extracted from main.bas DATA tables and LoadPatternB.
 */

// Intellivision color palette (STIC hardware)
export const INTV_COLORS = [
    { id: 0,  name: 'Black',        hex: '#000000' },
    { id: 1,  name: 'Blue',         hex: '#002DFF' },
    { id: 2,  name: 'Red',          hex: '#FF3D10' },
    { id: 3,  name: 'Tan',          hex: '#C9D464' },
    { id: 4,  name: 'Dark Green',   hex: '#00780F' },
    { id: 5,  name: 'Green',        hex: '#00A720' },
    { id: 6,  name: 'Yellow',       hex: '#FAEA27' },
    { id: 7,  name: 'White',        hex: '#FFFCFF' },
    { id: 8,  name: 'Grey',         hex: '#A7A8A8' },
    { id: 9,  name: 'Cyan',         hex: '#5ACBFF' },
    { id: 10, name: 'Orange',       hex: '#FFA600' },
    { id: 11, name: 'Brown',        hex: '#3C5800' },
    { id: 12, name: 'Pink',         hex: '#FF3276' },
    { id: 13, name: 'Light Blue',   hex: '#BD95FF' },
    { id: 14, name: 'Yellow-Green', hex: '#6CCD30' },
    { id: 15, name: 'Purple',       hex: '#C81A7D' },
];

export const GRID_COLS = 9;
export const GRID_ROWS = 5;
export const MAX_BOSSES = 4;
export const SKULL_TYPE = 0;
export const BOMB_TYPE = 1;
export const MARCH_SPEED_MIN = 24;
export const MARCH_SPEED_MAX = 60;

// Alien type names by row
export const ALIEN_TYPES = ['squid', 'crab', 'crab', 'octopus', 'octopus'];

export const TOTAL_WAVES = 32;

// ── Default game data (from main.bas — 32-wave cycle) ──

const DEFAULT_PATTERNS = [
    [0x081, 0x042, 0x024, 0x018, 0x024], //  0: Chevron
    [0x0D6, 0x038, 0x06C, 0x092, 0x000], //  1: Diamond
    [0x119, 0x13D, 0x119, 0x101, 0x101], //  2: Pillars
    [0x101, 0x10D, 0x101, 0x161, 0x101], //  3: Dual Pillars
    [0x155, 0x0AA, 0x155, 0x0AA, 0x155], //  4: Checkerboard
    [0x010, 0x028, 0x044, 0x082, 0x101], //  5: Arrow
    [0x038, 0x07C, 0x0FE, 0x07C, 0x038], //  6: Fortress
    [0x1FF, 0x000, 0x1FF, 0x000, 0x1FF], //  7: Phalanx
    [0x010, 0x038, 0x1FF, 0x038, 0x010], //  8: Cross
    [0x183, 0x0C6, 0x000, 0x0C6, 0x183], //  9: Wings
    [0x007, 0x038, 0x1C0, 0x038, 0x007], // 10: Zigzag
    [0x1FF, 0x101, 0x101, 0x101, 0x1FF], // 11: Frame
    [0x111, 0x000, 0x054, 0x000, 0x111], // 12: Scatter
    [0x1FF, 0x07C, 0x038, 0x010, 0x000], // 13: Funnel
    [0x010, 0x028, 0x044, 0x0AA, 0x1FF], // 14: Inverted V
    [0x1FF, 0x1FF, 0x000, 0x1FF, 0x1FF], // 15: Dense Rows
];

const DEFAULT_PATTERN_INDEX = [
    // Waves 1-8: introductory
    0, 1, 2, 3, 4, 5, 6, 7,
    // Waves 9-16: mix new + old
    8, 9, 10, 11, 0, 12, 13, 14,
    // Waves 17-24: harder combos
    15, 6, 9, 4, 11, 8, 3, 5,
    // Waves 25-32: endgame gauntlet
    14, 2, 10, 15, 13, 7, 12, 6,
];

const DEFAULT_ENTRANCES = [
    1, 0, 2, 0, 2, 0, 1, 2,  // Waves  1-8
    0, 2, 1, 0, 2, 1, 0, 2,  // Waves  9-16
    2, 0, 1, 2, 0, 1, 2, 0,  // Waves 17-24
    1, 2, 0, 2, 1, 0, 2, 1,  // Waves 25-32
];

// 6 palettes cycling via (wave) MOD 6
// Each: [squid_color, crab_color, octopus_color]
const PALETTE_BANK = [
    [6, 7, 5], // palette 0
    [1, 2, 3], // palette 1
    [5, 6, 1], // palette 2
    [2, 1, 3], // palette 3
    [7, 5, 2], // palette 4
    [3, 6, 7], // palette 5
];

// Map 32 waves to palette bank via MOD 6
function getDefaultPalette(waveIndex) {
    const p = PALETTE_BANK[waveIndex % 6];
    return { squid: p[0], crab: p[1], octopus: p[2] };
}

// Reinforcement waves (second horde before Pattern B)
// 0-based wave indices where Col = (Level-1) AND 31
const DEFAULT_REINFORCEMENTS = new Set([2, 10, 18, 26]); // Waves 3, 11, 19, 27

// Boss placements per wave (from LoadPatternB IF chain — 32 waves)
const DEFAULT_BOSSES = [
    // Wave 1: 1 skull
    [{ col: 3, row: 3, hp: 3, color: 9, type: SKULL_TYPE, orbiter: false }],
    // Wave 2: 2 skulls
    [
        { col: 2, row: 2, hp: 3, color: 9, type: SKULL_TYPE, orbiter: false },
        { col: 5, row: 2, hp: 3, color: 9, type: SKULL_TYPE, orbiter: false },
    ],
    // Wave 3: bomb + orbiter
    [{ col: 3, row: 1, hp: 2, color: 10, type: BOMB_TYPE, orbiter: true }],
    // Wave 4: 2 bombs + 2 orbiters
    [
        { col: 2, row: 1, hp: 2, color: 10, type: BOMB_TYPE, orbiter: true },
        { col: 5, row: 3, hp: 2, color: 10, type: BOMB_TYPE, orbiter: true },
    ],
    // Wave 5: no bosses
    [],
    // Wave 6: no bosses
    [],
    // Wave 7: 1 skull
    [{ col: 3, row: 1, hp: 3, color: 12, type: SKULL_TYPE, orbiter: false }],
    // Wave 8: 2 skulls
    [
        { col: 2, row: 0, hp: 3, color: 9, type: SKULL_TYPE, orbiter: false },
        { col: 2, row: 4, hp: 3, color: 10, type: SKULL_TYPE, orbiter: false },
    ],
    // Wave 9: 1 skull
    [{ col: 3, row: 2, hp: 3, color: 12, type: SKULL_TYPE, orbiter: false }],
    // Wave 10: 2 skulls
    [
        { col: 0, row: 1, hp: 3, color: 9, type: SKULL_TYPE, orbiter: false },
        { col: 6, row: 1, hp: 3, color: 9, type: SKULL_TYPE, orbiter: false },
    ],
    // Wave 11: bomb + orbiter
    [{ col: 4, row: 2, hp: 2, color: 10, type: BOMB_TYPE, orbiter: true }],
    // Wave 12: 2 skulls
    [
        { col: 0, row: 0, hp: 3, color: 12, type: SKULL_TYPE, orbiter: false },
        { col: 7, row: 4, hp: 3, color: 12, type: SKULL_TYPE, orbiter: false },
    ],
    // Wave 13: no bosses (breather)
    [],
    // Wave 14: 1 bomb
    [{ col: 2, row: 2, hp: 2, color: 10, type: BOMB_TYPE, orbiter: false }],
    // Wave 15: 1 skull
    [{ col: 3, row: 0, hp: 3, color: 9, type: SKULL_TYPE, orbiter: false }],
    // Wave 16: 2 bombs + orbiter
    [
        { col: 1, row: 4, hp: 2, color: 10, type: BOMB_TYPE, orbiter: true },
        { col: 5, row: 4, hp: 2, color: 10, type: BOMB_TYPE, orbiter: false },
    ],
    // Wave 17: 3 skulls
    [
        { col: 1, row: 0, hp: 3, color: 9, type: SKULL_TYPE, orbiter: false },
        { col: 4, row: 0, hp: 3, color: 12, type: SKULL_TYPE, orbiter: false },
        { col: 7, row: 4, hp: 3, color: 10, type: SKULL_TYPE, orbiter: false },
    ],
    // Wave 18: 2 bombs + 2 orbiters
    [
        { col: 1, row: 1, hp: 2, color: 10, type: BOMB_TYPE, orbiter: true },
        { col: 5, row: 3, hp: 2, color: 10, type: BOMB_TYPE, orbiter: true },
    ],
    // Wave 19: skull + bomb w/ orbiter
    [
        { col: 1, row: 1, hp: 2, color: 10, type: BOMB_TYPE, orbiter: true },
        { col: 6, row: 3, hp: 3, color: 9, type: SKULL_TYPE, orbiter: false },
    ],
    // Wave 20: 2 bombs + 2 orbiters
    [
        { col: 1, row: 0, hp: 2, color: 10, type: BOMB_TYPE, orbiter: true },
        { col: 5, row: 4, hp: 2, color: 10, type: BOMB_TYPE, orbiter: true },
    ],
    // Wave 21: 3 skulls
    [
        { col: 0, row: 0, hp: 3, color: 12, type: SKULL_TYPE, orbiter: false },
        { col: 7, row: 0, hp: 3, color: 12, type: SKULL_TYPE, orbiter: false },
        { col: 3, row: 4, hp: 3, color: 9, type: SKULL_TYPE, orbiter: false },
    ],
    // Wave 22: bomb + orbiter + 2 skulls
    [
        { col: 3, row: 2, hp: 2, color: 10, type: BOMB_TYPE, orbiter: true },
        { col: 1, row: 0, hp: 3, color: 9, type: SKULL_TYPE, orbiter: false },
        { col: 1, row: 4, hp: 3, color: 9, type: SKULL_TYPE, orbiter: false },
    ],
    // Wave 23: no bosses (breather)
    [],
    // Wave 24: 2 skulls
    [
        { col: 1, row: 3, hp: 3, color: 12, type: SKULL_TYPE, orbiter: false },
        { col: 5, row: 4, hp: 3, color: 12, type: SKULL_TYPE, orbiter: false },
    ],
    // Wave 25: 4 bosses — bomb + 3 skulls
    [
        { col: 1, row: 4, hp: 2, color: 10, type: BOMB_TYPE, orbiter: true },
        { col: 5, row: 3, hp: 3, color: 9, type: SKULL_TYPE, orbiter: false },
        { col: 3, row: 2, hp: 3, color: 12, type: SKULL_TYPE, orbiter: false },
        { col: 7, row: 4, hp: 3, color: 9, type: SKULL_TYPE, orbiter: false },
    ],
    // Wave 26: 2 bombs + 2 orbiters
    [
        { col: 3, row: 1, hp: 2, color: 10, type: BOMB_TYPE, orbiter: true },
        { col: 3, row: 3, hp: 2, color: 10, type: BOMB_TYPE, orbiter: true },
    ],
    // Wave 27: 3 skulls
    [
        { col: 0, row: 0, hp: 3, color: 9, type: SKULL_TYPE, orbiter: false },
        { col: 4, row: 2, hp: 3, color: 12, type: SKULL_TYPE, orbiter: false },
        { col: 0, row: 4, hp: 3, color: 9, type: SKULL_TYPE, orbiter: false },
    ],
    // Wave 28: 4 bosses — 2 bombs + 2 skulls
    [
        { col: 1, row: 0, hp: 2, color: 10, type: BOMB_TYPE, orbiter: true },
        { col: 5, row: 0, hp: 2, color: 10, type: BOMB_TYPE, orbiter: true },
        { col: 1, row: 4, hp: 3, color: 9, type: SKULL_TYPE, orbiter: false },
        { col: 5, row: 4, hp: 3, color: 12, type: SKULL_TYPE, orbiter: false },
    ],
    // Wave 29: 2 skulls
    [
        { col: 1, row: 0, hp: 3, color: 12, type: SKULL_TYPE, orbiter: false },
        { col: 6, row: 0, hp: 3, color: 12, type: SKULL_TYPE, orbiter: false },
    ],
    // Wave 30: 3 skulls
    [
        { col: 0, row: 0, hp: 3, color: 9, type: SKULL_TYPE, orbiter: false },
        { col: 4, row: 2, hp: 3, color: 12, type: SKULL_TYPE, orbiter: false },
        { col: 0, row: 4, hp: 3, color: 10, type: SKULL_TYPE, orbiter: false },
    ],
    // Wave 31: 2 bombs + 2 orbiters
    [
        { col: 2, row: 0, hp: 2, color: 10, type: BOMB_TYPE, orbiter: true },
        { col: 5, row: 2, hp: 2, color: 10, type: BOMB_TYPE, orbiter: true },
    ],
    // Wave 32: FINAL — 4 bosses max
    [
        { col: 1, row: 1, hp: 2, color: 10, type: BOMB_TYPE, orbiter: true },
        { col: 5, row: 1, hp: 2, color: 10, type: BOMB_TYPE, orbiter: true },
        { col: 1, row: 3, hp: 3, color: 12, type: SKULL_TYPE, orbiter: false },
        { col: 5, row: 3, hp: 3, color: 9, type: SKULL_TYPE, orbiter: false },
    ],
];

// ── State Class ──

export class WaveDesignerState {
    constructor() {
        this.currentWave = 0;
        this.waves = [];
        this.activeTool = 'toggle';
        this._listeners = new Set();
        this._initDefaults();
    }

    _initDefaults() {
        this.waves = Array.from({ length: TOTAL_WAVES }, (_, i) => ({
            entrance: DEFAULT_ENTRANCES[i],
            marchSpeed: Math.max(MARCH_SPEED_MIN, MARCH_SPEED_MAX - i * 2),
            palette: getDefaultPalette(i),
            reinforcement: DEFAULT_REINFORCEMENTS.has(i),
            patternB: {
                rows: [...DEFAULT_PATTERNS[DEFAULT_PATTERN_INDEX[i]]],
                bosses: JSON.parse(JSON.stringify(DEFAULT_BOSSES[i])),
            },
        }));
    }

    // ── Observer ──

    subscribe(fn) { this._listeners.add(fn); }
    unsubscribe(fn) { this._listeners.delete(fn); }
    _notify(event, data) {
        for (const fn of this._listeners) fn(event, data);
    }

    // ── Wave selection ──

    setCurrentWave(index) {
        this.currentWave = index;
        this._notify('waveChanged', index);
    }

    get wave() { return this.waves[this.currentWave]; }

    // ── Grid ──

    isCellAlive(row, col) {
        return (this.wave.patternB.rows[row] & (1 << col)) !== 0;
    }

    toggleCell(row, col) {
        this.wave.patternB.rows[row] ^= (1 << col);
        this._notify('gridChanged', { row, col });
    }

    setCellAlive(row, col, alive) {
        const mask = 1 << col;
        if (alive) this.wave.patternB.rows[row] |= mask;
        else this.wave.patternB.rows[row] &= ~mask;
        this._notify('gridChanged', { row, col });
    }

    setAllCells(alive) {
        const val = alive ? 0x1FF : 0;
        for (let r = 0; r < GRID_ROWS; r++) {
            this.wave.patternB.rows[r] = val;
        }
        this._notify('gridChanged', {});
    }

    // ── Bosses ──

    addBoss(col, row, type) {
        const bosses = this.wave.patternB.bosses;
        if (bosses.length >= MAX_BOSSES) return false;
        if (col >= GRID_COLS - 1) return false; // need 2 columns

        // Check for overlap
        for (const b of bosses) {
            if (b.row === row && (b.col === col || b.col === col - 1 || b.col === col + 1)) {
                return false;
            }
        }

        const defaultHp = type === BOMB_TYPE ? 2 : 3;
        const defaultColor = type === BOMB_TYPE ? 10 : 9;
        bosses.push({ col, row, hp: defaultHp, color: defaultColor, type, orbiter: false });

        // Ensure both boss columns are alive
        this.setCellAlive(row, col, true);
        this.setCellAlive(row, col + 1, true);

        this._notify('bossChanged', {});
        return true;
    }

    removeBoss(index) {
        this.wave.patternB.bosses.splice(index, 1);
        this._notify('bossChanged', {});
    }

    removeBossAt(row, col) {
        const bosses = this.wave.patternB.bosses;
        const idx = bosses.findIndex(b => b.row === row && (b.col === col || b.col + 1 === col));
        if (idx >= 0) {
            bosses.splice(idx, 1);
            this._notify('bossChanged', {});
            return true;
        }
        return false;
    }

    updateBoss(index, changes) {
        Object.assign(this.wave.patternB.bosses[index], changes);
        this._notify('bossChanged', {});
    }

    getBossAt(row, col) {
        return this.wave.patternB.bosses.find(
            b => b.row === row && (b.col === col || b.col + 1 === col)
        ) || null;
    }

    // ── Settings ──

    setEntrance(value) {
        this.wave.entrance = parseInt(value);
        this._notify('settingsChanged', {});
    }

    setMarchSpeed(value) {
        this.wave.marchSpeed = parseInt(value);
        this._notify('settingsChanged', {});
    }

    setPaletteColor(alienType, colorIndex) {
        this.wave.palette[alienType] = colorIndex;
        this._notify('paletteChanged', { alienType, colorIndex });
    }

    setReinforcement(value) {
        this.wave.reinforcement = value;
        this._notify('settingsChanged', {});
    }

    setActiveTool(tool) {
        this.activeTool = tool;
        this._notify('toolChanged', { tool });
    }

    // ── Serialization ──

    toJSON() {
        return JSON.stringify(this.waves, null, 2);
    }

    fromJSON(json) {
        try {
            this.waves = JSON.parse(json);
            this._notify('fullReload', {});
            return true;
        } catch (e) {
            console.error('Invalid JSON:', e);
            return false;
        }
    }

    // ── Stats ──

    getAliveCount() {
        let count = 0;
        for (let r = 0; r < GRID_ROWS; r++) {
            let bits = this.wave.patternB.rows[r];
            while (bits) { count += bits & 1; bits >>= 1; }
        }
        return count;
    }
}

export const state = new WaveDesignerState();
