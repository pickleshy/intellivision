#!/bin/bash
# new-intv-project.sh - Create a new IntyBASIC project
# Usage: ./new-intv-project.sh project_name

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 project_name"
    echo "Example: $0 space_shooter"
    exit 1
fi

PROJECT_NAME="$1"
PROJECT_DIR="$PROJECT_NAME"

# Get the directory where this script lives (the harness)
HARNESS_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -d "$PROJECT_DIR" ]; then
    echo "Error: Directory '$PROJECT_DIR' already exists"
    exit 1
fi

echo "Creating new IntyBASIC project: $PROJECT_NAME"

# Create project structure
mkdir -p "$PROJECT_DIR"/{src,build,assets,lib}

# Copy CLAUDE.md
cp "$HARNESS_DIR/CLAUDE.md" "$PROJECT_DIR/"

# Copy and customize build script
sed "s/PROJECT_NAME=\"game\"/PROJECT_NAME=\"$PROJECT_NAME\"/" "$HARNESS_DIR/build.sh" > "$PROJECT_DIR/build.sh"
chmod +x "$PROJECT_DIR/build.sh"

# Copy starter template
cp "$HARNESS_DIR/src/main.bas" "$PROJECT_DIR/src/main.bas"

# Update project name in main.bas
sed -i.bak "s/PROJECT_NAME/$PROJECT_NAME/g" "$PROJECT_DIR/src/main.bas"
rm -f "$PROJECT_DIR/src/main.bas.bak"

# Create .gitignore
cat > "$PROJECT_DIR/.gitignore" << 'EOF'
# Build artifacts
build/*.asm
build/*.rom
build/*.lst
build/*.cfg
build/*.bin

# macOS
.DS_Store

# Editor
*.swp
*.swo
*~

# IDE
.vscode/
.idea/
EOF

# Create README
cat > "$PROJECT_DIR/README.md" << EOF
# $PROJECT_NAME

An Intellivision game built with IntyBASIC.

## Building

\`\`\`bash
./build.sh        # Compile only
./build.sh run    # Compile and run in emulator
\`\`\`

## Project Structure

- \`src/\` - IntyBASIC source files
- \`build/\` - Compiled output (ROM, ASM, listing)
- \`assets/\` - Graphics and sound source files
- \`lib/\` - Shared libraries and includes

## Requirements

- IntyBASIC compiler
- AS1600 assembler (from jzintv)
- jzintv emulator
- Intellivision BIOS files (exec.bin, grom.bin)

## Resources

- [IntyBASIC Manual](https://github.com/nanochess/IntyBASIC/blob/master/manual.txt)
- [AtariAge Intellivision Programming](https://atariage.com/forums/forum/144-intellivision-programming/)
EOF

echo ""
echo "✓ Project created: $PROJECT_DIR/"
echo ""
echo "Next steps:"
echo "  cd $PROJECT_DIR"
echo "  ./build.sh run"
echo ""
