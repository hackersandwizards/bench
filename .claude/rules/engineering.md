# Engineering Principles

**Code Quality:**
- Favor simple, clean, maintainable solutions. Readability and changeability are primary.
- Small functions. Single responsibility.
- Build against real systems; reserve mocks for isolated test seams.
- Verify integration points, APIs, and libraries exist before building on them.

**Test-Driven Development (Default):**
Follow the RED-GREEN-REFACTOR cycle for new features and non-trivial logic:
1. **RED**: Write a concrete failing test that defines the requirement.
2. **GREEN**: Write the minimum code to make it pass.
3. **REFACTOR**: Clean up via `/simplify` and `/code-review high` while keeping tests green.

TDD applies to features and non-trivial logic in real projects. Scripts, spikes, one-off tools, config tweaks, doc edits, typo fixes, and one-line changes skip the cycle and get the minimal runnable check instead (see minimalism.md). Use judgment.

**Progression:**
1. **Make it work**: functioning code that passes tests.
2. **Make it right**: refactor for clarity and maintainability.
3. **Make it fast**: optimize only after profiling reveals a real bottleneck.
4. **Remember insights**: compound knowledge so the next session starts smarter.

**Comments (default to none):**
The code says *what*; a comment exists only for a *why* the code cannot show. Write far fewer comments than feel natural.
- Do not write a comment that restates what the next line does, names where code came from, or explains why your change is correct. That is talk for the reviewer, not the next reader, and it is noise once the PR merges.
- Keep only: a non-obvious *why*, a constraint the code can't express, a public API docstring, and directive comments (shellcheck, eslint, noqa, pragma, shebang).
- When a comment earns its place, make it one short sentence in plain ASCII.

**Documentation Hierarchy:**
1. Working code: self-documenting through clear naming.
2. Tests: executable documentation; the tests are the spec.
3. README / docs: setup, architecture, API specs.
4. Comments: last resort, per the comments rule above.

**Fail Fast & Validate:**
- Validate aggressively at inputs and integration boundaries.
- Give clear, descriptive errors when something breaks.
- Actively probe edge cases, invalid inputs, and unexpected conditions.
- Before delivering, ask: "Would a staff engineer approve this?" Codex will review afterward.

**Cleanliness:**
- Clean up test scripts, data files, temporary backups, and other temporary files when done.
- Remove files from strategies tried and abandoned.
- Keep project organization consistent.
