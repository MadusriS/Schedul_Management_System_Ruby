require 'rest-client'
require 'json'

module ScheduleClient
  BASE_URL = 'http://localhost:4567'

  DAYS_MAPPING = {
    'Monday' => 0b0000001,
    'Tuesday' => 0b0000010,
    'Wednesday' => 0b0000100,
    'Thursday' => 0b0001000,
    'Friday' => 0b0010000,
    'Saturday' => 0b0100000,
    'Sunday' => 0b1000000
  }.freeze

  # Method to convert time from string format to 24-hour format
  def ScheduleClient.convert_time(time_str)
    hour, minutes = time_str.scan(/\d+/).map(&:to_i)
    if time_str.include?('pm') && hour != 12
      hour += 12
    elsif time_str.include?('am') && hour == 12
      hour = 0
    end
    format('%02d:%02d:00', hour, minutes || 0)
  end

  # Method to create a new schedule
  def ScheduleClient.create_schedule
    puts "Enter name of the task:"
    taskname = gets.chomp

    puts "Enter days (e.g., Monday, Tuesday):"
    days_input = gets.chomp.split(",").map(&:strip).map(&:capitalize)

    invalid_days = days_input.reject { |day| DAYS_MAPPING.key?(day) }

    unless invalid_days.empty?
      puts "Error: Please enter valid days of the week (Monday to Sunday)."
      return
    end

    puts "Enter start time (e.g., 1am, 2pm):"
    start_time = convert_time(gets.chomp.downcase)
    puts "Enter end time (e.g., 1am, 2pm):"
    end_time = convert_time(gets.chomp.downcase)

    response = RestClient.post("#{BASE_URL}/schedule", {
                                 taskname: taskname,
                                 days: days_input.join(','),
                                 start_time: start_time,
                                 end_time: end_time
                               })

    puts "\n"
    puts response.body
    puts "\n"
  rescue RestClient::ExceptionWithResponse => e
    puts "Error: #{e.response.body}"
  end

  # Method to delete a schedule

def ScheduleClient.delete_schedule
  list_schedules
  puts "Enter day (e.g., Monday):"
  day = gets.chomp.capitalize

  unless ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday','Saturday','Sunday'].include?(day)
    puts "Error: Deletion is only allowed for weekdays "
    return
  end

  puts "Enter task name:"
  taskname = gets.chomp

  puts "Enter starting time (e.g., 1am, 2pm):"
  start_time = convert_time(gets.chomp.downcase)

  response = RestClient.delete("#{BASE_URL}/schedule", params: { day: day, taskname: taskname, start_time: start_time })

  puts response.body
rescue RestClient::ExceptionWithResponse => e
  puts "Error: #{e.response.body}"
end


def ScheduleClient.list_schedules
  response = RestClient.get("#{BASE_URL}/schedules")
  schedules = JSON.parse(response.body)
  formatted_schedules = {}
  sorted_schedules = schedules.sort_by { |schedule| schedule['start_time'] }
  sorted_schedules.each do |schedule|
    schedule_days = decode_days(schedule['days'])
    schedule_name = schedule['name']
    start_time = format_time(schedule['start_time'])
    end_time = format_time(schedule['end_time'])
    schedule_days.each do |day|
      formatted_schedules[day] ||= []
      formatted_schedules[day] << "#{schedule_name} (#{start_time} - #{end_time})"
    end
  end
  
  ordered_days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
  
  ordered_days.each do |day|
    if formatted_schedules[day]
      puts "#{day} - #{formatted_schedules[day].join(', ')}"
    end
  end
end

def ScheduleClient.format_time(time_str)
  time_str.match(/(\d{2}):(\d{2}):(\d{2})/)[1..2].join(":") # Extract HH:MM from the time string
end


  # Method to decode integer representing days into an array of day names
  def ScheduleClient.decode_days(days)
  day_names = []
  DAYS_MAPPING.each do |day, bitmask|
    day_names << day.capitalize if days & bitmask != 0
  end
  day_names
end

end

# Loop for user interaction
loop do
  puts "\nChoose an option:"
  puts "1. Create Schedule"
  puts "2. List Schedules"
  puts "3. Delete Schedule"
  puts "4. Exit"
  puts "\n"

  option = gets.chomp.to_i

  case option
  when 1
    ScheduleClient.create_schedule
  when 2
    ScheduleClient.list_schedules
  when 3
    ScheduleClient.delete_schedule
  when 4
    break
  else
    puts "Invalid option. Please try again."
  end
end
