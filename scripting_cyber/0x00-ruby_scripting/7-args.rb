#!/usr/bin/env ruby

# Function that prints command-line arguments
# ARGV is a special Ruby array containing all command-line arguments
def print_arguments
  # Check if no arguments were provided
  if ARGV.empty?
    puts "No arguments provided."
  else
    # Loop through each argument and print it
    ARGV.each do |arg|
      puts arg
    end
  end
end
