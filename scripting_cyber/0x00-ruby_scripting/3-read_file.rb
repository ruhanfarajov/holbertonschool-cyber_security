#!/usr/bin/env ruby

# Import json module to read and parse JSON files
require 'json'

def count_user_ids(path)
  # Read the entire file content as a string
  file = File.read(path)

  # Parse the JSON string into a Ruby array/hash
  data = JSON.parse(file)

  # Create a hash to count posts per user (default value is 0)
  user_count = Hash.new(0)

  # Loop through each post in the data array
  data.each do |post|
    # Increment the count for this user's ID
    user_count[post['userId']] += 1
  end

  # Sort the hash by user_id and display each user with their post count
  user_count.sort.each do |user_id, count|
    puts "#{user_id}: #{count}"
  end
end
