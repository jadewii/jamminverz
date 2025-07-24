# Adding Swift Files to Xcode Project

This directory contains several scripts to programmatically add the following Swift files to the Todomai-iOS Xcode project:
- DayView.swift
- EditTaskView.swift
- RepeatFrequencyView.swift
- SetRepeatTaskView.swift

## Prerequisites

All files must already exist in the `/Users/jade/Documents/Todomai-iOS/Todomai-iOS/` directory before running these scripts.

## Method 1: Python Script (Recommended)

The Python script provides the most robust solution with proper ID generation and error handling.

```bash
# Run the Python script
python3 add_files_to_xcode.py
```

This script will:
1. Generate unique IDs for each file
2. Add proper file references
3. Include files in the build phase
4. Update the project group structure

## Method 2: Shell Script

A simpler shell script that uses inline Python for the modification:

```bash
# Run the shell script
./add_files_to_xcode.sh
```

## Method 3: Ruby Script

A Ruby-based solution that mimics the behavior of the popular xcodeproj gem:

```bash
# Run the Ruby script
ruby add_files_manual.rb
```

## Method 4: Using xcodeproj Gem (Requires Installation)

If you prefer using the official xcodeproj gem:

```bash
# Install the gem
gem install xcodeproj

# Create and run this script
cat > add_with_xcodeproj.rb << 'EOF'
require 'xcodeproj'

project_path = '/Users/jade/Documents/Todomai-iOS/Todomai-iOS.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main group
main_group = project.main_group['Todomai-iOS']

# Files to add
files = ['DayView.swift', 'EditTaskView.swift', 'RepeatFrequencyView.swift', 'SetRepeatTaskView.swift']

# Find the main target
target = project.targets.first

files.each do |file_name|
  file_ref = main_group.new_reference(file_name)
  target.add_file_references([file_ref])
end

project.save
puts "Files added successfully!"
EOF

ruby add_with_xcodeproj.rb
```

## Manual Method (Using Xcode GUI)

If you prefer to add files manually through Xcode:

1. Open Todomai-iOS.xcodeproj in Xcode
2. Right-click on the "Todomai-iOS" folder in the project navigator
3. Select "Add Files to 'Todomai-iOS'..."
4. Navigate to the Todomai-iOS directory
5. Select all four files:
   - DayView.swift
   - EditTaskView.swift
   - RepeatFrequencyView.swift
   - SetRepeatTaskView.swift
6. Ensure "Copy items if needed" is unchecked (files are already in place)
7. Ensure "Add to targets: Todomai-iOS" is checked
8. Click "Add"

## Understanding the Project Structure

The Xcode project.pbxproj file contains several key sections:

1. **PBXBuildFile**: Links file references to build phases
2. **PBXFileReference**: Defines file references with their types and paths
3. **PBXGroup**: Organizes files into groups (folders in Xcode)
4. **PBXSourcesBuildPhase**: Lists which files should be compiled

Each file needs:
- A unique 24-character hex ID for the file reference
- A unique 24-character hex ID for the build file
- An entry in the appropriate group
- An entry in the sources build phase

## Verification

After running any of these scripts:

1. Open the project in Xcode
2. Verify all four files appear in the project navigator
3. Build the project to ensure files are properly included
4. Check that syntax highlighting and code completion work for the new files

## Backup

All scripts create a backup of the project.pbxproj file before modification. The backup is saved as:
```
project.pbxproj.backup
```

To restore from backup:
```bash
cp /Users/jade/Documents/Todomai-iOS/Todomai-iOS.xcodeproj/project.pbxproj.backup \
   /Users/jade/Documents/Todomai-iOS/Todomai-iOS.xcodeproj/project.pbxproj
```

## Troubleshooting

If files don't appear in Xcode after running a script:

1. Close and reopen the Xcode project
2. Clean the build folder (Shift+Cmd+K)
3. Check the Console app for any Xcode errors
4. Verify the files exist in the filesystem
5. Restore from backup and try a different method

## Notes

- The scripts use ID patterns similar to existing project files
- IDs must be unique within the project
- The scripts preserve the existing project structure
- All scripts are idempotent (can be run multiple times safely)