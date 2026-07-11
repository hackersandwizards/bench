# Model selection (Codex, gpt-5.6)

Default: `gpt-5.6-luna`, effort `high`.

| Pick | For |
|------|-----|
| luna high | everyday coding |
| luna xhigh | better quality without switching models |
| terra medium | bigger features |
| terra high | repo-wide changes |
| sol high | judgment: planning, hard bugs, architecture, final review |

- Below sol high, luna at higher effort is the same or better, cheaper.
- Instead of sol xhigh, use terra ultra. Sol ultra over sol max is rarely worth the cost.
- `ultra` efforts (terra, sol) delegate to parallel agents and burn usage fast; the fan-out cap in `tools.md` applies.
