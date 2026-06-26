# Plan — DMgtAsia Spatial Epidemiology Workshop Website

How to take the current consolidated repo and turn it into a polished, DMgtAsia-branded
workshop website. The module **consolidates and adapts material refined across multiple
spatial data science trainings and workshops delivered across India**.

Repo: <https://github.com/drarunmitra/DMgtAsia_Spatial_Module>

---

## 1. Where we are now (done)

- ✅ Consolidated, **runnable** module (all 20 exercise data paths resolve; verified statically).
- ✅ Quarto **website** (`_quarto.yml`, `type: website`, `output-dir: docs`), navbar organised by Unit A–D, DMgtAsia logo + footer.
- ✅ Landing (`index.qmd`), `setup.qmd`, `about.qmd`, `capstone.qmd`.
- ✅ Slides (Units A–C), exercises (Ex 1–4, 6, 7, John Snow, SIR/SMR), capstone pipeline, datasets, readings, and 4 Moodle quiz banks — all committed.
- ✅ GitHub repo created + pushed; CI publish workflow added (`.github/workflows/publish.yml`).

## 2. Publishing — two-repo setup (done)

The website is **separated from the runnable R Project** across two repos:

| Repo | Role | Pages |
|------|------|-------|
| **`DMgtAsia_Spatial_Module`** (this one) | clone-and-run **R Project**: source `.qmd`, exercises, `spatial_files/`, data — no rendered HTML | off |
| **`DMgtAsia_Spatial_Module_site`** | rendered static site (`docs/`) | on → live |

**Live site:** <https://drarunmitra.github.io/DMgtAsia_Spatial_Module_site/>

The site is **rendered locally** (no CI, no source-compiling `sf` on GitHub — pushes are
instant) and `docs/` is its own git checkout of the website repo.

**To update the site after editing content:**
```bash
./publish.sh        # quarto render + commit/push to the website repo
```
`freeze: auto` means only chunks you changed re-run. Why local-render beats CI here: the
slides are static once built, so GitHub never needs to run R.

## 3. Tailor for DMgtAsia (branding pass)

| Task | Where | Effort |
|------|-------|--------|
| Re-skin slide decks with DMgtAsia logo + colours (currently generic) | add `logo:`/`footer:` to each deck's `revealjs:` block; extend `styles.css` | M |
| Replace residual GIS4PublicHealth wording in slide bodies | `session*.qmd` | S |
| Add DMgtAsia course/credit framing (ECTS/ESG, learning outcomes block) | `index.qmd`, `setup.qmd` | S |
| Localise examples to DMgtAsia geographies (Kerala/AP tribal-health, Sholayur) | exercise narratives | M |
| Brand colour palette + fonts in `styles.css` + `theme` | `_quarto.yml`, `styles.css` | S |

## 4. Content to complete

- **Unit B hands-on**: an explicit EDA lab `.qmd` (WHO TB) — currently only the lecture deck. *(brief calls for a submitted EDA lab)*
- **Capstone outputs**: ship a pre-run `capstone/outputs/` (or a `freeze`d render) so `report.qmd` knits on a clean clone without running `run-all.R` first.
- **Accessibility analysis** lesson (service coverage / travel time) — gap noted in the content map; source bits exist (`demo_travel_est.r`, yellow-fever centres) but no finished lab.
- **Solution toggles**: wrap each exercise's answer in `callout-tip collapse="true"`; ship instructor vs participant builds via a `show_solutions` param.
- **Speaker notes** (⏱ time / 🎯 goal / 📋 check) on each deck for the intensive format.

## 5. Moodle integration (parallel track)

- Import `assessments/SDS4PH_Module1–4_Questions.xml` → Question bank → build one quiz per Unit (random draw from category).
- Embed each rendered slide deck (`docs/…slides-*.html`) as a Moodle **Page**/**File**; link exercises as **File** resources; the data bundle as a **Folder**/ZIP.
- Set **Restrict Access** to gate Unit B→C→D on the preceding quiz (≥60%); final project via **Workshop** (peer review).
- Full mapping in `~/Downloads/Module2_SpatialEpi_build_brief.md` §6.

## 6. Slimming the repo (optional, later)

The repo is self-contained (~165 MB) so it renders out of the box. To slim it:
move `spatial_files/` (the 117 MB bundle) to a **GitHub Release** asset, gitignore the
directory, and have `setup.qmd` download + unzip it. Keeps clones light; CI fetches the release.

## 7. Suggested sequence

1. Enable Pages (§2A) → confirm a live site.
2. Branding pass (§3) → DMgtAsia look.
3. Fill Unit B lab + solution toggles (§4).
4. Wire quizzes into Moodle (§5).
5. Dry-run the 2-day intensive; collect timings; then slim the repo (§6).
