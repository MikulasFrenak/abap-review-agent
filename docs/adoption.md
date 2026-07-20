# Adopting abap-review-agent in an SAP team

How a team goes from "an AI agent reviewed our ABAP once as a demo" to running it as a normal part of the change process. Same enablement pipeline as the [AI Delivery Playbook](https://github.com/MikulasFrenak/ai-delivery-playbook)'s [team adoption guide](https://github.com/MikulasFrenak/ai-delivery-playbook/blob/main/docs/adoption.md) — this is that pipeline applied specifically to SAP/ABAP code review, not a different philosophy.

```
Research
    ↓
Workshop / live demo on the team's own code
    ↓
Pilot on one real transport / package (informational only)
    ↓
Wired into the review process (still informational)
    ↓
Promoted to a gate, once trusted
```

The goal is *not* "one developer runs the agent on their own code before committing." It's "the team's review process includes this check, everyone knows what it does and doesn't catch, and someone owns the eval suite." A tool nobody trusts or maintains decays into noise nobody reads.

## The stages

**1. Research.** Run `abap-code-review` yourself first, against `fixtures/` and then against a real target (abapGit, or — once trust is established — the team's own code). Read every finding by hand before showing anyone else. You can't vouch for a report you haven't verified.

**2. Workshop / live demo.** Run it live against a package the team actually recognizes — their own code, not just abapGit. Show a real finding, and just as importantly, show a false positive if one turns up. A tool that only ever demos clean results teaches the wrong lesson: that it's infallible. It isn't, and the report format says so explicitly (see each skill's "honest limits" section).

**3. Pilot on one real transport/package — informational only.** Run it against one change before it goes through normal review. Findings go to the reviewer as input, not as an automatic blocker. This is where the team learns the actual failure modes: which patterns it catches reliably, which need a human's business-context judgment on top (is this SELECT-in-loop actually a problem, or is the outer loop bounded to 3 iterations?).

**4. Wire it into the process, still informational.** Run it automatically on every transport/package under review (CI, a pre-review script, whatever this team's release process already uses) but keep it advisory. The report is one more thing the reviewer reads, not a merge gate yet.

**5. Promote to a gate, once trusted — and only for what's actually reliable.** After enough pilots, some findings (e.g. missing `FOR ALL ENTRIES` guards — close to unambiguously wrong) may be worth blocking on. Others (severity judgment on internal-table anti-patterns) may stay advisory indefinitely, because they genuinely need business/data-volume context a static scan doesn't have. Don't gate on a category until its false-positive rate has actually been measured, not assumed.

## What makes it stick

**The eval suite is a living artifact, not a one-time setup step.** Every real false positive or missed finding from a pilot run becomes a new fixture in `fixtures/` with the correct expected outcome, checked by `scripts/check_fixtures.py`. If the fixtures never grow after the initial build, the tool isn't actually learning from real usage — it's frozen at demo quality.

**Findings are a starting point for the reviewer's own judgment, not a verdict.** The same "why" discipline that makes human code review useful applies here: a finding says *what pattern matched and why it's usually a problem*, not *this is definitely wrong, fix it*. A reviewer who rubber-stamps agent findings without applying their own judgment isn't reviewing.

**Report the false-positive rate honestly, every time.** Per the project's own success criteria: "verified honestly — document the false-positive rate rather than overclaiming accuracy." A tool that quietly stops disclosing its error rate is the fastest way to lose a team's trust in it.

**This is a review aid, not an ATC replacement or an auto-fixer.** It doesn't touch code, doesn't replace SAP's own tooling, and doesn't claim completeness — a clean report means "no findings for the patterns currently checked," not "this code has no issues." Setting that expectation correctly on day one avoids the credibility hit of someone assuming otherwise and being disappointed later.
