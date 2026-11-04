# Working-tree scope and preservation

The working tree is **not clean and does contain unrelated work**. The following two tracked modifications were already present before the typography task:

- `landing/index.html`
- `docs/reviews/2026-10-28-final-checking-readiness.md`

There are also pre-existing untracked reports, landing assets, generated files and archives. The initial status and the task's changed-file inventory distinguish them from migration files. No other unexpected tracked changes were found. The complete [classification](evidence/working-tree-classification.json) records each current path.

For this review-package operation, every existing changed/untracked file was frozen with SHA-256 before packaging and checked again afterward; the [preservation proof](evidence/review-preservation-sha256.json) records each result. The [raw start hashes](evidence/review-start-sha256.json) allow independent comparison. The pre-existing deleted legacy typography test path is recorded as deleted; the replacement test remains present. New files from this operation are confined to this review package and its ZIP; temporary tooling/logs are ignored under scratch/typography.

Historical limit: no complete byte-hash inventory was captured before the original migration. The original unrelated modifications were preserved according to the recorded initial status and the task's scoped file operations; their original pre-migration bytes cannot be independently proven by a retrospective hash. The before/after hashes in this package prove that review preparation left the current implementation and existing unrelated files unchanged.

No source edits, visual changes, commits, staging, release builds, IPA creation, or archive deletion were performed during review preparation.
