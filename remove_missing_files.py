#!/usr/bin/env python3
"""Remove references to missing files from Xcode project"""

def clean_project():
    # Files that are causing errors (from Shared folders)
    files_to_remove = [
        'TaskListModel.swift',
        'TaskStoreBase.swift', 
        'TaskStore_iOS.swift'
    ]
    
    with open('Todomai-iOS.xcodeproj/project.pbxproj', 'r') as f:
        content = f.read()
    
    lines = content.split('\n')
    cleaned_lines = []
    skip_line = False
    
    for line in lines:
        # Check if this line references one of the missing files
        should_skip = False
        for filename in files_to_remove:
            if filename in line:
                should_skip = True
                break
        
        if not should_skip:
            cleaned_lines.append(line)
    
    # Write cleaned content
    with open('Todomai-iOS.xcodeproj/project.pbxproj', 'w') as f:
        f.write('\n'.join(cleaned_lines))
    
    print("Removed references to missing Shared folder files")
    print("The project should now build without errors")

if __name__ == '__main__':
    clean_project()