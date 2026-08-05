# ls-compat implementation plan

## Goal

Replace selected direct SBCL extension use with a small, testable portability
facade so client systems can load under SBCL and CCL. ECL is best effort.

## Checkpoints

- [x] Define core, POSIX, and TCP API boundaries.
- [ ] Implement and validate `ls-compat` under SBCL and CCL.
- [ ] Migrate UTF-8, timeout, POSIX, and TCP call sites in clean client repos.
- [ ] Re-test each migrated system on SBCL and CCL.
- [ ] Record remaining deliberate SBCL-only systems.

## Deferred work

- Orfeus is under active development and is not modified here.
- Immortal Coil and Waytemp have pre-existing tracked changes.
- `sbcl-workers` remains an SBCL worker-core manager unless a separate design
  replaces its process and image model.
