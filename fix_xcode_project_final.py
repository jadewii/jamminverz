#!/usr/bin/env python3
"""
Final version of script to fix Xcode project file by moving misplaced Swift files 
from root level to the appropriate Jamminverz group with proper formatting.
"""

import re
import sys
from pathlib import Path


def fix_xcode_project(project_path):
    """Fix the Xcode project file by moving files to correct group."""
    
    # Read the project file
    with open(project_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    # Files to move and their IDs - these three are the main ones to move
    files_to_move = {
        'AlbumsView.swift': '0791300B2E3213240016A08A',
        'StoreView.swift': '0791300F2E3213240016A08A',
        'UnlocksView.swift': '079130112E3213240016A08A'
    }
    
    # Process line by line
    new_lines = []
    inside_root_group = False
    inside_jamminverz_group = False
    root_group_done = False
    files_added_to_jamminverz = False
    
    i = 0
    while i < len(lines):
        line = lines[i]
        
        # Check if we're entering the root group
        if 'A1B2C3C71A2B3C4D5E6F7880 = {' in line:
            inside_root_group = True
        
        # Check if we're entering the Jamminverz group
        if 'A1B2C3D21A2B3C4D5E6F7880 /* Jamminverz */ = {' in line:
            inside_jamminverz_group = True
            inside_root_group = False
        
        # If we're in the root group, skip lines that contain our files
        if inside_root_group and not root_group_done:
            # Skip the misplaced files from root
            skip = False
            for file_name, file_id in files_to_move.items():
                if file_id in line and file_name in line:
                    skip = True
                    break
            # Also skip other misplaced files
            if any(x in line for x in ['CollabsView.swift', 'FriendsView.swift', 
                                       'ProfileView.swift', 'StudioView.swift',
                                       'ArtSelectionView.swift', 'ArtStoreManager.swift',
                                       'ArtStoreView.swift', 'PaymentManager.swift']):
                skip = True
            
            if not skip:
                new_lines.append(line)
            
            # Check if we're done with the root group
            if line.strip() == ');' and inside_root_group:
                inside_root_group = False
                root_group_done = True
        
        # If we're in the Jamminverz group and haven't added files yet
        elif inside_jamminverz_group and not files_added_to_jamminverz:
            new_lines.append(line)
            
            # Look for where to insert the files (after TodayViewTimeBlocked.swift)
            if '07912F122E313DDE0016A08A /* TodayViewTimeBlocked.swift */' in line:
                # Add all the view files here with proper indentation
                new_lines.append('\t\t\t\t0791300C2E3213240016A08A /* CollabsView.swift */,\n')
                new_lines.append('\t\t\t\t0791300D2E3213240016A08A /* FriendsView.swift */,\n')
                new_lines.append('\t\t\t\t0791300E2E3213240016A08A /* ProfileView.swift */,\n')
                new_lines.append('\t\t\t\t0791300B2E3213240016A08A /* AlbumsView.swift */,\n')
                new_lines.append('\t\t\t\t0791300F2E3213240016A08A /* StoreView.swift */,\n')
                new_lines.append('\t\t\t\t079130112E3213240016A08A /* UnlocksView.swift */,\n')
                new_lines.append('\t\t\t\t079130102E3213240016A08A /* StudioView.swift */,\n')
                new_lines.append('\t\t\t\t0791301A2E321AAD0016A08A /* ArtSelectionView.swift */,\n')
                new_lines.append('\t\t\t\t0791301B2E321AAD0016A08A /* ArtStoreManager.swift */,\n')
                new_lines.append('\t\t\t\t0791301C2E321AAD0016A08A /* ArtStoreView.swift */,\n')
                new_lines.append('\t\t\t\t0791301F2E321AAD0016A08A /* PaymentManager.swift */,\n')
                files_added_to_jamminverz = True
            
            # Check if we're done with the Jamminverz group
            if line.strip() == '};' and inside_jamminverz_group:
                inside_jamminverz_group = False
        
        # For all other lines, check if they contain duplicate entries we need to skip
        else:
            skip = False
            # Skip any duplicate entries that might exist elsewhere
            if files_added_to_jamminverz:
                for file_name in ['CollabsView.swift', 'FriendsView.swift', 'ProfileView.swift',
                                 'AlbumsView.swift', 'StoreView.swift', 'UnlocksView.swift',
                                 'StudioView.swift', 'ArtSelectionView.swift', 'ArtStoreManager.swift',
                                 'ArtStoreView.swift', 'PaymentManager.swift']:
                    if file_name in line and any(id in line for id in ['0791300B', '0791300C', '0791300D', 
                                                                       '0791300E', '0791300F', '079130', '0791301']):
                        # Check if this line has bad indentation
                        if line.startswith('\t\t\t\t\t') or not line.startswith('\t\t\t\t'):
                            skip = True
                            break
            
            if not skip:
                new_lines.append(line)
        
        i += 1
    
    # Write the fixed content
    content = ''.join(new_lines)
    
    # Fix file references to have correct paths
    content = re.sub(r'path = Jamminverz/(ArtSelectionView|ArtStoreManager|ArtStoreView|PaymentManager)\.swift;', 
                     r'path = \1.swift;', content)
    
    with open(project_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("Successfully fixed the Xcode project file!")
    print("All Swift view files have been properly organized in the Jamminverz group.")
    
    return True


def main():
    """Main function."""
    project_file = "/Users/jade/SunoMusicPipeline/jamminverz/Jamminverz.xcodeproj/project.pbxproj"
    
    if not Path(project_file).exists():
        print(f"Error: Project file not found at {project_file}")
        sys.exit(1)
    
    # Restore from backup first
    backup_file = project_file + '.backup'
    if Path(backup_file).exists():
        print("Restoring from backup first...")
        with open(backup_file, 'r', encoding='utf-8') as f:
            backup_content = f.read()
        with open(project_file, 'w', encoding='utf-8') as f:
            f.write(backup_content)
    
    if fix_xcode_project(project_file):
        print("\nProject file has been fixed successfully!")
        print("You can now open the project in Xcode and the files should be in the correct location.")
    else:
        print("\nError: Failed to fix the project file")
        sys.exit(1)


if __name__ == "__main__":
    main()