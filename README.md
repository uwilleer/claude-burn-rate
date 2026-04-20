# claude-burn

Minimalist burn-rate indicator for **Claude Code**, designed for **Claude Max** subscribers who want to see — at a glance — how fast their current 5-hour block is being consumed, and whether they're on track to exceed it.

## Why

Claude Max meters usage in **rolling 5-hour blocks**. The official UI surfaces this only after you hit a limit. `claude-burn` puts a one-line indicator in Claude Code's statusline that:

- **Stays invisible** when you're nowhere near a limit (dim grey dot)
- **Warns early** when projection approaches the block ceiling (yellow)
- **Shouts** when you're going to exceed the block (bold red 🔥)
- **Shows the moment things change** with a trend arrow (↑ / ⇈ / ↓)

No dollar amounts — you're paying a subscription, not per-token. The metric is % of your own calibrated block ceiling.

## How it looks

![claude-burn statusline](docs/statusline.png)

```
● block 15→32% →       # dim grey — quiet, plenty of headroom
● block 25→74% ↑       # green    — normal, pace increasing
● block 58→98% ⇈       # yellow   — close to ceiling
🔥 block 72→148% ⇈     # bold red — will exceed block limit
```

- **block X→Y%** — tokens used **so far → projected end-of-block** in the current 5-hour window, as % of your calibrated block ceiling
- **trend arrow** — change in projection vs previous tick: `→` stable, `↑` rising (+5–15%), `⇈` spike (≥+15%), `↓` falling (≤−5%)

> **Weekly limits** (All models / Sonnet / Design) are separate Anthropic-side caps, partially invisible to local logs — webapp and mobile usage isn't captured by `ccusage`. Check Claude settings → Usage directly for those.

> **A note on accuracy.** `ccusage` reconstructs the 5-hour window from your local Claude Code JSONL logs — so "when does this block reset" is a local estimate, not what the Claude server actually uses. That's why this tool **does not display a countdown**: open Claude's settings → Usage for the real reset time. The block % and projection, once calibrated, tend to match Claude's UI within a few points.

## Install

### Prerequisites

- [Claude Code](https://claude.com/claude-code)
- [`ccusage`](https://github.com/ryoppippi/ccusage) — `bun add -g ccusage` (or `npm i -g ccusage`)
- `jq`

### Install the binary

```sh
git clone https://github.com/uwilleer/claude-burn-rate.git
cd claude-burn-rate
./install.sh
```

Or manually:

```sh
install -m 0755 bin/claude-burn /usr/local/bin/claude-burn
```

### Wire it into Claude Code

Add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "claude-burn"
  }
}
```

Or, to **append** to an existing statusline script (recommended if you already have one), add this at the end of your script:

```sh
claude-burn
```

`claude-burn` prints exactly one line and exits.

## Calibration (important)

`ccusage` does not know your Claude Max plan's real block ceiling — it approximates with the **historical maximum** of your past blocks, which can drift from the real limit (if you ever used pay-per-use API, or your plan changed). The first time you install, the indicator may disagree with what Claude's UI shows.

**To align:**

1. Open Claude settings → Usage. Note **two** numbers for the current session:
   - percentage used (e.g. `57%`)
   - remaining time (e.g. `1 hr 26 min`)
2. Run:
   ```sh
   claude-burn calibrate 57 1h26m
   ```

This writes the block token ceiling **and** the offset between ccusage's locally-reconstructed block end and Claude's real block end to `$BURN_CACHE_DIR/burn-limit`. Without the time offset, projections silently inflate (e.g. `block 25→180%` when you'd actually land at `106%`), because the projection formula multiplies your burn rate by how long is left in the block — and ccusage's idea of "how long" can be off by 1–2 hours.

Re-run calibration whenever the two numbers drift apart. You'll know it's time if the indicator's projection keeps going up even though the Claude UI says you'll easily make it to reset.

Alternative: if you know your plan's exact per-block token ceiling, set `BURN_BLOCK_LIMIT=<tokens>` in your environment. It takes precedence over the calibrated file.

## Configuration

All knobs are environment variables.

| Variable | Default | Meaning |
|---|---|---|
| `BURN_CACHE_DIR` | `$HOME/.claude` | Where the cache, history, and calibrated limit file live |
| `BURN_MAX_AGE` | `15` | Cache TTL in seconds (stale-while-revalidate) |
| `BURN_BLOCK_LIMIT` | unset | Explicit block token limit. Overrides calibration and ccusage's historical max. |
| `BURN_GREEN_MAX` | `60` | Upper bound of the green band (% of block) |
| `BURN_YELLOW_MAX` | `90` | Upper bound of the yellow band |
| `BURN_RED_MAX` | `110` | Upper bound of bold red without 🔥 |

## How it works

1. Calls `ccusage blocks --json --active --offline --token-limit max` in the **background**, once per `BURN_MAX_AGE` seconds. Result is cached.
2. Parses block data to compute `current %` (tokens so far) and `projected %` (extrapolated to end of block).
3. Appends the projection % to a rolling history file and diffs against the previous sample for the trend arrow.
4. Prints one ANSI-coloured line.

Statusline invocations are **non-blocking**: the first call after a cache expires returns stale data immediately and kicks the refresh in the background.

## Performance

- Each tick: 1 `jq` call, 1 `stat`, a couple of `printf`s — sub-millisecond.
- Background refresh: `ccusage blocks` takes ~10 s on a large log directory; it's backgrounded so it never blocks statusline rendering.
- No network calls (`--offline` uses cached pricing).

## Privacy

- Reads only local Claude Code JSONL logs (via `ccusage`)
- Writes only to `$BURN_CACHE_DIR` (cache + trend history)
- No telemetry, no network

## Compatibility

- macOS (`stat -f %m`) and Linux (`stat -c %Y`) — both supported
- POSIX `sh`

## License

MIT — see [LICENSE](LICENSE).
