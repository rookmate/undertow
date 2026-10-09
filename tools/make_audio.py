#!/usr/bin/env python3
"""Builds Undertow's placeholder sound effects and ambience loops from formulas (no recordings, nothing
to license). Deterministic: the same script always writes the same sounds.

    python3 -I tools/make_audio.py            # writes assets/audio/*.ogg (needs ffmpeg)

Each sound is synthesized here as samples, written to a temporary WAV and encoded to Ogg Vorbis. To change
a sound, change its recipe below and run the script again; the .ogg files are committed.
"""
import math
import os
import random
import struct
import subprocess
import sys
import tempfile
import wave

RATE = 44100
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "audio")


# --- Building blocks ---------------------------------------------------------------------------------
def n_of(seconds):
    return int(seconds * RATE)


def silence(seconds):
    return [0.0] * n_of(seconds)


def white(seconds, rng):
    return [rng.uniform(-1.0, 1.0) for _ in range(n_of(seconds))]


def brown(seconds, rng):
    out, v = [], 0.0
    for _ in range(n_of(seconds)):
        v = (v + rng.uniform(-1.0, 1.0) * 0.02) * 0.998
        out.append(v * 8.0)
    return out


def pink(seconds, rng):
    # Paul Kellet's economy pink filter over white noise.
    b0 = b1 = b2 = 0.0
    out = []
    for _ in range(n_of(seconds)):
        w = rng.uniform(-1.0, 1.0)
        b0 = 0.99765 * b0 + w * 0.0990460
        b1 = 0.96300 * b1 + w * 0.2965164
        b2 = 0.57000 * b2 + w * 1.0526913
        out.append((b0 + b1 + b2 + w * 0.1848) * 0.25)
    return out


def tone(seconds, freq, shape="sine", phase=0.0):
    """`freq` is a number or a function of time (s) -> Hz."""
    out, ph = [], phase
    f = freq if callable(freq) else (lambda _t, c=freq: c)
    for i in range(n_of(seconds)):
        t = i / RATE
        ph += 2.0 * math.pi * f(t) / RATE
        s = math.sin(ph)
        if shape == "square":
            s = 1.0 if s >= 0 else -1.0
        elif shape == "saw":
            s = ((ph / math.pi) % 2.0) - 1.0
        elif shape == "tri":
            s = 2.0 * abs(((ph / math.pi) % 2.0) - 1.0) - 1.0
        out.append(s)
    return out


def lowpass(x, fc):
    a = math.exp(-2.0 * math.pi * fc / RATE)
    out, y = [], 0.0
    for s in x:
        y = (1 - a) * s + a * y
        out.append(y)
    return out


def highpass(x, fc):
    lp = lowpass(x, fc)
    return [s - l for s, l in zip(x, lp)]


def bandpass(x, fc, q=1.0):
    # RBJ biquad band-pass (constant 0 dB peak gain).
    w0 = 2.0 * math.pi * fc / RATE
    alpha = math.sin(w0) / (2.0 * q)
    b0, b1, b2 = alpha, 0.0, -alpha
    a0, a1, a2 = 1 + alpha, -2 * math.cos(w0), 1 - alpha
    out, x1, x2, y1, y2 = [], 0.0, 0.0, 0.0, 0.0
    for s in x:
        y = (b0 * s + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2) / a0
        x2, x1, y2, y1 = x1, s, y1, y
        out.append(y)
    return out


def env(x, attack=0.005, decay=None, release=None, curve=1.0):
    """Linear attack, then exponential decay (`decay` = time to fall to ~1/e) or a linear release at the end."""
    n = len(x)
    out = []
    for i, s in enumerate(x):
        t = i / RATE
        g = min(1.0, t / attack) if attack > 0 else 1.0
        if decay is not None:
            g *= math.exp(-max(0.0, t - attack) / decay) ** curve
        if release is not None:
            left = (n - i) / RATE
            g *= min(1.0, left / release)
        out.append(s * g)
    return out


def swell(x):
    """sin² over the whole sound: in and out."""
    n = len(x)
    return [s * math.sin(math.pi * i / n) ** 2 for i, s in enumerate(x)]


def mix(*parts):
    """Each part is (samples, gain, start_seconds)."""
    n = max(len(p[0]) + n_of(p[2] if len(p) > 2 else 0.0) for p in parts)
    out = [0.0] * n
    for p in parts:
        samples, gain = p[0], p[1]
        start = n_of(p[2]) if len(p) > 2 else 0
        for i, s in enumerate(samples):
            out[start + i] += s * gain
    return out


def mul(a, b):
    return [x * y for x, y in zip(a, b)]


def normalize(x, peak_db=-1.0):
    top = max(1e-9, max(abs(s) for s in x))
    g = 10 ** (peak_db / 20.0) / top
    return [s * g for s in x]


