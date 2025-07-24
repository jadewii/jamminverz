#!/usr/bin/env python3
"""Fix corrupted Xcode project file by removing duplicates and fixing syntax"""

def fix_project_file():
    # Read the corrupted file
    with open('Todomai-iOS.xcodeproj/project.pbxproj', 'r') as f:
        content = f.read()
    
    # Replace duplicate IDs for the new files
    # First occurrence stays, second occurrence gets new ID
    replacements = [
        # DayView.swift duplicate
        ('1A0000003A0000000000001 /* DayView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 1A0000002A0000000000001 /* DayView.swift */; };',
         '1A0000011A0000000000002 /* DayView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 1A0000002A0000000000001 /* DayView.swift */; };'),
        
        # EditTaskView.swift duplicate  
        ('1A0000006A0000000000001 /* EditTaskView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 1A0000005A0000000000001 /* EditTaskView.swift */; };',
         '1A0000012A0000000000002 /* EditTaskView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 1A0000005A0000000000001 /* EditTaskView.swift */; };'),
        
        # RepeatFrequencyView.swift duplicate
        ('1A0000009A0000000000001 /* RepeatFrequencyView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 1A0000008A0000000000001 /* RepeatFrequencyView.swift */; };',
         '1A0000013A0000000000002 /* RepeatFrequencyView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 1A0000008A0000000000001 /* RepeatFrequencyView.swift */; };'),
        
        # SetRepeatTaskView ID fix
        ('1A0000012A0000000000001 /* SetRepeatTaskView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 1A0000011A0000000000001 /* SetRepeatTaskView.swift */; };',
         '1A0000014A0000000000002 /* SetRepeatTaskView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 1A0000011A0000000000001 /* SetRepeatTaskView.swift */; };'),
    ]
    
    # Find the lines with duplicate IDs and replace only the second occurrence
    lines = content.split('\n')
    seen_ids = set()
    fixed_lines = []
    
    for line in lines:
        # Check if this line contains a duplicate ID we need to fix
        fixed_line = line
        
        # Check for DayView duplicate (line ~20)
        if '1A0000003A0000000000001 /* DayView.swift in Sources */' in line and '1A0000003A0000000000001' in seen_ids:
            fixed_line = line.replace('1A0000003A0000000000001', '1A0000011A0000000000002')
        
        # Check for EditTaskView duplicate (line ~21)
        elif '1A0000006A0000000000001 /* EditTaskView.swift in Sources */' in line and '1A0000006A0000000000001' in seen_ids:
            fixed_line = line.replace('1A0000006A0000000000001', '1A0000012A0000000000002')
        
        # Check for RepeatFrequencyView duplicate (line ~22)
        elif '1A0000009A0000000000001 /* RepeatFrequencyView.swift in Sources */' in line and '1A0000009A0000000000001' in seen_ids:
            fixed_line = line.replace('1A0000009A0000000000001', '1A0000013A0000000000002')
        
        # Check for SetRepeatTaskView
        elif '1A0000012A0000000000001 /* SetRepeatTaskView.swift in Sources */' in line:
            fixed_line = line.replace('1A0000012A0000000000001', '1A0000014A0000000000002')
        
        # Track seen IDs
        if 'isa = PBXBuildFile' in line:
            id_part = line.split()[0]
            seen_ids.add(id_part)
        
        fixed_lines.append(fixed_line)
    
    # Join back and fix syntax errors
    fixed_content = '\n'.join(fixed_lines)
    
    # Fix the trailing comma and parenthesis in PBXGroup
    fixed_content = fixed_content.replace(
        '				1A0000011A0000000000001 /* SetRepeatTaskView.swift */,);',
        '				1A0000011A0000000000001 /* SetRepeatTaskView.swift */\n			);'
    )
    
    # Fix the trailing comma and parenthesis in PBXSourcesBuildPhase  
    fixed_content = fixed_content.replace(
        '				1A0000012A0000000000001 /* SetRepeatTaskView.swift in Sources */,);',
        '				1A0000014A0000000000002 /* SetRepeatTaskView.swift in Sources */\n			);'
    )
    
    # Also fix in the sources section
    seen_source_ids = set()
    final_lines = []
    for line in fixed_content.split('\n'):
        if '/* Sources */' in line and ' in Sources' in line:
            id_part = line.split()[0]
            if id_part in seen_source_ids:
                # This is a duplicate in sources section
                if 'DayView.swift in Sources' in line:
                    line = line.replace('1A0000003A0000000000001', '1A0000011A0000000000002')
                elif 'EditTaskView.swift in Sources' in line:
                    line = line.replace('1A0000006A0000000000001', '1A0000012A0000000000002')
                elif 'RepeatFrequencyView.swift in Sources' in line:
                    line = line.replace('1A0000009A0000000000001', '1A0000013A0000000000002')
            seen_source_ids.add(id_part.replace('1A0000011A0000000000002', '').replace('1A0000012A0000000000002', '').replace('1A0000013A0000000000002', '').replace('1A0000014A0000000000002', ''))
        final_lines.append(line)
    
    fixed_content = '\n'.join(final_lines)
    
    # Write the fixed file
    with open('Todomai-iOS.xcodeproj/project.pbxproj', 'w') as f:
        f.write(fixed_content)
    
    print("Project file fixed successfully!")
    print("The duplicate IDs have been replaced with unique ones.")
    print("You can now open the project in Xcode.")

if __name__ == '__main__':
    fix_project_file()