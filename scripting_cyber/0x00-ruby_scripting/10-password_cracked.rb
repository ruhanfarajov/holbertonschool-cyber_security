#!/usr/bin/env ruby

require 'digest'

# Check if both hashed password and dictionary file arguments are provided
if ARGV.length != 2
  puts "Usage: 10-password_cracked.rb HASHED_PASSWORD DICTIONARY_FILE"
  exit
end

# Get hashed password and dictionary file path from command-line arguments
hashed_password = ARGV[0]
dictionary_file = ARGV[1]

# Check if dictionary file exists
unless File.exist?(dictionary_file)
  puts "Error: Dictionary file '#{dictionary_file}' not found."
  exit 1
end

# Read the dictionary file and try to crack the password
password_found = false

File.open(dictionary_file, 'r') do |file|
  file.each_line do |line|
    # Remove trailing newline/whitespace from each word
    word = line.strip

    # Hash the word using SHA-256
    word_hash = Digest::SHA256.hexdigest(word)

    # Compare with the provided hash
    if word_hash == hashed_password
      puts "Password found: #{word}"
      password_found = true
      break
    end
  end
end

# If no match was found in the dictionary
unless password_found
  puts "Password not found in dictionary."
end
