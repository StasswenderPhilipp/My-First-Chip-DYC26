# Chip Submissions

This directory contains student chip submissions. Each submission consists of a GDS file and a short README describing the design.

## Submission Process

1. **Fork** this repository.
2. **Create a folder** inside `chips/` named after your project (e.g. `chips/01-layr-1`).
3. **Add your files** — at minimum a GDS file, a `README.md`, and your design source files (see requirements below).
4. **Add your design data** inside `design_data/`, either directly or as a Git submodule (see requirements below).
5. **Open a Pull Request** against the main branch with the title: `[Submission] your_project_name`.
6. Wait for review. Once approved, your design will be merged into the repository.

> ⚠️ Do not modify other students' folders or any files outside your own submission directory.

## Directory Structure

```
chips/
├── README.md                  ← you are here
├── exampledesign/             ← reference example, see below
│   ├── gds/
│   │   └── exampledesign.gds
│   ├── design_data/           ← source files to reproduce the GDS
│   └── README.md
└── your_project_name/         ← your submission goes here
    ├── gds/
    │   └── your_project_name.gds
    ├── design_data/           ← source files to reproduce the GDS
    └── README.md
```

## Submission Requirements

### Folder name
Use the **exact same name you used for your final presentation** (e.g. `01-layr-1`, `03-gameoflife`), following the format `XX-project-name` with the same group number and name. This must match your entry in the course repository exactly.

### design_data
This folder must contain everything needed to reproduce your GDS from scratch. There are two accepted ways to provide it:

**Option A — Include files directly:** Add your source files (RTL, constraints, config, scripts, etc.) inside the `design_data/` folder as part of your PR.

**Option B — Git submodule:** If your design lives in its own repository, add it as a submodule:
```bash
git submodule add https://github.com/your_username/your_project_repo chips/your_project_name/design_data
```

Either way, someone with the same toolchain should be able to reproduce the GDS solely from the contents of `design_data/`.

### GDS file
Place your final GDS inside a `gds/` subfolder.

### README.md
Your `README.md` must include at minimum:

| Section | Description |
|---|---|
| **Project name** | Name of your design (must match your Moodle entry) |
| **Author** | Your name |
| **Description** | What the chip does (a few sentences) |
| **Pin list** | Table of all input/output pins with name, direction, and brief description |

You are encouraged to add images, schematics, simulation results, or any other relevant information.

## Example

See [`exampledesign/`](exampledesign/) for a complete reference submission you can use as a starting point.