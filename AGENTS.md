# Repository Guidelines

## Project Structure & Module Organization
- Primary source lives in `openGrid-beam.scad`; it defines the edge beam geometry, parameters, and helper functions.
- External library dependency: `BOSL2/std.scad` is included; optional `openGrid/openGrid.scad` can be enabled when available.
- Keep future variants (e.g., fixtures, demos, exports) in sibling `.scad` files; place generated meshes in `build/` (create as needed) to avoid mixing artifacts with source.

## Build, Test, and Development Commands
- Preview model: `openscad openGrid-beam.scad` to inspect interactively.
- Export STL: `mkdir -p build && openscad -o build/openGrid-beam.stl openGrid-beam.scad`.
- Override parameters at CLI (example generates a 3-cell Lite beam): `openscad -D Full_or_Lite=\"Lite\" -D Beam_width=3 -o build/beam-lite-3.stl openGrid-beam.scad`.

## Coding Style & Naming Conventions
- Indentation: 4 spaces; no tabs. Keep trailing whitespace trimmed.
- Parameter names use CamelCase with underscores for multiword flags (e.g., `Half_left_end_segment`); functions use snake_case.
- Keep German comments where they already exist; add brief English comments for new logic that is not obvious.
- Group configuration blocks with section banners (as in the existing file) and place derived constants below their sources.

## Testing Guidelines
- Use OpenSCAD preview (`F5`) to validate shapes; use render (`F6`) before exporting.
- For parameterized checks, create temporary small scripts under `tmp/` or `build/` that `use`/`include` the main file; delete or ignore them in commits.
- Visually confirm connector cutouts, segment lengths, and chamfers when toggling `Half_*` flags.

## Commit & Pull Request Guidelines
- Follow the existing short, present-tense style (e.g., `progress`, `good`); keep messages concise but descriptive when possible (e.g., `tune-chamfer`, `add-corner-mode`).
- One change per commit: modeling tweaks, parameter defaults, or docs separately.
- PRs should list: purpose, key parameter changes/defaults, screenshots of preview if geometry changed, and any new commands used to export artifacts.
