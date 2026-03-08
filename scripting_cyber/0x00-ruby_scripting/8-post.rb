#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'json'

# Function that performs an HTTP POST request to the specified URL
# with body parameters and prints the response status and body
def post_request(url, body_params)
  # Parse the URL
  uri = URI(url)

  # Create an HTTP object
  http = Net::HTTP.new(uri.host, uri.port)

  # Set to use SSL if the URL uses HTTPS
  http.use_ssl = (uri.scheme == 'https')

  # Create a POST request
  request = Net::HTTP::Post.new(uri.request_uri)

  # Set the Content-Type header to JSON
  request['Content-Type'] = 'application/json'

  # Convert body_params to JSON and set as request body
  request.body = body_params.to_json

  # Send the request and get the response
  response = http.request(request)

  # Print the response status
  puts "Response status: #{response.code} #{response.message}"

  # Print the response body
  puts "Response body:"

  # If the response is JSON, pretty print it
  begin
    json_response = JSON.parse(response.body)
    puts JSON.pretty_generate(json_response)
  rescue JSON::ParserError
    # If it's not valid JSON, just print the body as is
    puts response.body
  end
end
