#!/usr/bin/env python3
import datetime as dt
import json
import os
from pathlib import Path
import sys
import time


CACHE_TTL_SECONDS = 30


def copilot_home() -> Path:
    return Path(os.environ.get("COPILOT_HOME") or Path.home() / ".copilot").expanduser()


def parse_timestamp(value: object) -> dt.datetime | None:
    if not isinstance(value, str):
        return None
    try:
        return dt.datetime.fromisoformat(value.replace("Z", "+00:00")).astimezone()
    except ValueError:
        return None


def nano_aiu_to_aiu(value: object) -> float:
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        return float(value) / 1_000_000_000
    return 0.0


def data_aiu(data: object) -> float:
    if not isinstance(data, dict):
        return 0.0

    total = nano_aiu_to_aiu(data.get("totalNanoAiu"))
    if total:
        return total

    model_metrics = data.get("modelMetrics")
    if not isinstance(model_metrics, dict):
        return 0.0

    return sum(
        nano_aiu_to_aiu(metric.get("totalNanoAiu"))
        for metric in model_metrics.values()
        if isinstance(metric, dict)
    )


def live_status_aiu(value: object) -> float:
    if isinstance(value, dict):
        total = data_aiu(value)
        if total:
            return total
        return sum(live_status_aiu(child) for child in value.values())

    if isinstance(value, list):
        return sum(live_status_aiu(child) for child in value)

    return 0.0


def event_files(home: Path) -> list[Path]:
    return list((home / "session-state").glob("*/events.jsonl"))


def latest_mtime_ns(paths: list[Path]) -> int:
    latest = 0
    for path in paths:
        try:
            latest = max(latest, path.stat().st_mtime_ns)
        except OSError:
            continue
    return latest


def read_cache(path: Path) -> dict[str, object]:
    try:
        return json.loads(path.read_text())
    except (OSError, json.JSONDecodeError):
        return {}


def write_cache(path: Path, payload: dict[str, object]) -> None:
    try:
        path.write_text(json.dumps(payload))
    except OSError:
        pass


def scan_historical_aiu(paths: list[Path], now: dt.datetime) -> float:
    total = 0.0
    for path in paths:
        try:
            lines = path.open(errors="replace")
        except OSError:
            continue

        with lines:
            for line in lines:
                try:
                    event = json.loads(line)
                except json.JSONDecodeError:
                    continue

                if event.get("type") != "session.shutdown":
                    continue

                event_time = parse_timestamp(event.get("timestamp"))
                if event_time is None:
                    continue
                if event_time.year != now.year or event_time.month != now.month:
                    continue

                total += data_aiu(event.get("data"))

    return total


def historical_aiu(home: Path, now: dt.datetime) -> float:
    month = f"{now.year:04d}-{now.month:02d}"
    cache_path = home / "statusline-aic-cache.json"
    cache = read_cache(cache_path)
    generated_at = cache.get("generated_at")

    if (
        cache.get("month") == month
        and isinstance(generated_at, (int, float))
        and time.time() - generated_at < CACHE_TTL_SECONDS
    ):
        total = cache.get("total")
        if isinstance(total, (int, float)) and not isinstance(total, bool):
            return float(total)

    paths = event_files(home)
    newest = latest_mtime_ns(paths)
    if cache.get("month") == month and cache.get("latest_mtime_ns") == newest:
        total = cache.get("total")
        if isinstance(total, (int, float)) and not isinstance(total, bool):
            return float(total)

    total = scan_historical_aiu(paths, now)
    write_cache(
        cache_path,
        {
            "month": month,
            "latest_mtime_ns": newest,
            "total": total,
            "generated_at": time.time(),
        },
    )
    return total


def read_status_stdin() -> object:
    if sys.stdin.isatty():
        return None

    raw = sys.stdin.read()
    if not raw.strip():
        return None
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return None


def format_aiu(value: float) -> str:
    if value.is_integer():
        return str(int(value))
    return f"{value:.1f}".rstrip("0").rstrip(".")


def main() -> int:
    now = dt.datetime.now().astimezone()
    total = historical_aiu(copilot_home(), now) + live_status_aiu(read_status_stdin())
    print(f"AIC {now:%b}: {format_aiu(total)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
