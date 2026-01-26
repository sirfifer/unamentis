#!/usr/bin/env ruby
# Script to add Pocket TTS models to Xcode project
# Run from project root: ruby scripts/setup_pocket_tts_models.rb

require 'xcodeproj'

PROJECT_PATH = 'UnaMentis.xcodeproj'
TARGET_NAME = 'UnaMentis'

# Model directory to add as a folder reference (preserves directory structure)
MODEL_DIR = 'models/Models'

def main
  puts "Opening Xcode project..."
  project = Xcodeproj::Project.open(PROJECT_PATH)
  target = project.targets.find { |t| t.name == TARGET_NAME }

  unless target
    puts "Error: Target '#{TARGET_NAME}' not found"
    exit 1
  end

  main_group = project.main_group

  # Find or create Models group in project
  models_group = main_group.groups.find { |g| g.name == 'Models' }
  unless models_group
    models_group = main_group.new_group('Models')
    puts "\nCreated 'Models' group in project"
  end

  # Check if Models directory is already added
  existing = models_group.files.find { |f| f.name == 'Models' || f.path&.include?('models/Models') }
  existing ||= models_group.groups.find { |g| g.name == 'Models' && g.path&.include?('models/Models') }

  if existing
    puts "\nModels directory already in project"
  else
    # Add Models as a folder reference to preserve structure
    puts "\nAdding Pocket TTS Models directory..."

    model_path = File.expand_path(MODEL_DIR)
    unless File.directory?(model_path)
      puts "Error: Model directory not found at #{model_path}"
      exit 1
    end

    # Add as folder reference (this keeps the directory structure intact in the bundle)
    folder_ref = models_group.new_reference(MODEL_DIR, :group)
    folder_ref.name = 'Models'
    folder_ref.source_tree = 'SOURCE_ROOT'
    folder_ref.path = MODEL_DIR

    puts "  Added folder reference: Models"
  end

  # Add to Copy Bundle Resources
  puts "\nAdding to Copy Bundle Resources..."
  resources_phase = target.resources_build_phase

  # Find the folder reference we just added (or already exists)
  folder_ref = models_group.files.find { |f| f.path&.include?('models/Models') }
  folder_ref ||= models_group.groups.find { |g| g.path&.include?('models/Models') }

  if folder_ref
    # Check if already in resources phase
    already_in_resources = resources_phase.files.any? do |f|
      f.file_ref&.path&.include?('models/Models')
    end

    if already_in_resources
      puts "  Models already in Copy Bundle Resources"
    else
      resources_phase.add_file_reference(folder_ref)
      puts "  Added Models to Copy Bundle Resources"
    end
  else
    puts "  Warning: Could not find Models reference to add to resources"
  end

  # Save project
  puts "\nSaving project..."
  project.save
  puts "Done!"
  puts "\nPocket TTS models will now be bundled with the app."
  puts "Total size: ~229MB"
end

main