def loopable(x, seconds, fade=1.0):
    """Crossfades the extra tail into the head so the loop has no seam. `x` must be seconds + fade long."""
    n, f = n_of(seconds), n_of(fade)
    out = x[:n]
    for i in range(f):
        k = i / f
        out[i] = x[n + i] * (1 - k) + out[i] * k
    return out


def write(name, x, peak_db=-1.0):
    x = normalize(x, peak_db)
    os.makedirs(OUT, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        wav = os.path.join(tmp, name + ".wav")
        with wave.open(wav, "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(RATE)
            w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in x))
        dst = os.path.join(OUT, name + ".ogg")
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", wav, "-c:a", "libvorbis", "-q:a", "4",
                        "-map_metadata", "-1", "-fflags", "+bitexact", "-flags:a", "+bitexact", dst], check=True)
    print("  %-22s %5.2f s" % (name, len(x) / RATE))


# --- The sounds ----------------------------------------------------------------------------------------
def build():
    rng = random.Random(1102)

    # Footsteps on wet cobble: a damp click and a low knock, each variant a little different.
    for i, centre in enumerate([900, 1150, 1400, 1700]):
        click = env(bandpass(white(0.09, rng), centre, 1.4), 0.002, 0.018)
        knock = env(tone(0.09, 110 + 12 * i), 0.002, 0.02)
        splash = env(highpass(white(0.12, rng), 3500), 0.01, 0.035)
        write("step_wet_%d" % (i + 1), mix((click, 1.0), (knock, 0.45), (splash, 0.18, 0.01)), -9)
    # Footsteps on dry concrete (the Ark, the stacks): drier and shorter.
    for i, centre in enumerate([1300, 1600, 1900]):
        click = env(bandpass(white(0.06, rng), centre, 2.0), 0.001, 0.012)
        knock = env(tone(0.06, 140 + 15 * i), 0.001, 0.015)
        write("step_dry_%d" % (i + 1), mix((click, 1.0), (knock, 0.35)), -10)

    # Dodge roll: cloth and air, in and out.
    for i, c in enumerate([700, 900]):
        air = swell(bandpass(pink(0.28, rng), c, 0.7))
        write("dodge_%d" % (i + 1), air, -6)

    # Traffic baton: a swish, and a hard knock on metal.
    for i, c in enumerate([1600, 2000]):
        write("baton_swing_%d" % (i + 1), swell(bandpass(white(0.17, rng), c, 1.2)), -8)
    for i in range(2):
        thud = env(tone(0.16, lambda t, i=i: 150 - 260 * t + 20 * i), 0.001, 0.04)
        clank = env(mix((tone(0.16, 1250 + 90 * i), 0.5), (tone(0.16, 1873 + 70 * i), 0.35)), 0.001, 0.03)
        crack = env(highpass(white(0.04, rng), 2500), 0.0005, 0.006)
        write("baton_hit_%d" % (i + 1), mix((thud, 1.0), (clank, 0.4), (crack, 0.7)), -4)

    # Riot drone: a falling electric blip.
    for i in range(2):
        blip = env(tone(0.12, lambda t, i=i: 1500 - 7000 * t + 120 * i, "square"), 0.001, 0.035)
        write("drone_shot_%d" % (i + 1), lowpass(blip, 3500), -9)

    # Defib gauntlet: a crackling discharge over a low buzz; the overload is longer and dirtier.
    buzz = env(lowpass(tone(0.35, 120, "saw"), 900), 0.002, 0.12)
    gate = [1.0 if rng.random() < 0.35 else 0.0 for _ in range(n_of(0.35))]
    crackle = env(mul(highpass(white(0.35, rng), 1800), gate), 0.001, 0.08)
    write("gauntlet_zap", mix((buzz, 0.7), (crackle, 0.8)), -4)
    buzz = env(lowpass(tone(0.7, 90, "saw"), 700), 0.002, 0.3)
    gate = [1.0 if rng.random() < 0.5 else 0.0 for _ in range(n_of(0.7))]
    crackle = env(mul(highpass(white(0.7, rng), 1200), gate), 0.001, 0.25)
    write("gauntlet_overload", mix((buzz, 0.9), (crackle, 1.0)), -3)

    # Machines taking a hit, and dying: inharmonic metal.
    for i, base in enumerate([520, 610]):
        ring = env(mix((tone(0.3, base), 0.6), (tone(0.3, base * 1.53), 0.4), (tone(0.3, base * 2.41), 0.25)), 0.001, 0.07)
        knock = env(highpass(white(0.05, rng), 1500), 0.0005, 0.01)
        write("machine_hit_%d" % (i + 1), mix((ring, 1.0), (knock, 0.6)), -6)
    fall = env(tone(0.7, lambda t: 300 - 280 * t), 0.002, 0.25)
    clank = env(mix((tone(0.7, 340), 0.5), (tone(0.7, 523), 0.35), (tone(0.7, 811), 0.2)), 0.001, 0.18)
    rattle = env(bandpass(white(0.7, rng), 2500, 1.0), 0.01, 0.2)
    write("machine_death", mix((fall, 0.8), (clank, 0.8), (rattle, 0.4)), -3)

    # A machine winding up to strike: a short rising whine (danger, and only danger).
    whine = env(tone(0.4, lambda t: 300 + 1100 * t, "tri"), 0.03, None, 0.05)
    write("windup", lowpass(whine, 2500), -12)

    # A paper bale thrown: a dry rustle.
    write("bale_throw", swell(highpass(white(0.22, rng), 2200)), -10)

    # The Operator hurt: a low, dull hit.
    thud = env(tone(0.3, lambda t: 95 - 60 * t), 0.002, 0.08)
    grit = env(lowpass(white(0.3, rng), 900), 0.002, 0.05)
    write("hurt", mix((thud, 1.0), (grit, 0.6)), -3)

    # The Steward speaks: a warm two-note chime, soft attack.
    chime = mix((env(tone(1.4, 659.25), 0.03, 0.5), 0.6), (env(tone(1.4, 987.77), 0.03, 0.45), 0.35, 0.09),
                (env(tone(1.4, 1318.5), 0.03, 0.35), 0.12, 0.09))
    write("steward_chime", chime, -10)
    # The voice switched off: a falling tone and a click. Switched on: rising, ending in the chime.
    off = mix((env(tone(0.45, lambda t: 880 * (0.25 ** (t / 0.4))), 0.005, None, 0.08), 0.6),
              (env(highpass(white(0.02, rng), 3000), 0.0005, 0.004), 0.8, 0.40))
    write("voice_off", off, -8)
    on = mix((env(tone(0.5, lambda t: 330 * (2.7 ** (t / 0.4))), 0.02, None, 0.1), 0.5),
             (env(tone(1.0, 987.77), 0.02, 0.35), 0.3, 0.38))
    write("voice_on", on, -9)
    # A lamp going out: a fizz and a tick.
    fizz = env(mul(bandpass(white(0.3, rng), 3200, 2.0), [abs(math.sin(i / RATE * 2 * math.pi * 37)) for i in range(n_of(0.3))]), 0.005, 0.1)
    write("lamp_off", mix((fizz, 0.8), (env(highpass(white(0.015, rng), 4000), 0.0005, 0.003), 0.6, 0.25)), -14)
    # The Steward loses the signal: a stuttering tone.
    stutter = [1.0 if math.sin(i / RATE * 2 * math.pi * 23) > -0.2 else 0.0 for i in range(n_of(0.5))]
    write("signal_lost", env(mul(tone(0.5, 659.25), stutter), 0.005, None, 0.15), -14)

    # Interface: a tick on focus, a two-step accept, a falling back.
    write("ui_move", env(tone(0.03, 1500, "tri"), 0.001, 0.008), -18)
    write("ui_accept", mix((env(tone(0.08, 880, "tri"), 0.001, 0.025), 0.6), (env(tone(0.08, 1320, "tri"), 0.001, 0.03), 0.6, 0.04)), -14)
    write("ui_back", mix((env(tone(0.08, 660, "tri"), 0.001, 0.025), 0.6), (env(tone(0.08, 440, "tri"), 0.001, 0.03), 0.6, 0.04)), -15)

    # Finds. A power core: a bright amber arpeggio. A truth core or unindexed paper: glassy and cool.
    notes = [523.25, 659.25, 783.99, 1046.5]
    write("core_take", mix(*[(env(tone(1.2, f), 0.004, 0.35), 0.4, k * 0.07) for k, f in enumerate(notes)]), -9)
    glass = mix((env(tone(1.4, lambda t: 1174.7 * (1 + 0.004 * math.sin(2 * math.pi * 5 * t))), 0.01, 0.5), 0.5),
                (env(tone(1.4, 1568.0), 0.01, 0.4), 0.3, 0.12), (env(tone(1.4, 2349.3), 0.01, 0.3), 0.12, 0.2))
    write("truth_find", glass, -9)
    # Waking one of the Waiting: a breath drawn in.
    write("wake", swell(lowpass(pink(0.9, rng), 700)), -10)
    # The Archive replaying a record: a typewriter tick per line.
    write("record_tick", mix((env(bandpass(white(0.04, rng), 2600, 1.5), 0.0005, 0.006), 1.0),
                             (env(tone(0.04, 180), 0.0005, 0.008), 0.3)), -14)
    # Checkpoint and respawn.
    write("checkpoint", mix((env(tone(0.9, 784.0), 0.01, 0.3), 0.5), (env(tone(0.9, 1174.7), 0.01, 0.25), 0.35, 0.06)), -12)
    write("respawn", env(tone(0.8, lambda t: 260 * (3.0 ** (t / 0.8)), "tri"), 0.2, None, 0.2), -12)
    # A wrought-iron gate swinging shut on its own: a creak, a clang, the latch.
    creak = env(bandpass(mul(white(0.5, rng), tone(0.5, 31.0, "saw")), 900, 3.0), 0.05, None, 0.1)
    clang = env(mix((tone(0.9, 210), 0.6), (tone(0.9, 331), 0.4), (tone(0.9, 517), 0.25)), 0.001, 0.22)
    latch = env(highpass(white(0.03, rng), 2500), 0.0005, 0.005)
    write("gate_shut", mix((creak, 0.5), (clang, 1.0, 0.45), (latch, 0.7, 0.6)), -4)
    # A Lamplighter's beam taking hold: an electric snap and a rising hum that holds.
    snap = env(highpass(white(0.05, rng), 2000), 0.0005, 0.01)
    hold = env(mix((tone(1.2, lambda t: 220 + 60 * min(t, 0.3)), 0.5), (tone(1.2, lambda t: 440 + 120 * min(t, 0.3), "tri"), 0.25)), 0.02, None, 0.3)
    write("lamp_hook", mix((snap, 0.9), (hold, 0.8, 0.03)), -6)
    # A blow off heavy armour: a dull ring, no give.
    ring = env(mix((tone(0.5, 180), 0.5), (tone(0.5, 287), 0.35), (tone(0.5, 461), 0.2)), 0.001, 0.12)
    write("armour_clang", mix((ring, 1.0), (env(highpass(white(0.03, rng), 2500), 0.0005, 0.006), 0.6)), -5)
    # A runaway carriage: wheels on rail joints, a rush of air, rising then gone.
    rush = swell(lowpass(brown(0.9, rng), 700))
    clacks = [0.0] * len(rush)
    for k in range(6):
        at = int((0.08 + k * 0.13) * RATE)
        for i in range(800):
            if at + i < len(clacks):
                clacks[at + i] += math.exp(-i / 120.0) * rng.uniform(-1, 1)
    write("carriage_run", mix((rush, 1.0), (highpass(clacks, 600), 0.8)), -3)
    # Steam out of a vent.
    write("vent_hiss", env(highpass(white(1.2, rng), 3000), 0.04, 0.5), -9)
    # A relay in the signal box snapping over.
    write("signal_zap", mix((env(tone(0.18, 1600, "square"), 0.001, 0.04), 0.4), (env(highpass(white(0.05, rng), 3000), 0.0005, 0.01), 0.8)), -8)

    # --- Ambience loops (seamless) ---
    # Rain on stone: pink noise shaped bright, with a slow wash.
    secs, fade = 12.0, 1.0
    r = highpass(lowpass(pink(secs + fade, rng), 5200), 300)
    wash = [0.85 + 0.15 * math.sin(2 * math.pi * i / RATE / 6.0) for i in range(len(r))]
    drops = [0.0] * len(r)
    for _ in range(int(secs * 30)):
        at = rng.randrange(0, len(r) - 600)
        for k in range(500):
            drops[at + k] += math.exp(-k / 60.0) * rng.uniform(-1, 1) * 0.6
    write("amb_rain", loopable(mix((mul(r, wash), 1.0), (highpass(drops, 2000), 0.5)), secs, fade), -10)
    # The Lattice hum: mains hum in the lamps, only while the Steward is with you. Whole cycles in 8 s.
    secs = 8.0
    hum = mix((tone(secs, 50.0), 0.6), (tone(secs, 100.0), 0.35), (tone(secs, 150.0), 0.15), (tone(secs, 250.0), 0.05))
    wobble = [0.8 + 0.2 * math.sin(2 * math.pi * 0.25 * i / RATE) for i in range(len(hum))]
    write("amb_lattice_hum", mul(hum, wobble), -14)
    # The estuary round the Ark: low wind and water.
    secs = 16.0
    wind = lowpass(brown(secs + fade, rng), 500)
    gust = [0.7 + 0.3 * math.sin(2 * math.pi * i / RATE / 8.0) for i in range(len(wind))]
    lap = bandpass(pink(secs + fade, rng), 350, 0.8)
    write("amb_estuary", loopable(mix((mul(wind, gust), 1.0), (lap, 0.4)), secs, fade), -9)
    # Underground (the stacks): close, dry room tone.
    secs = 10.0
    write("amb_underground", loopable(lowpass(brown(secs + fade, rng), 220), secs, fade), -16)


if __name__ == "__main__":
    print("Writing sounds to %s" % OUT)
    build()
    # Godot only sees new sound files once it has imported them.
    subprocess.run(["godot", "--headless", "--path", ROOT, "--import"], capture_output=True, timeout=600)
    sys.exit(0)
