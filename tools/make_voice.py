#!/usr/bin/env python3
"""Voices every line the Steward speaks (placeholder text-to-speech, DECISIONS #85).

    python3 -I tools/make_voice.py            # voices new or changed lines into assets/voice/
    python3 -I tools/make_voice.py --all      # re-voices everything (after changing the voice below)

The lines come from the game itself (tools/voice_manifest.gd lists VoiceLines.all()), so the game and the
voice files can't disagree about ids. A line is re-voiced only when its text or the voice settings change;
assets/voice/manifest.json remembers what each file says, and a test fails if any file is missing or stale.

Needs Piper in its own environment (see PROGRESS.md, "How to rebuild the voice"):
    PIPER_PYTHON   default ~/.local/opt/piper-venv/bin/python
    PIPER_VOICES   default ~/.local/opt/piper-voices
The voice: Piper's en_GB "cori" (high quality; trained on public-domain LibriVox recordings), lowered two
semitones with formants kept, slowed a little, warmed, and levelled. Warm, unhurried, mid-register.
"""
import hashlib
import json
import os
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "voice")
MANIFEST = os.path.join(OUT, "manifest.json")
PIPER_PYTHON = os.environ.get("PIPER_PYTHON", os.path.expanduser("~/.local/opt/piper-venv/bin/python"))
VOICES = os.environ.get("PIPER_VOICES", os.path.expanduser("~/.local/opt/piper-voices"))

MODEL = "en_GB-cori-high"
LENGTH_SCALE = 1.12        # > 1 is slower: unhurried
SENTENCE_SILENCE = 0.28    # seconds between sentences
PITCH = 0.891              # two semitones down: mid-register
FILTERS = ("rubberband=pitch=%s:formant=preserved,highpass=f=70,bass=g=2.5:f=200,"
           "equalizer=f=3200:t=q:w=1.2:g=-1.5,lowpass=f=10000,loudnorm=I=-18:TP=-2:LRA=7" % PITCH)
SETTINGS = "|".join([MODEL, str(LENGTH_SCALE), str(SENTENCE_SILENCE), FILTERS])


def lines_from_game():
    out = subprocess.run(["godot", "--headless", "--path", ROOT, "-s", "tools/voice_manifest.gd"],
                         capture_output=True, text=True, timeout=300).stdout
    if "VOICE_MANIFEST_BEGIN" not in out:
        sys.exit("could not read the lines from the game:\n" + out[-2000:])
    return json.loads(out.split("VOICE_MANIFEST_BEGIN", 1)[1].split("VOICE_MANIFEST_END", 1)[0])


def spoken_form(text):
    """What the voice reads. A line ending in a dash is cut off mid-word (the Quiet)."""
    cut = text.rstrip().endswith("—")
    t = text.rstrip().rstrip("—").replace("—", ", ").replace("·", ",")
    return t, cut


def duration(path):
    out = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", path],
                         capture_output=True, text=True, check=True).stdout
    return float(out.strip())


def voice(line_id, text, dst):
    spoken, cut = spoken_form(text)
    with tempfile.TemporaryDirectory() as tmp:
        raw = os.path.join(tmp, "raw.wav")
        subprocess.run([PIPER_PYTHON, "-m", "piper", "-m", os.path.join(VOICES, MODEL + ".onnx"), "-f", raw,
                        "--length-scale", str(LENGTH_SCALE), "--sentence-silence", str(SENTENCE_SILENCE)],
                       input=spoken, text=True, capture_output=True, check=True)
        filters = FILTERS
        if cut:
            # Stop dead a beat before the end of the last word: no fade-out, just a 6 ms click guard.
            end = max(0.3, duration(raw) - 0.12)
            filters = "atrim=end=%.3f,afade=t=out:st=%.3f:d=0.006," % (end, end - 0.006) + filters
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", raw, "-af", filters, "-ar", "44100", "-ac", "1",
                        "-c:a", "libvorbis", "-q:a", "4", "-map_metadata", "-1",
                        "-fflags", "+bitexact", "-flags:a", "+bitexact", dst], check=True)


def main():
    redo_all = "--all" in sys.argv
    if not os.path.exists(PIPER_PYTHON):
        sys.exit("Piper isn't installed at %s (see PROGRESS.md, 'How to rebuild the voice')" % PIPER_PYTHON)
    os.makedirs(OUT, exist_ok=True)
    lines = lines_from_game()
    old = json.load(open(MANIFEST)) if os.path.exists(MANIFEST) else {}
    manifest, made = {}, 0
    for line_id in sorted(lines):
        text = lines[line_id]
        digest = hashlib.sha1((SETTINGS + "\n" + text).encode()).hexdigest()
        dst = os.path.join(OUT, line_id + ".ogg")
        if redo_all or old.get(line_id, {}).get("hash") != digest or not os.path.exists(dst):
            voice(line_id, text, dst)
            made += 1
            print("  voiced %-34s %5.2f s  %s" % (line_id, duration(dst), text[:60]))
        manifest[line_id] = {"text": text, "hash": digest}
    for f in os.listdir(OUT):
        if f.endswith(".ogg") and f[:-4] not in manifest:
            os.remove(os.path.join(OUT, f))
            print("  removed %s (no such line any more)" % f)
    with open(MANIFEST, "w") as fh:
        json.dump(manifest, fh, indent=1, sort_keys=True, ensure_ascii=False)
        fh.write("\n")
    print("%d lines, %d voiced now" % (len(manifest), made))


if __name__ == "__main__":
    main()
