# Copilot Instructions for Giardino di Rob

This repository documents Rob's garden through a structured system of zones, plants, projects, and maintenance schedules.

## Project Overview

- **Purpose**: Maintain versioned, searchable documentation of the garden's evolution, plant inventory, and maintenance schedules.
- **Language**: Italian (all content is in Italian; maintain consistency).
- **Build/Test**: No build process or tests. This is a documentation repository managed through Git.

## Repository Structure

```
giardino/
├── zone/                  # Garden zones (scivolo, est, crinale, orto)
│   └── [zone-name]/
│       ├── [zone].md      # Main zone documentation
│       ├── foto/          # Photos of the zone
│       └── piante/        # Plant subdirectories
│           └── [plant-name]/
│               ├── [plant].md   # Plant record
│               └── foto/        # Photos of that plant
│
├── progetti/              # Garden projects (planning, layout, improvements)
│   └── [project-name].md
│
├── manutenzione/          # Maintenance schedules and guides
│   ├── calendario-annuale.md    # Annual maintenance calendar
│   ├── potature.md              # Pruning guide
│   └── irrigazione.md           # Irrigation guide
│
├── copilot.json           # Agent configuration
└── README.md              # Repository overview
```

## Documentation Patterns

### Zone Files
Each zone document (`zone/[zone-name]/[zone].md`) includes:
- **Esposizione** (Exposure): Sun orientation, hours of direct sun
- **Microclima**: Microclimatic conditions (wind, humidity, temperature variations)
- **Suolo** (Soil): Soil type, drainage, composition
- **Piante presenti** (Current plants): List of plants with locations
- **Piante consigliate** (Recommended plants): Potential additions
- **Problemi da evitare** (Problems to avoid): Known challenges or unsuitable plants
- **Note storiche** (Historical notes): Evolution of the zone
- **Foto contestuali** (Context photos): Referenced in `foto/` subdirectory

### Plant Files
Each plant record (`zone/[zone]/piante/[plant]/[plant].md`) follows this structure:
- **Informazioni generali** (General info): Plant name (common + scientific), family, characteristics
- **Esposizione** (Exposure): Light, temperature, humidity requirements
- **Coltivazione** (Cultivation): Soil, watering, fertilization
- **Potatura e manutenzione** (Pruning & maintenance): Seasonal care
- **Parassiti e malattie** (Pests & diseases): Known issues and resistance
- **Fioritura** (Flowering): Bloom period, colors, fragrance
- **Note sulla foto** (Photo notes): Date, plant health status, observations from the image

### Project Files
Project documents (`progetti/[project-name].md`) include:
- **Obiettivo** (Goal): What the project aims to achieve
- **Piante coinvolte** (Plants involved): Which plants are affected/included
- **Schema visivo** (Visual schema): Layout or design notes
- **Stato attuale** (Current status): Progress and phase
- **Prossimi passi** (Next steps): Action items

### Maintenance Files
- `manutenzione/calendario-annuale.md`: Monthly tasks and seasonal activities
- `manutenzione/potature.md`: Pruning schedule and techniques
- `manutenzione/irrigazione.md`: Watering schedule, system notes, seasonal adjustments

## Key Conventions

### Naming
- **Zone names**: kebab-case in Italian (e.g., `lato-sinistro`, `lato-destro`)
- **Plant common names**: Italian, lowercase with kebab-case (e.g., `lavanda`, `spiraea-arguta`)
- **Plant files**: Use scientific name (Genus-species) or Italian name, consistency within zones

### Photo Management
- All photos are stored in `foto/` subdirectories adjacent to their context (zone or plant)
- Photos are referenced in documentation with date and context
- Maintains visual history of garden evolution

### Dates and Seasonality
- Use month names in Italian (gennaio, febbraio, etc.) or "date: [month] [year]" format
- Seasonal references use Italian terms: primavera (spring), estate (summer), autunno (autumn), inverno (winter)

### Italicized Scientific Names
Scientific plant names appear in *italic* format (e.g., *Lavandula angustifolia*) when mentioned.

### Plant Information Structure
When documenting plant care:
- **Temperature ranges**: Use format "da -X a +Y°C"
- **Light hours**: Specify in hours per day (e.g., "6-8 ore al giorno")
- **Moisture levels**: Use terms like "ben drenato" (well-draining), "secco" (dry), "umido" (moist)

## Workflows with Copilot

### Automated Plant Identification (identifyPlants script)

Use the `identifyPlants.sh` script to automate photo organization and documentation:

```bash
./scripts/identifyPlants.sh zone:<zone_path>
```

**Examples:**
- `./scripts/identifyPlants.sh zone:crinale`
- `./scripts/identifyPlants.sh zone:scivolo:lato-destro`

**What it does:**
1. Finds all photos matching `00_da_identificare.*` in `zone/[zone]/foto/`
2. Guides you through Copilot CLI to identify each plant
3. Organizes photos into `zone/[zone]/piante/[plant-name]/`
4. Renames photos from `00_da_identificare.jpg` to `00_[plant-name].jpg`
5. Optionally generates plant documentation markdown

See `scripts/README.md` for full documentation.

### Creating a New Plant Record

**Manual approach** (without photos):
1. Determine the zone and sub-zone location
2. Create directory: `zone/[zone]/piante/[plant-name]/`
3. Create `[plant-name].md` with full plant documentation
4. Add photos to `foto/` subdirectory if available
5. Update the parent zone's plant list

**Automated approach** (with photos):
1. Place unidentified photos in `zone/[zone]/foto/` with name pattern `00_da_identificare.jpg`
2. Run `./scripts/identifyPlants.sh zone:[zone-path]`
3. Follow the interactive prompts

### Updating a Zone
1. Add new plants to "Piante presenti" section
2. Update "Stato" if conditions have changed
3. Add historical notes if relevant changes occurred
4. Update photo gallery references

### Creating a Project
1. Create file in `progetti/[project-name].md`
2. Reference affected zones and plants
3. Include visual schema (as text-based ASCII or description)
4. Link to relevant plant records

## Git Workflow

- Commit messages should reference the content changed (e.g., "aggiunte zone", "aggiornate piante scivolo destro")
- Use Italian terminology for consistency with commit history
- Commits track documentation evolution alongside photos

## copilot.json Configuration

The `copilot.json` file specifies:
- Agent: `plant-health-evaluation.agent`
- Primary goals: botanical image analysis, Markdown generation, structural coherence

When generating new content, maintain consistency with existing documentation patterns and botanical accuracy.

## Common Tasks

### Adding a new plant identification
- Use plant-health-evaluation agent if images are provided
- Cross-reference with zone microclimate and existing plants
- Verify compatibility before adding to "Piante presenti"

### Seasonal maintenance planning
- Consult `manutenzione/calendario-annuale.md` for timing
- Update plant records with seasonal observations
- Note any deviations from normal maintenance

### Updating plant health notes
- Reference photo dates when documenting observations
- Include visible characteristics: leaf color, growth habit, flowering stage
- Note any signs of pests, diseases, or stress
