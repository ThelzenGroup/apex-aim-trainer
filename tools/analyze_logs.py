"""Summarise Apex Aim Lab telemetry logs (the CSVs from the game's logs folder).

    python3 tools/analyze_logs.py <logs folder or .csv files> [--windows SECONDS]

For each log: frame rate, 1% lows, slow-frame counts against 240 Hz, where frame time
went (script, physics, render CPU, GPU) for every frame and for the slowest 1%, mouse
event rate while moving, and notes (clicks, live bullets). With --windows, also prints
FPS per time window, which shows frame-cap or V-Sync changes during a session.
"""
import argparse
import csv
import statistics as st
import sys
from pathlib import Path

TIMING = ("process_ms", "physics_ms", "render_cpu_ms", "gpu_ms")


def load(path):
    rows = list(csv.DictReader(path.open()))
    for r in rows:
        r["t"] = float(r["time_s"])
        r["ms"] = float(r["frame_ms"])
        r["dx"] = int(float(r["mouse_counts_x"]))
        r["events"] = int(r["mouse_events"])
        for key in TIMING:
            if key in r:
                r[key] = float(r[key])
    return rows


def low_1(frame_ms):
    worst = sorted(frame_ms)[-max(1, len(frame_ms) // 100):]
    return 1000.0 * len(worst) / sum(worst)


def summarise(path, window):
    rows = load(path)
    if len(rows) < 2:
        print(f"== {path.name}: too short")
        return
    ms = sorted(r["ms"] for r in rows)
    n, duration = len(ms), rows[-1]["t"] - rows[0]["t"]
    print(f"== {path.name}: {n} frames over {duration:.1f} s")
    print(f"   {n / duration:.0f} FPS average, 1% low {low_1(ms):.0f}, median {st.median(ms):.2f} ms, "
          f"p99 {ms[int(n * 0.99)]:.2f} ms, worst {ms[-1]:.1f} ms")
    print(f"   frames over 4.17 ms: {sum(m > 1000 / 240 for m in ms)} ({100 * sum(m > 1000 / 240 for m in ms) / n:.1f}%), "
          f"over 16 ms: {sum(m > 16 for m in ms)}, over 100 ms: {sum(m > 100 for m in ms)}")

    if all(key in rows[0] for key in TIMING):
        # Builds before 2026-10-08 logged Godot's TIME_PROCESS, the worst step of the last
        # second repeated on every row, so those script and physics columns aren't per frame.
        if len({r["process_ms"] for r in rows}) < max(3, n // 50):
            print("   note: this log's script/physics columns are per-second worst values (older build)")
        slowest = sorted(rows, key=lambda r: -r["ms"])[:max(1, n // 100)]
        for label, sample in (("every frame", rows), ("slowest 1%", slowest)):
            avg = {key: st.mean(r[key] for r in sample) for key in TIMING}
            print(f"   {label:12s} scripts {avg['process_ms']:.2f} · physics {avg['physics_ms']:.2f} · "
                  f"render CPU {avg['render_cpu_ms']:.2f} · GPU {avg['gpu_ms']:.2f} ms "
                  f"(frame {st.mean(r['ms'] for r in sample):.2f} ms)")

    moving_events = moving_ms = 0
    for previous, row in zip(rows, rows[1:]):
        if row["events"] and previous["events"]:
            moving_events += row["events"]
            moving_ms += row["ms"]
    if moving_ms:
        print(f"   mouse: {sum(r['events'] for r in rows)} events, net {sum(r['dx'] for r in rows)} x counts, "
              f"about {1000 * moving_events / moving_ms:.0f} events/s while moving")

    notes = [r["note"] for r in rows if r["note"]]
    if notes and all(note.isdigit() for note in notes):
        print(f"   live bullets: mean {st.mean(int(x) for x in notes):.0f}, max {max(int(x) for x in notes)}")
    elif notes:
        print(f"   notes: " + ", ".join(f"{notes.count(x)} × {x}" for x in sorted(set(notes))))

    if window:
        start = rows[0]["t"]
        while start < rows[-1]["t"]:
            part = [r for r in rows if start <= r["t"] < start + window]
            if part:
                print(f"   {start:6.1f}–{start + window:6.1f} s: {len(part) / window:6.0f} FPS, "
                      f"median {st.median(r['ms'] for r in part):.2f} ms, 1% low {low_1([r['ms'] for r in part]):.0f}")
            start += window


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("paths", nargs="+", type=Path)
    parser.add_argument("--windows", type=float, default=0.0, help="also print FPS per window of this many seconds")
    args = parser.parse_args()
    files = []
    for path in args.paths:
        files += sorted(path.glob("*.csv")) if path.is_dir() else [path]
    if not files:
        sys.exit("no CSV logs found")
    for path in files:
        summarise(path, args.windows)


if __name__ == "__main__":
    main()
