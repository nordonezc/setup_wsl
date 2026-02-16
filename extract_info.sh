#!/bin/bash

# --- ENTRADA DE RUTA ---
echo "➡️ Introduce la ruta completa del proyecto:"
read -r PROJECT_PATH

# Sustitución de ~ manual para evitar errores de bash/dash
if [[ "$PROJECT_PATH" == "~"* ]]; then
    PROJECT_PATH="${PROJECT_PATH/~/$HOME}"
fi

if [ ! -d "$PROJECT_PATH" ]; then
    echo "❌ Error: La ruta no existe o no es un directorio: $PROJECT_PATH"
    exit 1
fi

cd "$PROJECT_PATH" || exit 1
OUTPUT_FILE="project_audit_$(date +%Y%m%d_%H%M%S).txt"
> "$OUTPUT_FILE"

# --- CONSTRUCCIÓN DINÁMICA DE EXCLUSIONES ---
EXCLUDES=()
if [ -f ".gitignore" ]; then
    while IFS= read -r line; do
        # Ignorar comentarios, líneas vacías y archivos con '!' (negaciones)
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ -z "$line" ]] && continue
        [[ "$line" == "!"* ]] && continue
        
        # Limpiar patrones para que find los entienda
        clean_pattern=$(echo "$line" | sed 's/^\///;s/\/$//;s/\*/.*/g')
        EXCLUDES+=( -not -path "*/$clean_pattern*" )
    done < .gitignore
else
    EXCLUDES=( -not -path "*/node_modules*" -not -path "*/.git*" )
fi

echo "===============================================" >> "$OUTPUT_FILE"
echo "AUDITORÍA DINÁMICA: $(basename "$PROJECT_PATH")" >> "$OUTPUT_FILE"
echo "===============================================" >> "$OUTPUT_FILE"

# --- 1. ESTRUCTURA ---
echo -e "\n[1] ESTRUCTURA DE PROYECTO" >> "$OUTPUT_FILE"
find . -maxdepth 4 "${EXCLUDES[@]}" -not -path '*/.*' | sed -e "s/[^-][^\/]*\// |/g" -e "s/|\([^ ]\)/|-\1/" >> "$OUTPUT_FILE"

# --- 2. ARCHIVOS DE CONFIGURACIÓN ---
echo -e "\n[2] ARCHIVOS DE CONFIGURACIÓN" >> "$OUTPUT_FILE"
CONFIG_FILES=("package.json" "angular.json" ".angular-cli.json" "angular-cli.json" "tsconfig.json")

for file in "${CONFIG_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "\n--- FILE: $file ---" >> "$OUTPUT_FILE"
        cat "$file" >> "$OUTPUT_FILE"
    fi
done

# --- 3. MUESTRA DE CÓDIGO ---
if [ -d "src" ]; then
    echo -e "\n[3] MUESTRA DE CÓDIGO (src)" >> "$OUTPUT_FILE"
    find src -maxdepth 2 "${EXCLUDES[@]}" \( -name "*.ts" -o -name "*.js" -o -name "*.html" \) 2>/dev/null | while read -r src_file; do
        echo -e "\n--- SRC_FILE: $src_file ---" >> "$OUTPUT_FILE"
        head -n 50 "$src_file" >> "$OUTPUT_FILE"
    done
fi

echo "✅ Extracción finalizada: $OUTPUT_FILE"