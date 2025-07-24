#!/usr/bin/env ruby

# Manual Ruby script to add files to Xcode project
# This mimics the behavior of the xcodeproj gem without requiring installation

require 'fileutils'
require 'securerandom'

class XcodeProjectUpdater
  def initialize(project_path)
    @project_path = project_path
    @pbxproj_path = File.join(project_path, 'project.pbxproj')
    
    unless File.exist?(@pbxproj_path)
      raise "Project file not found at #{@pbxproj_path}"
    end
    
    @content = File.read(@pbxproj_path)
  end
  
  def add_files(files, group_name = "Todomai-iOS")
    # Create backup
    backup_path = @pbxproj_path + '.backup'
    FileUtils.cp(@pbxproj_path, backup_path)
    puts "Created backup at: #{backup_path}"
    
    # Generate IDs for each file
    file_data = files.map do |file_name|
      {
        name: file_name,
        file_ref_id: generate_uuid,
        build_file_id: generate_uuid
      }
    end
    
    # Add PBXFileReference entries
    add_file_references(file_data)
    
    # Add PBXBuildFile entries
    add_build_files(file_data)
    
    # Add to PBXGroup
    add_to_group(file_data, group_name)
    
    # Add to PBXSourcesBuildPhase
    add_to_sources_phase(file_data)
    
    # Save the file
    File.write(@pbxproj_path, @content)
    
    puts "\nSuccessfully added #{files.length} files to Xcode project:"
    files.each { |f| puts "  - #{f}" }
  end
  
  private
  
  def generate_uuid
    # Generate a 24-character hex string similar to Xcode's format
    # Using pattern similar to existing IDs in the project
    base = "1A0000"
    middle = rand(100..999).to_s
    suffix = "A0000000000001"
    
    # Ensure uniqueness by checking if ID already exists
    id = base + middle + suffix
    while @content.include?(id)
      middle = rand(100..999).to_s
      id = base + middle + suffix
    end
    
    id
  end
  
  def add_file_references(file_data)
    section_end = "/* End PBXFileReference section */"
    
    entries = file_data.map do |data|
      "\t\t#{data[:file_ref_id]} /* #{data[:name]} */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = #{data[:name]}; sourceTree = \"<group>\"; };"
    end
    
    @content.sub!(section_end, entries.join("\n") + "\n" + section_end)
  end
  
  def add_build_files(file_data)
    section_end = "/* End PBXBuildFile section */"
    
    entries = file_data.map do |data|
      "\t\t#{data[:build_file_id]} /* #{data[:name]} in Sources */ = {isa = PBXBuildFile; fileRef = #{data[:file_ref_id]} /* #{data[:name]} */; };"
    end
    
    @content.sub!(section_end, entries.join("\n") + "\n" + section_end)
  end
  
  def add_to_group(file_data, group_name)
    # Find the group and add files to children
    # Looking for the pattern where Styles.swift is listed
    styles_pattern = /(\t\t\t\t1A0000021A0000000000001 \/\* Styles\.swift \*\/,)/
    
    if match = @content.match(styles_pattern)
      entries = file_data.map do |data|
        "\t\t\t\t#{data[:file_ref_id]} /* #{data[:name]} */,"
      end
      
      replacement = match[1] + "\n" + entries.join("\n")
      @content.sub!(match[1], replacement)
    else
      puts "Warning: Could not find insertion point for group entries"
    end
  end
  
  def add_to_sources_phase(file_data)
    # Find the sources build phase and add files
    # Looking for the pattern where Styles.swift is in Sources
    styles_pattern = /(\t\t\t\t1A0000010A0000000000001 \/\* Styles\.swift in Sources \*\/,)/
    
    if match = @content.match(styles_pattern)
      entries = file_data.map do |data|
        "\t\t\t\t#{data[:build_file_id]} /* #{data[:name]} in Sources */,"
      end
      
      replacement = match[1] + "\n" + entries.join("\n")
      @content.sub!(match[1], replacement)
    else
      puts "Warning: Could not find insertion point for source entries"
    end
  end
end

# Main execution
if __FILE__ == $0
  project_path = "/Users/jade/Documents/Todomai-iOS/Todomai-iOS.xcodeproj"
  files_to_add = [
    "DayView.swift",
    "EditTaskView.swift",
    "RepeatFrequencyView.swift",
    "SetRepeatTaskView.swift"
  ]
  
  begin
    updater = XcodeProjectUpdater.new(project_path)
    updater.add_files(files_to_add)
    puts "\nProject updated successfully!"
    puts "You can now open the project in Xcode and the files should be visible."
  rescue => e
    puts "Error: #{e.message}"
    exit 1
  end
end