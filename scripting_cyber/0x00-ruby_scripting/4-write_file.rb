#!/usr/bin/env ruby

# Import json module to read, parse and write JSON files
require 'json'

def merge_json_files(file1_path, file2_path)
  # Read and parse the first JSON file into a Ruby array/hash
  data1 = JSON.parse(File.read(file1_path))

  # Read and parse the second JSON file into a Ruby array/hash
  data2 = JSON.parse(File.read(file2_path))

  # Check if data is arrays or hashes and merge accordingly
  if data1.is_a?(Array) && data2.is_a?(Array)
    # Concatenate arrays (data2 first, then data1)
    merged_data = data2 + data1
  elsif data1.is_a?(Hash) && data2.is_a?(Hash)
    # Merge hashes (data2 is overridden by data1 if keys conflict)
    merged_data = data2.merge(data1)
  else
    # If types don't match, just concatenate or merge what we can
    merged_data = data2 + data1
  end

  # Open file2 in write mode ('w' = overwrite)
  File.open(file2_path, 'w') do |f|
    # Write the merged data as formatted JSON (with indentation)
    f.write(JSON.pretty_generate(merged_data))
  end

  # Display confirmation message
  puts "Merged JSON written to #{file2_path}"
end
