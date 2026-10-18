#!/usr/bin/env python3
"""Synthesize the two completion chimes into assets/audio/.

Bundling generated tones keeps the app self-contained: no third-party audio
files, no licensing question, and the timbre stays tunable from here.
Run from the project root:  python3 tool/generate_chimes.py
"""
import math
import struct
import wave

RATE = 44100


def bell(freq, dur, amp=1.0, decay=3.2):
    """One bell-ish voice: a few harmonics under a fast-attack, exponential decay."""
    n = int(RATE * dur)
    # Slightly inharmonic partials read as "struck metal" rather than "sine beep".
    partials = [(1.0, 1.0), (2.01, 0.42), (3.02, 0.19), (4.97, 0.08)]
    out = [0.0] * n
    attack = int(RATE * 0.006)
    for mult, pamp in partials:
        w = 2 * math.pi * freq * mult
        # Higher partials fade faster, as they do on a real bell.
        d = decay * (1.0 + (mult - 1.0) * 0.55)
        for i in range(n):
            t = i / RATE
            env = math.exp(-d * t)
            if i < attack:
                env *= i / attack
            out[i] += pamp * env * math.sin(w * t)
    return [v * amp for v in out]


def mix(voices, dur):
    """Overlay (freq, delay, amp, decay) voices onto one buffer."""
    buf = [0.0] * int(RATE * dur)
    for freq, delay, amp, decay in voices:
        off = int(RATE * delay)
        v = bell(freq, dur - delay, amp=amp, decay=decay)
        for i, s in enumerate(v):
            if off + i < len(buf):
                buf[off + i] += s
    return buf


def write(path, buf):
    peak = max(abs(v) for v in buf) or 1.0
    # Normalize to -1.5 dBFS, then a short fade-out so nothing clicks at the tail.
    gain = 0.84 / peak
    fade = int(RATE * 0.05)
    n = len(buf)
    frames = bytearray()
    for i, v in enumerate(buf):
        s = v * gain
        if i > n - fade:
            s *= (n - i) / fade
        frames += struct.pack('<h', int(max(-1.0, min(1.0, s)) * 32767))
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(bytes(frames))
    print(f'{path}  {n / RATE:.2f}s  {len(frames) + 44} bytes')


# Focus done -> you earned the break. Warm major triad, unhurried.
write('assets/audio/focus_complete.wav', mix([
    (523.25, 0.00, 1.00, 2.6),   # C5
    (659.25, 0.08, 0.80, 2.8),   # E5
    (783.99, 0.16, 0.66, 3.0),   # G5
    (1046.50, 0.24, 0.34, 3.4),  # C6
], 2.0))

# Break over -> back to it. Brighter, quicker, rising fifth.
write('assets/audio/break_complete.wav', mix([
    (783.99, 0.00, 0.90, 4.4),   # G5
    (1174.66, 0.11, 0.85, 4.0),  # D6
], 1.3))
