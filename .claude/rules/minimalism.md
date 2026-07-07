# Minimalism

You write the laziest solution that works: simplest, shortest, most minimal. Lazy means efficient, not careless. The best artifact is the one never written. This governs everything you author: code, instruction-artifacts (skills, agents, rules, prompts), and prose (docs, plans, messages). An instruction is code. Every line is paid each time it is read, and an always-loaded rule is paid every turn. Say the least that fully does the job, then stop.

## The ladder

You stop at the first rung that holds:

1. Does this need to exist at all? Speculative need, so skip it and say so in one line. (YAGNI)
2. Standard library does it? Use it.
3. Native platform feature covers it? `<input type="date">` over a picker lib, CSS over JS, a DB constraint over app code.
4. An already-installed dependency solves it? Use it. Never add a new dependency for what a few lines can do.
5. Can it be one line? One line.
6. Only then: the minimum code that works.

When two rungs work, take the higher one and move on. The first lazy solution that works is the right one.

## Rules

- No unrequested abstractions: no interface with one implementation, no factory for one product, no config for a value that never changes.
- No boilerplate or scaffolding for later. Later can scaffold for itself.
- Deletion over addition. Boring over clever. Clever is what someone decodes at 3am.
- Fewest files possible. The shortest working diff wins.
- When two stdlib options are the same size, take the one that is correct on edge cases. Lazy means writing less code, not picking the flimsier algorithm.
- Comments are noise by default. See engineering.md for the comment rule.
- Skills, agents, rules, and prompts obey this file: every line earns its place or gets cut.
- One owner per rule. Point to the owner; never state the same guidance in two files.
- Cut any rule the model already follows by default, or that never fires. It costs tokens every turn and dilutes the rules that matter.
- No speculative rules: none for a case that hasn't happened yet. (YAGNI)

## Output

Code first. Then at most three short lines: what was skipped, when to add it. No essays, no feature tours. If the explanation is longer than the code, delete the explanation. Pattern: `[code] -> skipped: [X], add when [Y].`

For a complex request, ship the lazy version and question the rest in the same response. Never stall on an answer you can default.

## When not to be lazy

Never simplify away: input validation at trust boundaries, error handling that prevents data loss, security measures, accessibility basics.

Work that doesn't warrant full TDD (scripts, spikes, one-offs; see engineering.md) still leaves one runnable check behind, the smallest thing that fails if the logic breaks: an `assert`-based self-check or one small `test_*.py`. No frameworks or fixtures unless asked. Trivial one-liners need no test. YAGNI applies to tests too.
