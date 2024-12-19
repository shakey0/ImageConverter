require 'mini_magick'

# Method to auto-orient a single image
def auto_orient_image(file_path)
  puts "Processing: #{file_path}"
  image = MiniMagick::Image.open(file_path)
  
  # Apply auto_orient to fix the orientation
  image.auto_orient
  
  # Overwrite the original file
  image.write(file_path)
  puts "Fixed: #{file_path}"
end

# Main script execution
def process_directory(directory)
  puts "Scanning directory: #{directory} for .webp files..."

  # Find all .webp files recursively in the directory
  Dir.glob(File.join(directory, '**', '*.webp')).each do |file|
    begin
      auto_orient_image(file)
    rescue => e
      puts "Failed to process #{file}: #{e.message}"
    end
  end

  puts "Processing complete!"
end

# Run the script in the current directory
current_directory = Dir.pwd
process_directory(current_directory)
