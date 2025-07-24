#!/bin/bash

# Script to add Swift files to Xcode project using manual editing
# This script adds DayView.swift, EditTaskView.swift, RepeatFrequencyView.swift, 
# and SetRepeatTaskView.swift to the Todomai-iOS Xcode project.

PROJECT_FILE="/Users/jade/Documents/Todomai-iOS/Todomai-iOS.xcodeproj/project.pbxproj"
BACKUP_FILE="${PROJECT_FILE}.backup"

# Check if project file exists
if [ ! -f "$PROJECT_FILE" ]; then
    echo "Error: Project file not found at $PROJECT_FILE"
    exit 1
fi

# Create backup
echo "Creating backup of project file..."
cp "$PROJECT_FILE" "$BACKUP_FILE"

# Files to add
FILES=("DayView.swift" "EditTaskView.swift" "RepeatFrequencyView.swift" "SetRepeatTaskView.swift")

# Check if files exist
echo "Checking if files exist..."
for file in "${FILES[@]}"; do
    if [ ! -f "/Users/jade/Documents/Todomai-iOS/Todomai-iOS/$file" ]; then
        echo "Error: $file not found"
        exit 1
    fi
done

echo "All files found. Proceeding with addition to Xcode project..."

# Generate unique IDs (using timestamp and random numbers)
# In a real implementation, these would need to be properly generated
# following Xcode's ID generation pattern

# For now, let's use a Python script inline to do the modification
python3 << 'EOF'
import re

project_file = "/Users/jade/Documents/Todomai-iOS/Todomai-iOS.xcodeproj/project.pbxproj"

# Read the file
with open(project_file, 'r') as f:
    content = f.read()

# Files to add with their IDs
files_data = [
    ("DayView.swift", "1A0000022A0000000000001", "1A0000011A0000000000002"),
    ("EditTaskView.swift", "1A0000023A0000000000001", "1A0000012A0000000000002"),
    ("RepeatFrequencyView.swift", "1A0000024A0000000000001", "1A0000013A0000000000002"),
    ("SetRepeatTaskView.swift", "1A0000025A0000000000001", "1A0000014A0000000000002"),
]

# Add PBXBuildFile entries
build_files_section = "/* End PBXBuildFile section */"
build_entries = []
for file_name, file_ref_id, build_file_id in files_data:
    entry = f"\t\t{build_file_id} /* {file_name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* {file_name} */; }};"
    build_entries.append(entry)

content = content.replace(build_files_section, "\n".join(build_entries) + "\n" + build_files_section)

# Add PBXFileReference entries
file_ref_section = "/* End PBXFileReference section */"
ref_entries = []
for file_name, file_ref_id, build_file_id in files_data:
    entry = f'\t\t{file_ref_id} /* {file_name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {file_name}; sourceTree = "<group>"; }};'
    ref_entries.append(entry)

content = content.replace(file_ref_section, "\n".join(ref_entries) + "\n" + file_ref_section)

# Add to PBXGroup - find the line with Styles.swift and add after it
styles_line = '\t\t\t\t1A0000021A0000000000001 /* Styles.swift */,'
group_entries = []
for file_name, file_ref_id, build_file_id in files_data:
    entry = f'\t\t\t\t{file_ref_id} /* {file_name} */,'
    group_entries.append(entry)

content = content.replace(styles_line, styles_line + "\n" + "\n".join(group_entries))

# Add to PBXSourcesBuildPhase - find the line with Styles.swift in Sources and add after it
styles_sources = '\t\t\t\t1A0000010A0000000000001 /* Styles.swift in Sources */,'
source_entries = []
for file_name, file_ref_id, build_file_id in files_data:
    entry = f'\t\t\t\t{build_file_id} /* {file_name} in Sources */,'
    source_entries.append(entry)

content = content.replace(styles_sources, styles_sources + "\n" + "\n".join(source_entries))

# Write back
with open(project_file, 'w') as f:
    f.write(content)

print("Successfully added files to Xcode project!")
EOF

echo ""
echo "Files added to Xcode project successfully!"
echo "Backup saved at: $BACKUP_FILE"
echo ""
echo "Added files:"
for file in "${FILES[@]}"; do
    echo "  - $file"
done
echo ""
echo "You can now open the project in Xcode and the files should be visible and included in the build."