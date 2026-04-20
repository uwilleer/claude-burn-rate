# claude-burn

Minimalist burn-rate indicator for **Claude Code**, designed for **Claude Max** subscribers who want to see — at a glance — how fast their current 5-hour block is being consumed, and whether they're on track to exceed it.

## Why

Claude Max meters usage in **rolling 5-hour blocks**. The official UI surfaces this only after you hit a limit. `claude-burn` puts a one-line indicator in Claude Code's statusline that:

- **Stays invisible** when you're nowhere near a limit (dim grey dot)
- **Warns early** when projection approaches the block ceiling (yellow)
- **Shouts** when you're going to exceed the block (bold red 🔥)
- **Shows the moment things change** with a trend arrow (↑ / ⇈ / ↓)

No dollar amounts — you're paying a subscription, not per-token. The metric is % of your own historical block ceiling (what `ccusage --token-limit max` calls your "limit").

## How it looks

```
● block: 15% · projection 32% →                       # dim grey — quiet
● block: 25% · projection 74% ↑                       # green    — normal
● block: 58% · projection 98% ⇈  2h15m to reset       # yellow   — close to ceiling
🔥 block: 72% · projection 148% ⇈  1h42m to reset     # bold red — will exceed
```

- **block: X%** — tokens used so far in the current 5-hour block, as % of your historical max block
- **projection Y%** — extrapolation to end of block at current pace
- **trend** — vs previous tick: `→` stable, `↑` rising (+5–15%), `⇈` spike (≥+15%), `↓` falling (−5% or more)

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

## Configuration

All knobs are environment variables — set them in your shell or in the wrapping script.

| Variable | Default | Meaning |
|---|---|---|
| `BURN_CACHE_DIR` | `$HOME/.claude` | Where `burn-cache.json` and `burn-history` live |
| `BURN_MAX_AGE` | `30` | Cache TTL in seconds (stale-while-revalidate) |
| `BURN_GREEN_MAX` | `60` | Upper bound of the green band (% of block) |
| `BURN_YELLOW_MAX` | `90` | Upper bound of the yellow band |
| `BURN_RED_MAX` | `110` | Upper bound of bold red without 🔥 |

## How it works

1. Calls `ccusage blocks --json --active --offline --token-limit max` in the **background**, once per `BURN_MAX_AGE` seconds. Result is cached.
2. Parses `blocks[0].tokenLimitStatus.percentUsed` (projected %) and `totalTokens / limit` (current %).
3. Appends the projection % to a rolling history file and diffs against the previous sample for the trend arrow.
4. Prints one ANSI-coloured line.

Statusline invocations are **non-blocking**: the first call after 30 s of inactivity returns stale data immediately and kicks the refresh in the background.

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
