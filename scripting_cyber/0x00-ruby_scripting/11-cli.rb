#!/usr/bin/env ruby

require 'optparse'

# File to store tasks
TASKS_FILE = 'tasks.txt'

# Function to add a new task
def add_task(task)
  File.open(TASKS_FILE, 'a') do |file|
    file.puts(task)
  end
  puts "Task '#{task}' added."
end

# Function to list all tasks
def list_tasks
  if File.exist?(TASKS_FILE)
    tasks = File.readlines(TASKS_FILE, chomp: true)
    if tasks.empty?
      puts "No tasks found."
    else
      tasks.each do |task|
        puts task
      end
    end
  else
    puts "No tasks found."
  end
end

# Function to remove a task by index
def remove_task(index)
  unless File.exist?(TASKS_FILE)
    puts "No tasks found."
    return
  end

  tasks = File.readlines(TASKS_FILE, chomp: true)

  if index < 1 || index > tasks.length
    puts "Invalid task index."
    return
  end

  removed_task = tasks.delete_at(index - 1)

  File.open(TASKS_FILE, 'w') do |file|
    tasks.each { |task| file.puts(task) }
  end

  puts "Task '#{removed_task}' removed."
end

# Parse command-line options
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: cli.rb [options]"

  opts.on('-a', '--add TASK', 'Add a new task') do |task|
    options[:add] = task
  end

  opts.on('-l', '--list', 'List all tasks') do
    options[:list] = true
  end

  opts.on('-r', '--remove INDEX', Integer, 'Remove a task by index') do |index|
    options[:remove] = index
  end

  opts.on('-h', '--help', 'Show help') do
    puts opts
    exit
  end
end.parse!

# Execute the appropriate action based on options
if options[:add]
  add_task(options[:add])
elsif options[:list]
  list_tasks
elsif options[:remove]
  remove_task(options[:remove])
else
  puts "Usage: cli.rb [options]"
  puts "Use -h or --help for more information."
end
