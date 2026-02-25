#!/usr/bin/env python3
"""Parse Maple Leaf Rag MIDI and extract A strain melody for IntyBASIC."""

import struct
import sys

def read_varlen(data, offset):
    """Read MIDI variable-length quantity."""
    value = 0
    while True:
        byte = data[offset]
        offset += 1
        value = (value << 7) | (byte & 0x7F)
        if not (byte & 0x80):
            break
    return value, offset

def parse_midi(filepath):
    """Parse MIDI file and return tracks with events."""
    with open(filepath, 'rb') as f:
        data = f.read()

    # Header
    assert data[0:4] == b'MThd'
    header_len = struct.unpack('>I', data[4:8])[0]
    fmt, ntracks, ticks_per_beat = struct.unpack('>HHH', data[8:14])
    print(f"Format: {fmt}, Tracks: {ntracks}, Ticks/beat: {ticks_per_beat}")

    offset = 8 + header_len
    tracks = []

    for t in range(ntracks):
        assert data[offset:offset+4] == b'MTrk', f"Expected MTrk at {offset}"
        track_len = struct.unpack('>I', data[offset+4:offset+8])[0]
        track_data = data[offset+8:offset+8+track_len]
        offset += 8 + track_len

        events = []
        pos = 0
        abs_tick = 0
        running_status = 0

        while pos < len(track_data):
            delta, pos = read_varlen(track_data, pos)
            abs_tick += delta

            byte = track_data[pos]

            if byte == 0xFF:  # Meta event
                pos += 1
                meta_type = track_data[pos]
                pos += 1
                meta_len, pos = read_varlen(track_data, pos)
                meta_data = track_data[pos:pos+meta_len]
                pos += meta_len

                if meta_type == 0x51:  # Tempo
                    tempo = (meta_data[0] << 16) | (meta_data[1] << 8) | meta_data[2]
                    bpm = 60000000 / tempo
                    events.append(('tempo', abs_tick, tempo, bpm))
                elif meta_type == 0x58:  # Time signature
                    num = meta_data[0]
                    den = 2 ** meta_data[1]
                    events.append(('timesig', abs_tick, num, den))
                elif meta_type == 0x03:  # Track name
                    events.append(('name', abs_tick, meta_data.decode('ascii', errors='replace')))
                elif meta_type == 0x2F:  # End of track
                    events.append(('end', abs_tick))
                    break
            elif byte >= 0x80:
                running_status = byte
                pos += 1

                status = running_status & 0xF0
                channel = running_status & 0x0F

                if status == 0x90:  # Note On
                    note = track_data[pos]; pos += 1
                    vel = track_data[pos]; pos += 1
                    if vel > 0:
                        events.append(('note_on', abs_tick, channel, note, vel))
                    else:
                        events.append(('note_off', abs_tick, channel, note, 0))
                elif status == 0x80:  # Note Off
                    note = track_data[pos]; pos += 1
                    vel = track_data[pos]; pos += 1
                    events.append(('note_off', abs_tick, channel, note, vel))
                elif status == 0xB0:  # Control Change
                    cc = track_data[pos]; pos += 1
                    val = track_data[pos]; pos += 1
                elif status == 0xC0:  # Program Change
                    prog = track_data[pos]; pos += 1
                elif status == 0xE0:  # Pitch Bend
                    lsb = track_data[pos]; pos += 1
                    msb = track_data[pos]; pos += 1
                else:
                    # Unknown, try to skip
                    if status in (0xD0, 0xC0):
                        pos += 1
                    else:
                        pos += 2
            else:
                # Running status
                status = running_status & 0xF0
                channel = running_status & 0x0F

                if status == 0x90:
                    note = byte; pos += 1
                    vel = track_data[pos]; pos += 1
                    if vel > 0:
                        events.append(('note_on', abs_tick, channel, note, vel))
                    else:
                        events.append(('note_off', abs_tick, channel, note, 0))
                elif status == 0x80:
                    note = byte; pos += 1
                    vel = track_data[pos]; pos += 1
                    events.append(('note_off', abs_tick, channel, note, vel))
                elif status == 0xB0:
                    cc = byte; pos += 1
                    val = track_data[pos]; pos += 1
                elif status == 0xC0:
                    prog = byte; pos += 1
                elif status == 0xE0:
                    lsb = byte; pos += 1
                    msb = track_data[pos]; pos += 1
                else:
                    pos += 1

        tracks.append(events)

    return ticks_per_beat, tracks


