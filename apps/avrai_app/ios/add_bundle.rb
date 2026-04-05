require 'xcodeproj'

project_path = 'Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.find { |t| t.name == 'Runner' }

# Path to the bundle folder
bundle_path = 'dist/bundle'

# Create a file reference for the bundle (as a folder reference)
group = project.main_group.find_subpath('Runner', true)
file_ref = group.new_reference(bundle_path)
file_ref.last_known_file_type = 'folder'

# Find the "Copy Bundle Resources" build phase
resources_build_phase = target.resources_build_phase

# Check if it's already there
unless resources_build_phase.files_references.include?(file_ref)
  build_file = resources_build_phase.add_file_reference(file_ref)
  puts "Added dist/bundle to Copy Bundle Resources."
else
  puts "dist/bundle is already in Copy Bundle Resources."
end

project.save
