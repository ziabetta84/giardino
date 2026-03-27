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
    echo "Usage: identifyPlants zone:<zone_path>"
    echo ""
    echo "Examples:"
    echo "  ./scripts/identifyPlants.sh zone:crinale"
    echo "  ./scripts/identifyPlants.sh zone:scivolo:lato-destro"
    echo "  ./scripts/identifyPlants.sh zone:scivolo:lato-sinistro"
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

# Parse arguments
if [[ $# -ne 1 ]]; then
    usage
fi

ZONE_PARAM="$1"

# Extract zone path from parameter
if [[ ! $ZONE_PARAM =~ ^zone: ]]; then
    print_error "Parameter must start with 'zone:'"
    usage
fi

ZONE_PATH="${ZONE_PARAM#zone:}"
ZONE_PATH="${ZONE_PATH//:/\/}"

ZONE_DIR="$REPO_ROOT/zone/$ZONE_PATH"
FOTO_DIR="$ZONE_DIR/foto"

# Validate that zone directory exists
if [[ ! -d "$ZONE_DIR" ]]; then
    print_error "Zone directory not found: $ZONE_DIR"
    exit 1
fi

# Check if foto directory exists
if [[ ! -d "$FOTO_DIR" ]]; then
    print_warning "No foto directory found at: $FOTO_DIR"
    exit 0
fi

# Find all files matching the pattern "00_da_identificare.*"
UNIDENTIFIED_PHOTOS=()
while IFS= read -r -d '' file; do
    UNIDENTIFIED_PHOTOS+=("$file")
done < <(find "$FOTO_DIR" -maxdepth 1 -name "00_da_identificare.*" -print0)

if [[ ${#UNIDENTIFIED_PHOTOS[@]} -eq 0 ]]; then
    print_info "No unidentified photos found in $FOTO_DIR"
    exit 0
fi

print_info "Found ${#UNIDENTIFIED_PHOTOS[@]} unidentified photo(s) in: $ZONE_PATH"
echo ""

# Process each unidentified photo
for photo_path in "${UNIDENTIFIED_PHOTOS[@]}"; do
    photo_name=$(basename "$photo_path")
    photo_ext="${photo_name##*.}"
    
    print_info "Processing: $photo_name"
    echo ""
    print_info "Use Copilot to identify this plant. Run:"
    echo ""
    echo "  copilot -p \"Analizza questa foto di una pianta nel giardino."
    echo ""
    echo "  Identifica il nome comune italiano e il nome scientifico della pianta."
    echo ""
    echo "  Rispondi in questo formato (UNA sola riga):"
    echo "  nome_italiano|nome_scientifico"
    echo ""
    echo "  Esempi:"
    echo "  lavanda|Lavandula angustifolia\""
    echo ""
    echo "  Then paste the response below (nome_italiano|nome_scientifico):"
    
    # Read the identification from user
    read -p "Identification: " IDENTIFICATION
    
    if [[ -z "$IDENTIFICATION" ]]; then
        print_warning "No identification provided. Skipping this photo."
        echo ""
        continue
    fi
    
    # Parse the identification response
    PLANT_NAME=$(echo "$IDENTIFICATION" | cut -d'|' -f1 | xargs)
    SCIENTIFIC_NAME=$(echo "$IDENTIFICATION" | cut -d'|' -f2 | xargs)
    
    # Normalize plant name to kebab-case
    PLANT_NAME=$(echo "$PLANT_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/-+/-/g' | sed 's/^-\|-$//')
    
    if [[ -z "$PLANT_NAME" ]]; then
        print_warning "Could not parse plant name from: $IDENTIFICATION"
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
    
    # Determine new photo filename
    new_photo_name="00_${PLANT_NAME}.$photo_ext"
    new_photo_path="$PLANT_DIR/$new_photo_name"
    
    if [[ -f "$new_photo_path" ]]; then
        print_warning "Photo already exists: $new_photo_name"
    fi
    
    # Move the photo to the plant directory
    mv "$photo_path" "$new_photo_path"
    print_success "Photo moved to: piante/$PLANT_NAME/$new_photo_name"
    
    # Create plant markdown file if it doesn't exist
    PLANT_MD="$PLANT_DIR/${PLANT_NAME}.md"
    
    if [[ -f "$PLANT_MD" ]]; then
        print_warning "Plant documentation already exists: ${PLANT_NAME}.md"
        print_info "Skipping markdown generation"
    else
        print_info "Generating plant documentation using Copilot..."
        echo ""
        print_info "Run this command to generate the plant documentation:"
        echo ""
        echo "  copilot -p \"Analizza questa foto di una pianta e genera una documentazione completa."
        echo ""
        echo "  Nome della pianta: $PLANT_NAME"
        echo "  Nome scientifico: $SCIENTIFIC_NAME"
        echo "  Zona: $ZONE_PATH"
        echo ""
        echo "  Rispondi con SOLO il markdown, nessun'altra spiegazione, usando questo template:"
        echo ""
        echo "  # $PLANT_NAME ($SCIENTIFIC_NAME)"
        echo ""
        echo "  ## Informazioni generali"
        echo "  [...]"
        echo ""
        echo "  ## Esposizione"
        echo "  - **Luce**: [...]"
        echo "  - **Temperatura**: [...]"
        echo "  - **Umidità**: [...]"
        echo ""
        echo "  (continua con le altre sezioni come nei file esistenti)\""
        echo ""
        read -p "Paste the generated markdown here (or press Enter to skip): " PLANT_MD_CONTENT
        
        if [[ -n "$PLANT_MD_CONTENT" ]]; then
            echo "$PLANT_MD_CONTENT" > "$PLANT_MD"
            print_success "Created: ${PLANT_NAME}.md"
        else
            print_warning "Skipped markdown generation"
        fi
    fi
    
    echo ""
done

print_success "Plant identification complete!"