def midi_note_name(n):
    """Convert MIDI note number to name."""
    names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
    octave = (n // 12) - 1
    return f"{names[n % 12]}{octave}"


def psg_period(midi_note):
    """Convert MIDI note to Intellivision PSG period.
    PSG clock = 3579545 Hz (NTSC), divider = 16
    Period = 3579545 / (16 * freq)
    """
    freq = 440.0 * (2 ** ((midi_note - 69) / 12.0))
    period = int(round(3579545.0 / (16.0 * freq)))
    return period


if __name__ == '__main__':
    filepath = sys.argv[1] if len(sys.argv) > 1 else \
        '/Users/developer/src/intybasic-workbench/games/downbeat/downbeat_v2/Maple Leaf Rag.mid'

    tpb, tracks = parse_midi(filepath)

    print(f"\n=== MIDI Structure ===")
    print(f"Ticks per beat: {tpb}")

    for i, track in enumerate(tracks):
        print(f"\n--- Track {i} ---")
        for ev in track:
            if ev[0] in ('tempo', 'timesig', 'name'):
                print(f"  {ev}")

    # Find the track with note data (track 1 for format 1)
    note_track = None
    for i, track in enumerate(tracks):
        note_count = sum(1 for ev in track if ev[0] == 'note_on')
        print(f"Track {i}: {note_count} note-on events")
        if note_count > 0 and note_track is None:
            note_track = i

    if note_track is None:
        print("No note data found!")
        sys.exit(1)

    # Extract note-on events from the note track
    notes = [(ev[1], ev[3], ev[4]) for ev in tracks[note_track] if ev[0] == 'note_on']

    # Get tempo events from track 0
    tempos = [(ev[1], ev[2], ev[3]) for ev in tracks[0] if ev[0] == 'tempo']
    timesigs = [(ev[1], ev[2], ev[3]) for ev in tracks[0] if ev[0] == 'timesig']

    print(f"\n=== Tempo Changes ===")
    for tick, us, bpm in tempos:
        beat = tick / tpb
        print(f"  Tick {tick:6d} (beat {beat:6.1f}): {bpm:.1f} BPM ({us} us/beat)")

    print(f"\n=== Time Signature Changes ===")
    for tick, num, den in timesigs:
        beat = tick / tpb
        print(f"  Tick {tick:6d} (beat {beat:6.1f}): {num}/{den}")

    # Group notes by tick (chord = simultaneous notes)
    from collections import defaultdict
    tick_notes = defaultdict(list)
    for tick, note, vel in notes:
        tick_notes[tick].append((note, vel))

    sorted_ticks = sorted(tick_notes.keys())

    print(f"\n=== First 128 note events (by tick) ===")
    print(f"{'Tick':>8} {'Beat':>8} {'Measure':>8} | Notes")
    print("-" * 80)

    # Determine time signature for measure calculation
    # Initial time sig from track data
    current_num = 2  # default
    current_den = 4
    for tick, num, den in timesigs:
        if tick == 0:
            current_num = num
            current_den = den

    beats_per_measure = current_num  # For 2/4 time
    ticks_per_measure = tpb * beats_per_measure

    print(f"Time signature: {current_num}/{current_den}")
    print(f"Ticks per measure: {ticks_per_measure}")

    for i, tick in enumerate(sorted_ticks[:128]):
        beat = tick / tpb
        measure = tick / ticks_per_measure + 1
        beat_in_measure = (tick % ticks_per_measure) / tpb + 1

        chord = tick_notes[tick]
        highest = max(chord, key=lambda x: x[0])
        note_names = ', '.join(f"{midi_note_name(n)}(v{v})" for n, v in sorted(chord, key=lambda x: -x[0]))

        # Mark the highest note (melody)
        print(f"{tick:8d} {beat:8.2f} {measure:5.1f}:{beat_in_measure:.2f} | {note_names}")

        if i >= 127:
            break

    # Extract melody line (highest note at each tick position)
    print(f"\n=== MELODY EXTRACTION (highest note per tick) ===")
    print(f"Focusing on first 16 measures (A strain)")

    a_strain_end = ticks_per_measure * 18  # Extra measures for safety

    melody_notes = []
    for tick in sorted_ticks:
        if tick >= a_strain_end:
            break
        chord = tick_notes[tick]
        highest_note = max(chord, key=lambda x: x[0])[0]
        melody_notes.append((tick, highest_note))

    print(f"\nMelody notes in A strain ({len(melody_notes)} events):")
    print(f"{'#':>3} {'Tick':>6} {'Beat':>6} {'Meas':>6} {'Note':>5} {'PSG':>5}")
    for i, (tick, note) in enumerate(melody_notes):
        beat = tick / tpb
        measure = tick / ticks_per_measure + 1
        beat_in_measure = (tick % ticks_per_measure) / tpb + 1
        period = psg_period(note)
        print(f"{i:3d} {tick:6d} {beat:6.2f} {measure:4.0f}:{beat_in_measure:.2f} {midi_note_name(note):>5} {period:5d}")

    # Now quantize to 16th note grid for the obstacle system
    print(f"\n=== QUANTIZED TO 16TH NOTE GRID ===")
    ticks_per_16th = tpb // 4  # For 2/4 time, each beat has 4 16th notes
    print(f"Ticks per 16th note: {ticks_per_16th}")

    # Quantize each note to nearest 16th
    quantized = []
    for tick, note in melody_notes:
        q_pos = round(tick / ticks_per_16th)
        quantized.append((q_pos, tick, note))

    # Group by quantized position (take highest if multiple)
    q_notes = defaultdict(list)
    for q_pos, tick, note in quantized:
        q_notes[q_pos].append(note)

    print(f"\nQuantized melody ({len(q_notes)} positions):")
    print(f"{'Pos':>4} {'Beat':>6} {'Meas':>8} {'Note':>5} {'PSG':>5}")
    for q_pos in sorted(q_notes.keys()):
        highest = max(q_notes[q_pos])
        beat = q_pos / 4.0
        beats_per_measure = current_num
        sixteenths_per_measure = beats_per_measure * 4
        measure = q_pos // sixteenths_per_measure + 1
        pos_in_measure = q_pos % sixteenths_per_measure + 1
        period = psg_period(highest)
        print(f"{q_pos:4d} {beat:6.2f} {measure:4d}:{pos_in_measure:2d}/8  {midi_note_name(highest):>5} {period:5d}")

    # Generate IntyBASIC DATA statements
    print(f"\n=== INTYBASIC DATA OUTPUT ===")
    print(f"' PSG Period = 3579545 / (16 * freq)")
    print(f"' REST = 0 (no note)")

    # Fill out a complete grid for the A strain
    # 16 measures × 8 sixteenth-notes per measure (2/4 time) = 128 positions
    sixteenths_per_measure = current_num * 4
    total_positions = 16 * sixteenths_per_measure

    print(f"\n' Total grid: {total_positions} sixteenth-note positions")
    print(f"' {sixteenths_per_measure} positions per measure")

    grid = [0] * total_positions  # 0 = rest
    for q_pos in sorted(q_notes.keys()):
        if q_pos < total_positions:
            highest = max(q_notes[q_pos])
            grid[q_pos] = psg_period(highest)

    print(f"\nMelodyPSG:")
    for m in range(16):
        start = m * sixteenths_per_measure
        end = start + sixteenths_per_measure
        values = grid[start:end]
        line = ', '.join(f"{v:4d}" for v in values)
        print(f"    DATA {line}  ' Measure {m+1}")

    # Also output MIDI note numbers for reference
    print(f"\nMelodyMIDI:")
    grid_midi = [255] * total_positions  # 255 = rest
    for q_pos in sorted(q_notes.keys()):
        if q_pos < total_positions:
            highest = max(q_notes[q_pos])
            grid_midi[q_pos] = highest

    for m in range(16):
        start = m * sixteenths_per_measure
        end = start + sixteenths_per_measure
        values = grid_midi[start:end]
        names = []
        for v in values:
            if v == 255:
                names.append("---")
            else:
                names.append(f"{midi_note_name(v):>3}")
        line = ', '.join(f"{v:3d}" for v in values)
        name_line = '  '.join(names)
        print(f"    DATA {line}  ' M{m+1}: {name_line}")
