#!/usr/bin/env ruby

require 'open-uri'
require 'uri'
require 'fileutils'

# Check if both URL and local file path arguments are provided
if ARGV.length != 2
  puts "Usage: 9-download_file.rb URL LOCAL_FILE_PATH"
  exit
end

# Get URL and local file path from command-line arguments
url = ARGV[0]
local_path = ARGV[1]

begin
  # Parse and validate the URL
  uri = URI.parse(url)

  # Display download message
  puts "Downloading file from #{url}..."

  # Open the URL and read its content
  URI.open(uri) do |remote_file|
    # Ensure the directory exists for the local file path
    FileUtils.mkdir_p(File.dirname(local_path))

    # Write the downloaded content to the local file
    File.open(local_path, 'wb') do |local_file|
      local_file.write(remote_file.read)
    end
  end

  # Display success message
  puts "File downloaded and saved to #{local_path}."

rescue URI::InvalidURIError
  puts "Error: Invalid URL provided."
  exit 1
rescue OpenURI::HTTPError => e
  puts "Error: HTTP error occurred - #{e.message}"
  exit 1
rescue Errno::EACCES
  puts "Error: Permission denied to write to #{local_path}."
  exit 1
rescue StandardError => e
  puts "Error: #{e.message}"
  exit 1
end
