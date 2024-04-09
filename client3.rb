require 'rest-client'
require 'json'

module ScheduleClient
  BASE_URL = 'http://localhost:4567'
  
  WEEKDAYS = %w[Monday Tuesday Wednesday Thursday Friday].freeze
  
 # Method to convert time from string format to 24-hour format
def self.convert_time(time_str)
  hour, minutes = time_str.scan(/\d+/).map(&:to_i)
  if time_str.include?('pm') && hour != 12
    hour += 12
  elsif time_str.include?('am') && hour == 12
    hour = 0
  end
  format('%02d:%02d:00', hour, minutes || 0)
end
 
 # Method to validate if the input day is a weekday
  def self.valid_weekday?(day)
    WEEKDAYS.include?(day)
  end

def self.create_schedule
  puts "Enter days (e.g., Monday,Tuesday):"
  days = gets.chomp.split(',').map(&:strip).map(&:capitalize)

  days.each do |day|
    unless valid_weekday?(day)
      puts "Error: '#{day}' is not a valid weekday. Skipping."
      next
    end

    puts "Enter start time for #{day} (e.g., 1am, 2pm):"
    start_time = convert_time(gets.chomp.downcase)
    puts "Enter end time for #{day} (e.g., 1am, 2pm):"
    end_time = convert_time(gets.chomp.downcase)
    puts "Enter description for #{day}:"
    description = gets.chomp

    response = RestClient.post("#{BASE_URL}/schedule", { day: day, start_time: start_time, end_time: end_time, description: description })
    puts "\n"
    puts response.body
    puts "\n"
  end
rescue RestClient::ExceptionWithResponse => e
  puts "Error: #{e.response.body}"
end

  
  # Method to delete a schedule
  def self.delete_schedule    
    list_schedules 
    puts "Enter ID of the schedule to delete:"
    id = gets.chomp.to_i    
    response = RestClient.delete("#{BASE_URL}/schedule/#{id}")    
    puts response.body    
  rescue RestClient::ExceptionWithResponse => e
    puts "Error: #{e.response.body}"
  end
  
  # Method to list all schedules-for deletion
  def self.list_schedules
    response = RestClient.get("#{BASE_URL}/schedules")
    schedules = JSON.parse(response.body)
    schedules.each do |schedule|
      # Split descriptions into array of strings if it's a single concatenated string
      descriptions = if schedule['descriptions'].is_a?(String)
                       schedule['descriptions'].split(', ')
                     else
                       schedule['descriptions']
                     end
      # Sort descriptions by start time
      sorted_descriptions = descriptions.sort_by do |desc|
        start_time = desc.match(/\((.*?)\s*-/)[1]
        Time.parse(start_time)
    end
    # Display day and descriptions with process IDs
    
    puts "#{schedule['day']} - #{sorted_descriptions.join(', ')}"
    
  end
  rescue RestClient::ExceptionWithResponse => e
    puts "Error: #{e.response.body}"
  end
  
  # Method to list all schedules-User's View
  def self.list_scheduless
    response = RestClient.get("#{BASE_URL}/scheduless")
    schedules = JSON.parse(response.body)
    schedules.each do |schedule|
      # Split descriptions into array of strings if it's a single concatenated string
      descriptions = if schedule['descriptions'].is_a?(String)
                       schedule['descriptions'].split(', ')
                     else
                       schedule['descriptions']
                     end
      # Sort descriptions by start time
      sorted_descriptions = descriptions.sort_by do |desc|
        start_time = desc.match(/\((.*?)\s*-/)[1]
        Time.parse(start_time)
     end
     # Display day and descriptions with process IDs
    
    puts "#{schedule['day']} - #{sorted_descriptions.join(', ')}"
    
   end
   rescue RestClient::ExceptionWithResponse => e
     puts "Error: #{e.response.body}"
   end
  end
  
# loop for user interaction
loop do
  puts "\nChoose an option:"
  puts "1. Create Schedule"
  puts "2. Delete Schedule"
  puts "3. List Schedules"
  puts "4. Exit"
  puts "\n"

  option = gets.chomp.to_i

  case option
  when 1
    ScheduleClient.create_schedule
  when 2
    ScheduleClient.delete_schedule
    ScheduleClient.list_schedules
  when 3
    ScheduleClient.list_scheduless
  when 4
    break
  else
    puts "Invalid option. Please try again."
  end
end

