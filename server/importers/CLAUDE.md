# Curriculum Importer Framework

Python framework for importing external curriculum sources into UMLCF format.

## Purpose

Ingest curriculum from external sources (MIT OCW, Stanford SEE, Fast.ai, CK-12) and convert to the UnaMentis Curriculum Format (UMLCF).

## Architecture

```
importers/
├── core/              # Framework core
│   ├── base.py        # Base importer class
│   ├── models.py      # Data models
│   ├── registry.py    # Importer registry
│   └── orchestrator.py # Import orchestration engine
├── sources/           # Source-specific importers
│   └── mit_ocw.py     # MIT OpenCourseWare importer
├── parsers/           # Content parsers
├── enrichment/        # AI enrichment pipeline
├── tests/             # Importer tests
├── data/              # Runtime data
└── output/            # Import output
```

## Key Patterns

### Base Importer

All importers extend the base class in `core/base.py`:

```python
class BaseImporter:
    async def fetch_catalog(self) -> List[Course]
    async def import_course(self, course_id: str) -> Curriculum
    async def enrich(self, curriculum: Curriculum) -> Curriculum
```

### Registry

Importers register themselves via `core/registry.py`:

```python
registry.register("mit_ocw", MITOCWImporter)
```

### Orchestrator

The orchestrator in `core/orchestrator.py` coordinates:
1. Source discovery
2. Course selection
3. Import execution
4. AI enrichment
5. UMLCF output generation

## Testing

```bash
cd server/importers
pytest tests/
```

## Importer Specifications

Detailed specs for each source are in `curriculum/importers/`:
- `MIT_OCW_IMPORTER_SPEC.md`
- `STANFORD_SEE_IMPORTER_SPEC.md`
- `FASTAI_IMPORTER_SPEC.md`
- `CK12_IMPORTER_SPEC.md`

## Output Format

All importers produce UMLCF-compliant JSON. See `curriculum/spec/` for the full specification.
