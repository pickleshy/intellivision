#!/usr/bin/env python3
"""
Extract melody from MIDI file and convert to IntyBASIC PSG period DATA statements.

Approach: "highest note per tick" — for each 16th-note position in a 128-position
grid, find the highest MIDI note that is sounding and convert to AY-3-8914 PSG period.

PSG period formula (NTSC): Period = 3579545 / (16 * frequency_hz)
MIDI note to frequency: freq = 440 * 2^((note - 69) / 12)

Output: 128 DATA values formatted as IntyBASIC DATA statements.
"""

import struct
import sys
from collections import defaultdict

MIDI_FILE = "/Users/developer/src/intybasic-workbench/games/downbeat-v2/assets/stage2_b_to_a_final.mid"
GRID_SIZE = 128  # 16 bars × 8 sixteenths per bar (2/4 time)
PSG_CLOCK = 3579545  # NTSC master clock
PSG_DIVISOR = 16


def read_vlq(data, pos):
    """Read a MIDI variable-length quantity."""
    val = 0
    while True:
        b = data[pos]
        val = (val << 7) | (b & 0x7F)
        pos += 1
        if not (b & 0x80):
            break
    return val, pos


def midi_note_to_name(note):
    """Convert MIDI note number to name string."""
    names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
    octave = (note // 12) - 1
    return f"{names[note % 12]}{octave}"


def midi_note_to_psg_period(note):
    """Convert MIDI note number to AY-3-8914 PSG period value (NTSC)."""
    freq = 440.0 * (2.0 ** ((note - 69) / 12.0))
    period = round(PSG_CLOCK / (PSG_DIVISOR * freq))
    # PSG period registers are 12-bit (max 4095)
    if period > 4095:
        # Shift up an octave
        period = round(period / 2)
    return period


def parse_midi(filepath):
    """Parse MIDI file and return (ppqn, tempo_us, events list)."""
    data = open(filepath, 'rb').read()

    # Validate header
    if data[0:4] != b'MThd':
        raise ValueError("Not a MIDI file")

    ppqn = struct.unpack('>H', data[12:14])[0]

    # Parse the track data (starts after header 14 bytes + MTrk header 8 bytes)
    pos = 22
    track_end = len(data)

    events = []
    tempo = 600000  # default 100 BPM
    running_status = 0
    abs_tick = 0

    while pos < track_end:
        delta, pos = read_vlq(data, pos)
        abs_tick += delta

        byte = data[pos]

        if byte == 0xFF:  # Meta event
            pos += 1
            meta_type = data[pos]
            pos += 1
            length, pos = read_vlq(data, pos)
            meta_data = data[pos:pos + length]
            pos += length

            if meta_type == 0x51:  # Tempo
                tempo = (meta_data[0] << 16) | (meta_data[1] << 8) | meta_data[2]
            elif meta_type == 0x2F:  # End of track
                break

        elif byte == 0xF0 or byte == 0xF7:  # Sysex
            pos += 1
            length, pos = read_vlq(data, pos)
            pos += length

        else:
            # MIDI channel message
            if byte & 0x80:
                status = byte
                pos += 1
            else:
                status = running_status

            running_status = status
            msg_type = status & 0xF0

            if msg_type == 0x90 or msg_type == 0x80:  # Note On/Off
                note = data[pos]; pos += 1
                vel = data[pos]; pos += 1
                if msg_type == 0x90 and vel > 0:
                    events.append(('on', abs_tick, note, vel))
                else:
                    events.append(('off', abs_tick, note, 0))
            elif msg_type in (0xA0, 0xB0, 0xE0):
                pos += 2  # 2 data bytes
            elif msg_type in (0xC0, 0xD0):
                pos += 1  # 1 data byte

    return ppqn, tempo, events


def extract_melody(ppqn, events, grid_size=128, method='highest'):
    """
    Extract melody from MIDI events using the specified method.

    Methods:
      'highest' — highest note per tick (works when melody is on top)
      'newest'  — most recently attacked note per tick (works when melody
                   moves while chord tones sustain)

    Returns list of grid_size MIDI note numbers (0 = rest).
    """
    ticks_per_16th = ppqn // 4  # At 256 ppqn, this is 64

    # Sort events: at same tick, process note-offs before note-ons
    # This ensures a note that ends and a new one starts at the same tick
    # are handled correctly
    sorted_events = sorted(events, key=lambda e: (e[1], 0 if e[0] == 'off' else 1))

    # Detect notes sustaining from before tick 0:
    # Any note-off that occurs before any note-on for that pitch
    # means the note was already active at tick 0
    first_on_tick = {}
    first_off_tick = {}
    for e in sorted_events:
        note = e[2]
        if e[0] == 'on' and note not in first_on_tick:
            first_on_tick[note] = e[1]
        elif e[0] == 'off' and note not in first_off_tick:
            first_off_tick[note] = e[1]

    # Notes where first event is off (no preceding on in this file)
    # were sustaining from the previous section
    pre_existing = set()
    for note, off_tick in first_off_tick.items():
        if note not in first_on_tick or first_on_tick[note] > off_tick:
            pre_existing.add(note)

    # Initialize active notes with pre-existing ones
    active_notes = set(pre_existing)

    # Walk through grid positions
    results = [0] * grid_size
    event_idx = 0
    prev_tick = -1
    last_melody = 0  # for 'newest' method: sustain previous melody

    for grid_pos in range(grid_size):
        tick = grid_pos * ticks_per_16th

        # Track which notes had onsets since last grid position
        new_onsets = set()

        # Process all events up to and including this tick
        while event_idx < len(sorted_events) and sorted_events[event_idx][1] <= tick:
            e = sorted_events[event_idx]
            if e[0] == 'on':
                active_notes.add(e[2])
                if e[1] > prev_tick:  # onset since last grid tick
                    new_onsets.add(e[2])
            elif e[0] == 'off':
                active_notes.discard(e[2])
                new_onsets.discard(e[2])
            event_idx += 1

        if method == 'newest':
            if new_onsets:
                # Pick highest of the newly attacked notes
                last_melody = max(new_onsets)
                results[grid_pos] = last_melody
            elif last_melody in active_notes:
                # Sustain previous melody note if still sounding
                results[grid_pos] = last_melody
            elif active_notes:
                # Melody note ended, fall back to highest active
                last_melody = max(active_notes)
                results[grid_pos] = last_melody
            # else: rest (0)
        else:  # 'highest'
            if active_notes:
                results[grid_pos] = max(active_notes)

        prev_tick = tick

    return results


def format_output(melody_notes):
    """Format as IntyBASIC DATA statements with PSG periods."""
    print("' Stage 2 B-to-A melody - PSG periods (NTSC)")
    print("' Extracted from stage2_b_to_a_final.mid")
    print("' 128 positions = 16 bars × 8 sixteenths (2/4 time, 100 BPM)")
    print("' 0 = rest (silence channel)")
    print("'")
    print("Stage2MelodyPSG:")

    for i in range(0, GRID_SIZE, 4):
        values = []
        comments = []
        for j in range(4):
            idx = i + j
            if idx < len(melody_notes):
                note = melody_notes[idx]
                if note == 0:
                    values.append("0")
                    comments.append("---")
                else:
                    period = midi_note_to_psg_period(note)
                    values.append(str(period))
                    comments.append(midi_note_to_name(note))

        # Calculate measure and beat info
        bar = (i // 8) + 1
        beat_in_bar = (i % 8) // 4 + 1
        measure_str = f"M{bar:02d}"
        if beat_in_bar == 1:
            measure_str += " beat 1"
        else:
            measure_str += " beat 2"

        data_line = "    DATA " + ",".join(values)
        comment = f"  ' {measure_str}: {' '.join(comments)}"
        print(data_line + comment)

    print()
    print("' --- PSG Period Reference ---")
    print("' Note   MIDI  Period")
    # Print unique notes used
    used_notes = sorted(set(n for n in melody_notes if n > 0))
    for note in used_notes:
        period = midi_note_to_psg_period(note)
        print(f"' {midi_note_to_name(note):5s}  {note:3d}   {period}")


def main():
    # Parse args: [--newest] [midi_file]
    method = 'highest'
    filepath = MIDI_FILE
    for arg in sys.argv[1:]:
        if arg == '--newest':
            method = 'newest'
        else:
            filepath = arg

    ppqn, tempo, events = parse_midi(filepath)

    bpm = 60000000 / tempo
    print(f"' MIDI: PPQN={ppqn}, Tempo={tempo}us/beat ({bpm:.1f} BPM)")
    print(f"' Ticks per 16th note: {ppqn // 4}")
    print(f"' Total note events: {len(events)}")
    print(f"' Method: {method}")
    print()

    melody_notes = extract_melody(ppqn, events, GRID_SIZE, method=method)
    format_output(melody_notes)


if __name__ == '__main__':
    main()
