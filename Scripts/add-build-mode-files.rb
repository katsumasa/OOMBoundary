#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'OOMBoundary.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'OOMBoundary' }

# Get the OOMBoundary group (folder in Xcode)
oom_group = project.main_group.groups.find { |g| g.display_name == 'OOMBoundary' }

# Files to add
files_to_add = [
  'OOMBoundary/BuildMode.swift',
  'OOMBoundary/BuildModeGenerated.swift'
]

files_to_add.each do |file_path|
  file_name = File.basename(file_path)

  # Check if file is already in the project
  existing_file = oom_group.files.find { |f| f.display_name == file_name }

  if existing_file
    puts "✓ #{file_name} already in project"
    next
  end

  # Add file reference to the group
  file_ref = oom_group.new_reference(file_path)

  # Add file to build phases (compile sources)
  target.source_build_phase.add_file_reference(file_ref)

  puts "✅ Added #{file_name} to project"
end

# Save the project
project.save

puts "✨ Project updated successfully"
