# DOWNBEAT! Game Design - Continuation Prompt

Use this prompt to resume the DOWNBEAT! game design conversation with Claude.

---

## Context Prompt

```
I'm designing an Intellivision game called DOWNBEAT!. We've already worked out most of the core mechanics and I have a complete design document. I need your help continuing the design work.

Here's what we've established so far:

GAME OVERVIEW:
- 2-player competitive rhythm game for Intellivision with Intellivoice module
- Players alternate between building melodies (hitting rhythm) and sabotaging opponent
- Turn-based: Player A builds while Player B sabotages, then swap
- Best of 3 rounds (Best of 5 as option), 45 seconds per turn
- 9 buttons: 8 instruments (Piccolo, Trumpet, Violin, Oboe, Viola, Trombone, Bassoon, Timpani) + REST

TURN STRUCTURE:
- 45 seconds per building phase (~90 beats at 120 BPM)
- Only ends early if sync meter depletes (loses phrase, 2-sec daze, meter resets to 50%, continues)
- No voluntary quit or early perfect completion
- Round tie-breaker: instrument variety → perfect streak → fewest misses
- Between rounds: ~10-12 sec (scores, banked reflections shown, countdown)
- Match win: first to 2 rounds (or 3 in Best of 5)

SCORING SYSTEM:
- Per-note: Perfect (10pts) / Good (5pts) / Miss (0pts + sync meter penalty)
- Phrase bonuses: 3-note (+20) / 4-note (+30) / 5-note (+50) / 6+ note (+75)
- Variety multiplier: 3-4 instruments (1.1x) / 5-6 (1.25x) / 7-8 (1.5x) / All 8 non-rest (3x)
- Perfect streaks: 5 (+50) / 8 (+100 + maestro) / 10 (+200) / 15 (+500)
- Sync meter: Perfect (+10%), Good (+5%), Miss (-15%); empty = phrase lost, reset to 50%

PRE-GAME TEMPO SELECTION:
- Pie wedge arc design: 3 wedges (Adagio 80 BPM left, Moderato 120 BPM center larger, Allegro 160 BPM right)
- Unselected = Gray, selected fills with color (Adagio Green, Moderato Orange, Allegro Red)
- Default: Moderato selected (Orange)
- Rotate disc to select, press any button to start
- Screen shows: "DOWNBEAT!" title (SF Intellivised), "TEMPO SELECTION", pie wedges, "◄ Rotate disc to select tempo ►", "Press any button to start", "© Shaya Bendix Lyon"

INSTRUMENTS:
- 8 instruments + REST button (position #9, bottom-right)
- Final lineup: Piccolo, Trumpet, Violin, Oboe, Viola, Trombone, Bassoon, Timpani, REST
- REST: scores like other notes, maintains combos, doesn't count for variety
- Layout: 3x3 grid (Piccolo, Trumpet, Violin / Oboe, Viola, Trombone / Bassoon, Timpani, REST)
- Each instrument has unique color for visual ID (see design doc for full list)

VISUAL DESIGN:
- Intellivision 16-color palette: Red (P1), Purple (P2), Orange (metronome/accent), Pink (UI), Black (background), White (text), Gray (used/disabled)
- Instrument colors: Piccolo (Cyan), Trumpet (Yellow), Violin (Light Blue), Oboe (Orange), Viola (Pink), Trombone (Yellow-Green), Bassoon (Dark Green), Timpani (Red), Rest (Gray)
- Asymmetric layout: Builder 70% screen, saboteur 20%
- Melody line: Snaking pattern (L→R, R→L alternating 6 rows), progressive building as notes hit, Orange pulse [●] = next beat = metronome
- Active phrase = colorful instrument icons, broken phrase = Gray icons (keep shape)
- Top bar (Black): Shows "MODERATO 🎩🎩 ⚡ P1: BUILDER 450" (tempo, power icons, role, score)
- Power icons: White top hat w/black details (baton, 2-3 uses), Orange lightning (partner, 1 use), Gray when used
- Sync meter: White blocks (full) / Gray blocks (empty), pulses when critical (<20%)
- Saboteur bar (bottom): Shows "PLAYER 2: 320 │ 💥•• (5s) 📝•• 🗣••" (score, sabotage uses with cooldowns)
- Sabotage effects: SNEEZE (5-6px screen shake, 1 sec, "ACHOO!"), DROP PENCIL (single yellow pencil w/pink eraser, angled bouncing physics 70%→40%→20%, 4-6 beats, clatter sound), COUNT OUT LOUD (audio only, voice counts wrong tempo)
- Instrument icons: Try visual icons first, fallback to 2-letter codes (Pi, Tr, Vn, Ob, Va, Tb, Bs, Ti, R)
- Each instrument has unique color, active=full color, broken=Gray

BRANDING:
- Game title: DOWNBEAT! (with exclamation)
- Title font: SF Intellivised
- In-game text font: Press Start 2P (authentic 1980s retro gaming aesthetic)
- Copyright: Shaya Bendix Lyon

BETWEEN-TURN/ROUND SCREENS:
1. Turn Completion: Shows "PLAYER 1 / 450 POINTS! / BEST BEAT STREAK: 15 / INSTRUMENTS: 6/8" (player color, points in Orange, stats White, 8/8 highlighted Orange)
2. Player Announcement: Shows "ROUND 2 / PLAYER TWO / BUILDER / Press any button for downbeat" (waits for input, voice says player name)
3. Countdown: 4...3...2...1 overlaid on game screen (Orange numbers, no background, tempo-matched, voice counts + tick, sync meter hidden until start)
4. Round Comparison (after both turns): Shows "ROUND 1 COMPLETE / PLAYER 1 450 POINTS PLAYER 2 520 POINTS / PLAYER 2 WINS ROUND! / MATCH SCORE: P1: 0 P2: 1" (winner text in their color, voice says "BRAVO!" or applause)
5. Match Winner (final): Shows "★★★★★★★★★★★★★★★ / REHEARSAL COMPLETE / PLAYER 2 WINS! / 2 - 1 / ★★★★★★★★★★★★★★★ / Press any button to play again" (stars Orange, winner color, voice announces winner + fanfare)
- Banked reflections shown as extra dots in saboteur bar (no separate screen)
- Round 3: PARTNER disabled (no Round 4 to use reflections)

CORE MECHANICS:
- Builder presses instrument buttons in time with visual metronome
- 3+ consecutive successful notes creates a "phrase" that plays back
- Missing beats causes notes to drop from melody
- Sync meter tracks rhythm accuracy

HELPER POWERS (Builder has):
1. METRONOME (unlimited): Makes metronome more visible/obvious for several beats
2. GLANCE AT MAESTRO (2 per turn, earn 3rd): 3-4 beats of auto-pilot (perfect timing + sabotage immunity). Earn 3rd use by hitting 8-10 consecutive beats perfectly.
3. GLANCE AT PARTNER (1 per turn): Preemptive reflection trap - press it any time, next sabotage is blocked and banked for revenge next round

SABOTAGE POWERS (Saboteur has 2-3 of each with cooldowns):
1. SNEEZE: Screen shake + "ACHOO!" voice, instant disruption
2. DROP PENCIL: Pencils bounce across screen + clatter sound, 4-6 beats of visual obstruction
3. COUNT OUT LOUD: Voice counts "ONE TWO THREE FOUR" in wrong tempo, 3-5 beats of cognitive confusion
4. CHANGE TEMPO: Instantly speeds up or slows down metronome (double-edged)

AUDIO:
- Intellivoice for: game start orchestra tuning, "ACHOO!", counting, "REFLECTED!", "MAESTRO!", "PLAYER ONE/TWO", "BRAVO!" or applause (randomized)
- 9 distinct instrument sounds
- Metronome audible pulse

KEY DESIGN DECISIONS WE MADE:
- Turn-based to prevent audio chaos of two melodies at once
- Sabotage is instant (no wind-up/countdown) with cooldowns
- Single shared screen (not split-screen)
- Eyes stay on screen, not controller
- Reflection is preemptive trap (not reactive) because reactive would be impossible during rhythm gameplay
- Starting power economy balanced for accessibility with skill expression

WHAT WE STILL NEED TO DESIGN:
- Tempo arc visual design (pre-game selection screen)
- Between-round screens (score comparison, banked reflections, countdown)
- Specific instrument sounds (what each sounds like on Intellivision chip)
- Font selection for in-game text

[Insert specific topic you want to continue with]

Please help me continue designing this game. Refer to the established mechanics above and maintain consistency with what we've already decided.
```

