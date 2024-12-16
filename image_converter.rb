require 'mini_magick'
require 'securerandom'

def sanitize_filename(filename)
  base_name = File.basename(filename, ".*")
  sanitized = base_name.gsub(/[^a-zA-Z0-9_-]/, '')
  random_suffix = SecureRandom.alphanumeric(10)
  "#{sanitized}_#{random_suffix}.webp"
end

def format_size(size_in_bytes)
  (size_in_bytes / 1024.0).round(2)
end

def file_size_ok?(file_path, max_size_kb)
  File.size(file_path).to_f / 1024 <= max_size_kb
end

def compress_image(input_path, output_path, max_size_kb = 200)
  input_size = format_size(File.size(input_path))
  puts "Input image size: #{input_size}KB"

  image = MiniMagick::Image.open(input_path)
  original_dimensions = "#{image.width}x#{image.height}"
  puts "Original dimensions: #{original_dimensions}"

  image.format 'webp'

  # Initial size check
  if file_size_ok?(input_path, max_size_kb)
    image.write output_path
    output_size = format_size(File.size(output_path))
    puts "Image already under target size. Simply converted to WebP."
    puts "Output image size: #{output_size}KB"
    puts "Size change: #{(output_size - input_size).round(2)}KB (#{((output_size - input_size) / input_size * 100).round(2)}%)"
    return
  end

  # Initial resize if dimensions are too large
  if image.width > 1920 || image.height > 1080
    puts "Image exceeds 1920x1080, resizing..."
    image.resize '1920x1080>'  # '>' means it will only shrink, never enlarge
    image.write output_path
    puts "Resized to: #{image.width}x#{image.height}"
    
    # Check if resize was enough to meet size requirement
    if file_size_ok?(output_path, max_size_kb)
      output_size = format_size(File.size(output_path))
      puts "After resize, image is under target size."
      puts "Output image size: #{output_size}KB"
      puts "Size change: #{(output_size - input_size).round(2)}KB (#{((output_size - input_size) / input_size * 100).round(2)}%)"
      return
    end
  end

  # Reduce quality until file size is within target or quality hits 50
  quality = 90
  while quality >= 50 && !file_size_ok?(output_path, max_size_kb)
    image.quality quality
    image.write output_path
    puts "Trying quality: #{quality}%, size: #{format_size(File.size(output_path))}KB"
    quality -= 10
  end

  # If still too large, alternate between resizing and quality reduction
  while !file_size_ok?(output_path, max_size_kb) && quality > 10
    # Reduce dimensions by 10%
    current_width = image.width
    current_height = image.height
    new_width = (current_width * 0.95).to_i
    new_height = (current_height * 0.95).to_i
    
    # Don't resize if images would become too small
    if new_width < 100 || new_height < 100
      break
    end
    
    image.resize "#{new_width}x#{new_height}"
    puts "Resized to: #{new_width}x#{new_height}"
    
    # Try current quality with new size
    image.quality quality
    image.write output_path
    puts "Trying quality: #{quality}% at new size, size: #{format_size(File.size(output_path))}KB"
    
    # If still too large, reduce quality by 5
    if !file_size_ok?(output_path, max_size_kb)
      quality -= 5
    end
  end

  output_size = format_size(File.size(output_path))
  puts "\nFinal results:"
  puts "Original dimensions: #{original_dimensions}"
  puts "Final dimensions: #{image.width}x#{image.height}"
  puts "Input size: #{input_size}KB"
  puts "Output size: #{output_size}KB"
  puts "Size change: #{(output_size - input_size).round(2)}KB (#{((output_size - input_size) / input_size * 100).round(2)}%)"
  puts "Final quality: #{quality}"
end

if ARGV.empty?
  puts "Usage: #{$0} <image_filename>"
  exit 1
end

input_filename = ARGV[0]

unless File.exist?(input_filename)
  puts "Error: File '#{input_filename}' not found"
  exit 1
end

output_filename = sanitize_filename(input_filename)

begin
  compress_image(input_filename, output_filename)
  puts "Successfully processed image: #{output_filename}"
rescue => e
  puts "Error processing image: #{e.message}"
  exit 1
end
