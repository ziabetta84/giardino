#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the repository root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Function to print usage
usage() {
    echo "Usage: identifyPlants zone:<zone_path> [pianta:<plant_name>]"
    echo ""
    echo "Examples:"
    echo "  ./scripts/identifyPlants.sh zone:crinale"
    echo "  ./scripts/identifyPlants.sh zone:scivolo:lato-destro"
    echo "  ./scripts/identifyPlants.sh zone:scivolo:lato-sinistro"
    echo ""
    echo "Regenerate plant documentation from photos:"
    echo "  ./scripts/identifyPlants.sh zone:est pianta:spiraea-arguta"
    echo "  ./scripts/identifyPlants.sh zone:scivolo:lato-sinistro pianta:lavanda"
    exit 1
}

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Function to regenerate plant documentation from photos
regenerate_plant_documentation() {
    local ZONE_DIR="$1"
    local PLANT_NAME="$2"
    local PLANT_DIR="$ZONE_DIR/piante/$PLANT_NAME"
    local PLANT_MD="$PLANT_DIR/${PLANT_NAME}.md"
    
    # Validate plant directory exists
    if [[ ! -d "$PLANT_DIR" ]]; then
        print_error "Plant directory not found: $PLANT_DIR"
        return 1
    fi
    
    # Check if there are any photos in the plant directory
    local PHOTOS=()
    while IFS= read -r -d '' file; do
        PHOTOS+=("$file")
    done < <(find "$PLANT_DIR" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.JPG" -o -name "*.PNG" \) -print0)
    
    if [[ ${#PHOTOS[@]} -eq 0 ]]; then
        print_warning "No photos found in $PLANT_DIR"
        return 1
    fi
    
    print_info "Found ${#PHOTOS[@]} photo(s) for plant: $PLANT_NAME"
    print_info "Regenerating plant documentation..."
    echo ""
    
    # Extract zone path for the prompt
    local ZONE_PATH="${ZONE_DIR#$REPO_ROOT/zone/}"
    ZONE_PATH="${ZONE_PATH//\//:}"
    
    # Build the prompt for Copilot
    local MARKDOWN_PROMPT="Analizza le foto di questa pianta e genera una documentazione completa.

Nome della pianta: $PLANT_NAME
Zona: $ZONE_PATH

Rispondi con SOLO il markdown, nessun'altra spiegazione, usando questo template:

# $PLANT_NAME

## Informazioni generali
[Descrizione della pianta, famiglia, caratteristiche principali]

## Esposizione
- **Luce**: [ore di sole giornaliero]
- **Temperatura**: [range di temperature]
- **Umidità**: [livello di umidità preferito]

## Coltivazione
- **Terreno**: [tipo di terreno preferito]
- **Annaffiature**: [frequenza e quantità]
- **Concimazione**: [tipo e frequenza]

## Potatura e manutenzione
[Istruzioni per potatura e manutenzione stagionale]

## Parassiti e malattie
[Problemi comuni e come prevenirli]

## Fioritura
- Periodo: [mesi di fioritura]
- Colori fiori: [colori e forma]
- Profumo: [descrizione o 'non ha profumo particolare']

## Note sulla foto
- **Data foto**: [mese anno dalle foto disponibili]
- **Stato di salute**: [descrizione dello stato]
- **Osservazioni**: [note dettagliate su quello che si vede nelle foto]"
    
    # Call Copilot to generate markdown
    print_info "Calling Copilot CLI to generate documentation..."
    local PLANT_MD_CONTENT=$(copilot -p "$MARKDOWN_PROMPT" 2>/dev/null)
    
    if [[ -n "$PLANT_MD_CONTENT" ]]; then
        # Filter: extract only markdown starting from the first heading (#)
        # and remove everything from "Total usage" onwards
        PLANT_MD_CONTENT=$(echo "$PLANT_MD_CONTENT" | sed -n '/^# /,/^Total usage/p' | sed '/^Total usage/d')
        
        # Backup existing file if it exists
        if [[ -f "$PLANT_MD" ]]; then
            local BACKUP_FILE="${PLANT_MD}.backup.$(date +%s)"
            cp "$PLANT_MD" "$BACKUP_FILE"
            print_warning "Backed up existing documentation to: $(basename "$BACKUP_FILE")"
        fi
        
        echo "$PLANT_MD_CONTENT" > "$PLANT_MD"
        print_success "Regenerated: ${PLANT_NAME}.md"
        return 0
    else
        print_error "Failed to generate markdown documentation"
        return 1
    fi
}


if [[ $# -lt 1 || $# -gt 2 ]]; then
    usage
fi

ZONE_PARAM="$1"
PIANTA_PARAM="${2:-}"

# Extract zone path from parameter
if [[ ! $ZONE_PARAM =~ ^zone: ]]; then
    print_error "First parameter must start with 'zone:'"
    usage
fi

ZONE_PATH="${ZONE_PARAM#zone:}"
ZONE_PATH=$(echo "$ZONE_PATH" | tr ':' '/')

ZONE_DIR="$REPO_ROOT/zone/$ZONE_PATH"

# Check if we're in pianta regeneration mode
REGEN_PIANTA=""
if [[ -n "$PIANTA_PARAM" ]]; then
    if [[ ! $PIANTA_PARAM =~ ^pianta: ]]; then
        print_error "Second parameter must start with 'pianta:'"
        usage
    fi
    REGEN_PIANTA="${PIANTA_PARAM#pianta:}"
fi

# Validate that zone directory exists
if [[ ! -d "$ZONE_DIR" ]]; then
    print_error "Zone directory not found: $ZONE_DIR"
    exit 1
fi

# Handle plant regeneration mode
if [[ -n "$REGEN_PIANTA" ]]; then
    regenerate_plant_documentation "$ZONE_DIR" "$REGEN_PIANTA"
    exit $?
fi

# Check if foto directory exists
FOTO_DIR="$ZONE_DIR/foto"
if [[ ! -d "$FOTO_DIR" ]]; then
    print_warning "No foto directory found at: $FOTO_DIR"
    exit 0
fi

# Find all photo files (excluding those already organized in piante/)
ALL_PHOTOS=()
while IFS= read -r -d '' file; do
    ALL_PHOTOS+=("$file")
done < <(find "$FOTO_DIR" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.JPG" -o -name "*.PNG" \) -print0)

if [[ ${#ALL_PHOTOS[@]} -eq 0 ]]; then
    print_info "No photos found in $FOTO_DIR"
    exit 0
fi

print_info "Found ${#ALL_PHOTOS[@]} photo(s) in: $ZONE_PATH"
echo ""

# Process each photo
for photo_path in "${ALL_PHOTOS[@]}"; do
    photo_name=$(basename "$photo_path")
    photo_ext="${photo_name##*.}"
    
    # Check if this is an unidentified photo (*da_identificare.* or *da-identificare.*) or already has a plant name
    if [[ "$photo_name" =~ da[_-]identificare ]]; then
        # Unidentified photo - use Copilot to identify it
        print_info "Processing (unidentified): $photo_name"
        echo ""
        
        # Ask user for visual description to help Copilot identify the plant
        echo ""
        print_info "Descrivi brevemente cosa vedi nella foto per aiutare l'identificazione:"
        print_info "(colore fiori/foglie, forma, altezza stimata, caratteristiche particolari)"
        read -p "> " USER_DESCRIPTION
        echo ""

        # Helper function to call Copilot with the photo and optional description
        identify_with_copilot() {
            local extra_info="$1"
            local prompt="@${photo_path}

Analizza questa foto di una pianta nel giardino nella zona ${ZONE_PATH}."
            if [[ -n "$extra_info" ]]; then
                prompt="${prompt}
Informazioni aggiuntive dall'utente: ${extra_info}"
            fi
            prompt="${prompt}

Identifica il nome comune italiano e il nome scientifico della pianta.
Rispondi con UNA SOLA riga nel formato: nome_italiano|nome_scientifico
Esempi: lavanda|Lavandula angustifolia"
            copilot --allow-all-paths -p "$prompt" 2>/dev/null
        }

        # Helper function to parse Copilot response into PLANT_NAME and SCIENTIFIC_NAME
        parse_identification() {
            local response="$1"
            local id
            id=$(echo "$response" | grep -o '^[a-z][a-z0-9 -]*|[A-Za-z ].*$' | head -1)
            if [[ -z "$id" ]]; then
                id=$(echo "$response" | grep '|' | tail -1)
            fi
            echo "$id"
        }

        # Validate the parsed plant name is not a placeholder/error
        is_valid_plant_name() {
            local name="$1"
            local invalid_patterns=("da-identificare" "non-identificata" "non-identificato" "sconosciuta" "sconosciuto" "pianta" "unknown" "plant" "")
            for pattern in "${invalid_patterns[@]}"; do
                if [[ "$name" == "$pattern" ]]; then
                    return 1
                fi
            done
            return 0
        }

        # Use Copilot to identify the plant
        print_info "Analisi della foto con Copilot..."
        COPILOT_RESPONSE=$(identify_with_copilot "$USER_DESCRIPTION")

        IDENTIFICATION=$(parse_identification "$COPILOT_RESPONSE")
        PLANT_NAME=$(echo "$IDENTIFICATION" | cut -d'|' -f1 | xargs)
        SCIENTIFIC_NAME=$(echo "$IDENTIFICATION" | cut -d'|' -f2 | xargs)

        # Ask for user confirmation with option to try again or enter manually
        CONFIRMED=0
        while [[ $CONFIRMED -eq 0 ]]; do
            echo ""
            if [[ -n "$PLANT_NAME" ]] && is_valid_plant_name "$PLANT_NAME"; then
                print_info "Copilot ha identificato la pianta come:"
                echo "  Nome: $PLANT_NAME"
                echo "  Nome scientifico: $SCIENTIFIC_NAME"
                echo ""
                read -p "Conferma l'identificazione? (y/n/riprova/manuale): " CONFIRM_CHOICE
            else
                print_warning "Copilot non è riuscito a identificare la pianta con certezza."
                echo ""
                read -p "Cosa vuoi fare? (riprova/manuale/salta): " CONFIRM_CHOICE
                # Map to expected values for the case below
                [[ "$CONFIRM_CHOICE" == "salta" ]] && CONFIRM_CHOICE="n"
            fi

            case "$CONFIRM_CHOICE" in
                y|Y|yes|YES|si|SI|sì)
                    CONFIRMED=1
                    ;;
                n|N|no|NO|salta)
                    print_warning "Foto saltata."
                    echo ""
                    continue 2  # Continue outer loop (skip to next photo)
                    ;;
                riprova|retry|r|R|try-again)
                    echo ""
                    print_info "Aggiungi ulteriori dettagli per affinare l'identificazione (o premi Enter per riprovare con le stesse info):"
                    read -p "> " EXTRA_DESCRIPTION
                    [[ -z "$EXTRA_DESCRIPTION" ]] && EXTRA_DESCRIPTION="$USER_DESCRIPTION"
                    print_info "Rianalisi della foto con Copilot..."
                    COPILOT_RESPONSE=$(identify_with_copilot "$EXTRA_DESCRIPTION")
                    IDENTIFICATION=$(parse_identification "$COPILOT_RESPONSE")
                    PLANT_NAME=$(echo "$IDENTIFICATION" | cut -d'|' -f1 | xargs)
                    SCIENTIFIC_NAME=$(echo "$IDENTIFICATION" | cut -d'|' -f2 | xargs)
                    ;;
                manuale|m|M)
                    echo ""
                    read -p "Inserisci il nome italiano della pianta: " PLANT_NAME
                    read -p "Inserisci il nome scientifico (opzionale): " SCIENTIFIC_NAME
                    if [[ -z "$PLANT_NAME" ]]; then
                        print_warning "Nome non inserito. Foto saltata."
                        echo ""
                        continue 2
                    fi
                    CONFIRMED=1
                    ;;
                *)
                    print_warning "Scelta non valida. Usa: y, n, riprova, manuale"
                    ;;
            esac
        done
    else
        # Photo already has a plant name in filename (e.g., 01_narciso.jpg, 07_spiraea_arguta.jpg)
        # Extract plant name from filename: XX_[plant-name].ext or XX_XX_[plant-name].ext
        plant_name_with_numbers=$(echo "$photo_name" | sed 's/\.[^.]*$//')  # Remove extension
        PLANT_NAME=$(echo "$plant_name_with_numbers" | sed 's/^[0-9_]*//; s/_[0-9]*$//')  # Remove leading/trailing numbers and underscores
        
        if [[ -z "$PLANT_NAME" ]]; then
            print_warning "Could not extract plant name from: $photo_name. Skipping."
            echo ""
            continue
        fi
        
        # Query user for scientific name or skip
        print_info "Processing (named): $photo_name"
        print_info "Detected plant: $PLANT_NAME"
        read -p "Inserisci il nome scientifico (o premi Enter per saltare): " SCIENTIFIC_NAME
        
        if [[ -z "$SCIENTIFIC_NAME" ]]; then
            SCIENTIFIC_NAME=""
        fi
        echo ""
    fi
    
    # Normalize plant name to kebab-case
    PLANT_NAME=$(echo "$PLANT_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/-+/-/g' | sed 's/^-\|-$//')
    
    if [[ -z "$PLANT_NAME" ]]; then
        print_warning "Nome pianta non trovato, foto saltata."
        echo ""
        continue
    fi
    
    print_success "Identified: $PLANT_NAME"
    if [[ -n "$SCIENTIFIC_NAME" ]]; then
        print_info "Scientific name: $SCIENTIFIC_NAME"
    fi
    
    # Create plant directory structure
    PLANT_DIR="$ZONE_DIR/piante/$PLANT_NAME"
    
    if [[ -d "$PLANT_DIR" ]]; then
        print_warning "Plant directory already exists: piante/$PLANT_NAME"
        print_info "Adding photo to existing plant record"
    else
        print_info "Creating plant directory: piante/$PLANT_NAME"
        mkdir -p "$PLANT_DIR"
    fi
    
    # Determine new photo filename using the next available sequential number
    NEXT_NUM=0
    while true; do
        new_photo_name="$(printf "%02d" $NEXT_NUM)_${PLANT_NAME}.$photo_ext"
        new_photo_path="$PLANT_DIR/$new_photo_name"
        [[ ! -f "$new_photo_path" ]] && break
        (( NEXT_NUM++ ))
    done
    
    # Move the photo to the plant directory
    mv "$photo_path" "$new_photo_path"
    print_success "Photo moved to: piante/$PLANT_NAME/$new_photo_name"
    
    # Create plant markdown file if it doesn't exist
    PLANT_MD="$PLANT_DIR/${PLANT_NAME}.md"
    
    if [[ -f "$PLANT_MD" ]]; then
        print_warning "Plant documentation already exists: ${PLANT_NAME}.md"
    else
        print_info "Generating plant documentation using Copilot..."
        
        # Build the prompt for Copilot
        MARKDOWN_PROMPT="Analizza questa foto di una pianta e genera una documentazione completa.

Nome della pianta: $PLANT_NAME
Nome scientifico: $SCIENTIFIC_NAME
Zona: $ZONE_PATH

Rispondi con SOLO il markdown, nessun'altra spiegazione, usando questo template:

# $PLANT_NAME ($SCIENTIFIC_NAME)

## Informazioni generali
[Descrizione della pianta, famiglia, caratteristiche principali]

## Esposizione
- **Luce**: [ore di sole giornaliero]
- **Temperatura**: [range di temperature]
- **Umidità**: [livello di umidità preferito]

## Coltivazione
- **Terreno**: [tipo di terreno preferito]
- **Annaffiature**: [frequenza e quantità]
- **Concimazione**: [tipo e frequenza]

## Potatura e manutenzione
[Istruzioni per potatura e manutenzione stagionale]

## Parassiti e malattie
[Problemi comuni e come prevenirli]

## Fioritura
- Periodo: [mesi di fioritura]
- Colori fiori: [colori e forma]
- Forma: [descrizione della forma del fiore]

## Note sulla foto
- **Data foto**: [mese anno]
- **Stato di salute**: [descrizione dello stato]
- **Osservazioni**: [note dettagliate su quello che si vede nella foto]"
        
        # Call Copilot to generate markdown
        PLANT_MD_CONTENT=$(copilot -p "$MARKDOWN_PROMPT" 2>/dev/null)
        
        if [[ -n "$PLANT_MD_CONTENT" ]]; then
            # Filter: extract only markdown starting from the first heading (#)
            # and remove everything from "Total usage" onwards
            PLANT_MD_CONTENT=$(echo "$PLANT_MD_CONTENT" | sed -n '/^# /,/^Total usage/p' | sed '/^Total usage/d')
            
            echo "$PLANT_MD_CONTENT" > "$PLANT_MD"
            print_success "Created: ${PLANT_NAME}.md"
        else
            print_warning "Failed to generate markdown documentation"
        fi
    fi
    
    echo ""
done

print_success "Plant identification complete!"