---

## Quick Reference - Established Design

### Power Economy (Each Turn)
- ∞ METRONOME
- 2 GLANCE AT MAESTRO (earn 3rd via streak)
- 1 GLANCE AT PARTNER
- 2-3 each sabotage (with cooldowns)
- Plus banked reflections from previous round

### Round Structure
1. Player A builds (45 sec) / Player B sabotages
2. Score Player A
3. Player B builds (45 sec) / Player A sabotages
4. Score Player B
5. Declare round winner
6. Best of 3 rounds

### Design Philosophy
- Accessible but skill-rewarding
- Strategic resource management
- Turn-based prevents chaos
- Eyes on screen (not controller)
- Authentic Intellivision limitations

---

## Topics Still To Design

Use these as starting points for continuing the conversation:

### 1. Between-Round Screens
```
We need to design the screens shown between rounds:
- Score comparison display
- Banked reflections visualization  
- Countdown sequence
- Match winner screen
```

### 2. Instrument Sounds
```
We need to define what each instrument sounds like on Intellivision sound chip:
- How to make 8 instruments + REST recognizably different
- What timbres/waveforms to use for each
```

---

## How to Use This File

1. Copy the "Context Prompt" section
2. Add the specific topic you want to continue (from Topics Still To Design)
3. Paste into a new Claude conversation
4. Claude will have full context and can continue designing with you

Example:
```
[Paste Context Prompt]

WHAT WE STILL NEED TO DESIGN:
The detailed scoring system - how points are awarded, penalties, bonuses, etc.

Let's work on this together!
```