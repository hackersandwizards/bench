# Engineering Principles

**Code Quality:**
- Favor simple, clean, maintainable solutions. Readability and changeability are primary.
- Small functions. Single responsibility.
- Build against real systems; reserve mocks for isolated test seams.
- Verify integration points, APIs, and libraries exist before building on them.

**Test-Driven Development (Default):**
Follow the RED-GREEN-REFACTOR-INSIGHTS cycle for new features and non-trivial logic:
1. **RED** — Write a concrete failing test that defines the requirement.
2. **GREEN** — Write the minimum code to make it pass.
3. **REFACTOR** — Clean up while keeping tests green.
4. **INSIGHTS** — Capture what was learned. Run `/insights`.

Config tweaks, doc edits, typo fixes, and one-line changes skip the cycle — use judgment.

**Progression:**
1. **Make it work** — functioning code that passes tests.
2. **Make it right** — refactor for clarity and maintainability.
3. **Make it fast** — optimize only after profiling reveals a real bottleneck.
4. **Remember insights** — compound knowledge so the next session starts smarter.

**Documentation Hierarchy:**
1. Working code — self-documenting through clear naming.
2. Tests — executable documentation; the tests are the spec.
3. README / docs — setup, architecture, API specs.
4. Comments — reserve for non-obvious *why*, not *what*.

**Fail Fast & Validate:**
- Validate aggressively at inputs and integration boundaries.
- Give clear, descriptive errors when something breaks.
- Actively probe edge cases, invalid inputs, and unexpected conditions.
- Before delivering, ask: "Would a staff engineer approve this?" Codex will review afterward.

**Cleanliness:**
- Clean up test scripts, data files, and other temporary files when done.
- Remove files from strategies tried and abandoned.
- Keep project organization consistent.
