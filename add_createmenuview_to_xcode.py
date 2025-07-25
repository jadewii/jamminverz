#!/usr/bin/env python3
"""
Script to add CreateMenuView.swift to the Jamminverz Xcode project.
"""

import re
import os
import sys
from pathlib import Path
import shutil
import uuid

def generate_xcode_id():
    """Generate a unique 24-character hex ID for Xcode project elements."""
    # Generate a random UUID and convert to hex string
    unique_id = uuid.uuid4().hex[:24].upper()
    return unique_id

def add_createmenuview_to_project(project_path):
    """Add CreateMenuView.swift to the Xcode project."""
    
    # First create a backup
    backup_path = project_path + '.backup_createmenu'
    shutil.copy2(project_path, backup_path)
    print(f"Created backup at: {backup_path}")
    
    # Read the project file
    with open(project_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Generate unique IDs for CreateMenuView
    file_ref_id = generate_xcode_id()
    build_file_id = generate_xcode_id()
    
    print(f"Generated IDs:")
    print(f"  File Reference ID: {file_ref_id}")
    print(f"  Build File ID: {build_file_id}")
    
    # 1. Add PBXBuildFile entry
    build_file_section = "/* End PBXBuildFile section */"
    build_file_entry = f"\t\t{build_file_id} /* CreateMenuView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* CreateMenuView.swift */; }};\n"
    content = content.replace(build_file_section, build_file_entry + build_file_section)
    
    # 2. Add PBXFileReference entry
    file_ref_section = "/* End PBXFileReference section */"
    file_ref_entry = f'\t\t{file_ref_id} /* CreateMenuView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = CreateMenuView.swift; sourceTree = "<group>"; }};\n'
    content = content.replace(file_ref_section, file_ref_entry + file_ref_section)
    
    # 3. Add to PBXGroup (find the Jamminverz group and add file after CreateView.swift)
    # Look for CreateView.swift and add CreateMenuView.swift right after it
    create_view_pattern = re.compile(r'(\t\t\t\tA1B2C3FF1A2B3C4D5E6F78B5 /\* CreateView\.swift \*/,)\n')
    match = create_view_pattern.search(content)
    
    if match:
        # Add CreateMenuView.swift after CreateView.swift
        replacement = match.group(1) + f'\n\t\t\t\t{file_ref_id} /* CreateMenuView.swift */,'
        content = content.replace(match.group(0), replacement + '\n')
        print("Added CreateMenuView.swift to Jamminverz group")
    else:
        print("Warning: Could not find CreateView.swift in group, adding at end of group")
        # Alternative: find the Jamminverz group and add at the end
        group_pattern = re.compile(r'(A1B2C3D21A2B3C4D5E6F7880 /\* Jamminverz \*/ = \{[^}]+children = \([^)]+)\n(\t+\);)', re.DOTALL)
        match = group_pattern.search(content)
        if match:
            group_content = match.group(1)
            closing = match.group(2)
            # Add file reference before the closing
            new_content = group_content + f',\n\t\t\t\t{file_ref_id} /* CreateMenuView.swift */\n' + closing
            content = content.replace(match.group(0), new_content)
    
    # 4. Add to PBXSourcesBuildPhase (add after CreateView.swift in build phase)
    create_view_build_pattern = re.compile(r'(\t\t\t\tA1B2C4001A2B3C4D5E6F78B5 /\* CreateView\.swift in Sources \*/,)\n')
    match = create_view_build_pattern.search(content)
    
    if match:
        # Add CreateMenuView.swift after CreateView.swift in build phase
        replacement = match.group(1) + f'\n\t\t\t\t{build_file_id} /* CreateMenuView.swift in Sources */,'
        content = content.replace(match.group(0), replacement + '\n')
        print("Added CreateMenuView.swift to Sources build phase")
    else:
        print("Warning: Could not find CreateView.swift in build phase, adding at end")
        # Alternative: find the Sources build phase and add at the end
        source_pattern = re.compile(r'(A1B2C3CC1A2B3C4D5E6F7880 /\* Sources \*/ = \{[^}]+files = \([^)]+)\n(\t+\);)', re.DOTALL)
        match = source_pattern.search(content)
        if match:
            source_content = match.group(1)
            closing = match.group(2)
            # Add build file before the closing
            new_content = source_content + f',\n\t\t\t\t{build_file_id} /* CreateMenuView.swift in Sources */\n' + closing
            content = content.replace(match.group(0), new_content)
    
    # Write the modified content back
    with open(project_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("\nSuccessfully added CreateMenuView.swift to the Xcode project!")
    return True

def main():
    """Main function."""
    # Path to the project file
    project_file = "/Users/jade/SunoMusicPipeline/jamminverz/Jamminverz.xcodeproj/project.pbxproj"
    
    # Check if project file exists
    if not os.path.exists(project_file):
        print(f"Error: Project file not found at {project_file}")
        sys.exit(1)
    
    # Check if CreateMenuView.swift exists
    swift_file = "/Users/jade/SunoMusicPipeline/jamminverz/Jamminverz/CreateMenuView.swift"
    if not os.path.exists(swift_file):
        print(f"Error: CreateMenuView.swift not found at {swift_file}")
        sys.exit(1)
    
    print("Adding CreateMenuView.swift to Xcode project...")
    print(f"Project file: {project_file}")
    print(f"Swift file: {swift_file}")
    
    try:
        if add_createmenuview_to_project(project_file):
            print("\nProject file updated successfully!")
            print("You can now open the project in Xcode and CreateMenuView.swift should be visible.")
            print("\nNext steps:")
            print("1. Open Jamminverz.xcodeproj in Xcode")
            print("2. Verify CreateMenuView.swift appears in the project navigator")
            print("3. Build the project to ensure it compiles correctly")
        else:
            print("\nError: Failed to update the project file")
            sys.exit(1)
    except Exception as e:
        print(f"\nError updating project file: {str(e)}")
        print("The backup has been preserved. You can restore it if needed.")
        sys.exit(1)

if __name__ == "__main__":
    main()