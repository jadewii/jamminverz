#!/usr/bin/env python3
"""
Script to add Swift files to an Xcode project.pbxproj file.
This script adds DayView.swift, EditTaskView.swift, RepeatFrequencyView.swift, 
and SetRepeatTaskView.swift to the Todomai-iOS Xcode project.
"""

import re
import os
import sys
from pathlib import Path

def generate_unique_id(existing_ids, base="1A00000"):
    """Generate a unique 24-character ID for Xcode project elements."""
    # Find the highest existing ID number
    max_num = 0
    pattern = re.compile(r'1A0000(\d{3})A0000000000001')
    
    for id_str in existing_ids:
        match = pattern.match(id_str)
        if match:
            num = int(match.group(1))
            if num > max_num:
                max_num = num
    
    # Generate new ID
    new_num = max_num + 1
    return f"1A0000{new_num:03d}A0000000000001"

def extract_existing_ids(content):
    """Extract all existing IDs from the project file."""
    id_pattern = re.compile(r'[0-9A-F]{24}')
    return set(id_pattern.findall(content))

def add_files_to_xcode_project(project_path, files_to_add):
    """Add files to the Xcode project."""
    
    # Read the project file
    with open(project_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Extract existing IDs
    existing_ids = extract_existing_ids(content)
    
    # Generate unique IDs for each file
    file_refs = {}
    build_files = {}
    
    for file_name in files_to_add:
        # Generate IDs
        existing_ids.add(generate_unique_id(existing_ids))
        file_ref_id = generate_unique_id(existing_ids)
        existing_ids.add(file_ref_id)
        build_file_id = generate_unique_id(existing_ids)
        existing_ids.add(build_file_id)
        
        file_refs[file_name] = file_ref_id
        build_files[file_name] = build_file_id
    
    # 1. Add PBXBuildFile entries
    build_file_section = "/* End PBXBuildFile section */"
    build_file_entries = []
    
    for file_name in files_to_add:
        entry = f"\t\t{build_files[file_name]} /* {file_name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[file_name]} /* {file_name} */; }};"
        build_file_entries.append(entry)
    
    build_file_text = "\n".join(build_file_entries) + "\n"
    content = content.replace(build_file_section, build_file_text + build_file_section)
    
    # 2. Add PBXFileReference entries
    file_ref_section = "/* End PBXFileReference section */"
    file_ref_entries = []
    
    for file_name in files_to_add:
        entry = f'\t\t{file_refs[file_name]} /* {file_name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {file_name}; sourceTree = "<group>"; }};'
        file_ref_entries.append(entry)
    
    file_ref_text = "\n".join(file_ref_entries) + "\n"
    content = content.replace(file_ref_section, file_ref_text + file_ref_section)
    
    # 3. Add to PBXGroup (find the Todomai-iOS group and add files)
    # Find the group section for Todomai-iOS
    group_pattern = re.compile(r'(1A0000210A0000000000001 /\* Todomai-iOS \*/ = \{[^}]+children = \([^)]+)', re.DOTALL)
    match = group_pattern.search(content)
    
    if match:
        group_content = match.group(1)
        # Add file references before the closing of children array
        for file_name in files_to_add:
            group_content += f"\n\t\t\t\t{file_refs[file_name]} /* {file_name} */,"
        
        content = content.replace(match.group(1), group_content)
    
    # 4. Add to PBXSourcesBuildPhase
    source_pattern = re.compile(r'(1A0000320A0000000000001 /\* Sources \*/ = \{[^}]+files = \([^)]+)', re.DOTALL)
    match = source_pattern.search(content)
    
    if match:
        source_content = match.group(1)
        # Add build files before the closing of files array
        for file_name in files_to_add:
            source_content += f"\n\t\t\t\t{build_files[file_name]} /* {file_name} in Sources */,"
        
        content = content.replace(match.group(1), source_content)
    
    # Write the modified content back
    with open(project_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"Successfully added {len(files_to_add)} files to the Xcode project:")
    for file_name in files_to_add:
        print(f"  - {file_name}")

def main():
    # Define the files to add
    files_to_add = [
        "DayView.swift",
        "EditTaskView.swift", 
        "RepeatFrequencyView.swift",
        "SetRepeatTaskView.swift"
    ]
    
    # Path to the project file
    project_file = "/Users/jade/Documents/Todomai-iOS/Todomai-iOS.xcodeproj/project.pbxproj"
    
    # Check if project file exists
    if not os.path.exists(project_file):
        print(f"Error: Project file not found at {project_file}")
        sys.exit(1)
    
    # Check if all files exist
    project_dir = "/Users/jade/Documents/Todomai-iOS/Todomai-iOS"
    missing_files = []
    
    for file_name in files_to_add:
        file_path = os.path.join(project_dir, file_name)
        if not os.path.exists(file_path):
            missing_files.append(file_name)
    
    if missing_files:
        print("Error: The following files are missing:")
        for file_name in missing_files:
            print(f"  - {file_name}")
        sys.exit(1)
    
    # Add files to the project
    try:
        add_files_to_xcode_project(project_file, files_to_add)
        print("\nProject file updated successfully!")
        print("You can now open the project in Xcode and the files should be visible.")
    except Exception as e:
        print(f"Error updating project file: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()