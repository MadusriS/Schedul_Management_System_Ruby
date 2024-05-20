require 'sinatra'
require 'mysql2'
require 'json'

module Database
  def Database.connect
    Mysql2::Client.new(host: 'localhost', username: 'root', password: 'Madusri@2002', database: 'scheduler')
  end

  def Database.create_table
    db = connect
    db.query('CREATE TABLE IF NOT EXISTS schedules (
    id INT AUTO_INCREMENT PRIMARY KEY, 
    name VARCHAR(255), 
    days INT, 
    start_time TIME, 
    end_time TIME)')
  end

  def Database.insert_schedule(name, days, start_time, end_time)
    db = connect
    db.query("INSERT INTO schedules (
    name, days, start_time, end_time) 
    VALUES ('#{name}', #{days}, '#{start_time}', '#{end_time}')")
  end

  def Database.query(sql)
    db = connect
    db.query(sql)
  end

  def Database.delete_schedule(id)
    db = connect
    db.query("DELETE FROM schedules WHERE id = #{id}")
  end
end

module ScheduleOperations
  DAYS_MAPPING = {
    'Monday' => 0b0000001,
    'Tuesday' => 0b0000010,
    'Wednesday' => 0b0000100,
    'Thursday' => 0b0001000,
    'Friday' => 0b0010000,
    'Saturday' => 0b0100000,
    'Sunday' => 0b1000000
  }.freeze

  def ScheduleOperations.convert_days_to_binary(days)
    binary = 0
    days.each { |day| binary |= DAYS_MAPPING[day] }
    binary
  end

  def ScheduleOperations.schedule_overlap?(days, start_time, end_time)
    query = "SELECT * FROM schedules WHERE days & #{days} != 0 AND 
    ((start_time <= '#{start_time}' AND end_time > '#{start_time}') OR 
    (start_time < '#{end_time}' AND end_time >= '#{end_time}') OR 
    (start_time >= '#{start_time}' AND end_time <= '#{end_time}'))"
    result = Database.query(query)
    result.any?
  end

  def ScheduleOperations.add_schedule(name, days, start_time, end_time)
    binary_days = convert_days_to_binary(days)
    if schedule_overlap?(binary_days, start_time, end_time)
      raise "Schedule overlaps with existing schedule"
    else
      Database.insert_schedule(name, binary_days, start_time, end_time)
      { message: "Schedule created successfully" }.to_json
    end
  end

  def ScheduleOperations.get_schedules
    schedules = Database.query("SELECT * FROM schedules")
    schedules.to_a
  end
  
def ScheduleOperations.delete_schedule(day, taskname, start_time)
  binary_day = DAYS_MAPPING[day.capitalize]

  # First, delete any schedules where days = 0
  Database.query("DELETE FROM schedules WHERE days = 0")

  # Check if the schedule exists for the given parameters
  existing_schedule_query = "SELECT * FROM schedules 
                             WHERE name = '#{taskname}' 
                             AND start_time = '#{start_time}'
                             AND days & #{binary_day} != 0"

  existing_schedule_result = Database.query(existing_schedule_query)

  if existing_schedule_result.any?
    # If the schedule exists, delete it
    query = "UPDATE schedules SET days = days & ~#{binary_day} 
             WHERE name = '#{taskname}' 
             AND start_time = '#{start_time}'"
    puts "Generated SQL query: #{query}" # Print the generated SQL query for debugging
    result = Database.query(query)

    { message: "Schedule successfully deleted" }.to_json
  else
    { message: "Schedule not found" }.to_json
  end
end

end

# API endpoint to create a new schedule
post '/schedule' do
  begin
    start_time = params['start_time']
    end_time = params['end_time']
    taskname = params['taskname']
    days = params['days'].split(',')

    ScheduleOperations.add_schedule(taskname, days, start_time, end_time)
  rescue => e
    status 400
    { error: e.message }.to_json
  end
end

# API endpoint to delete a schedule by day, task name, and start time
delete '/schedule' do
  begin
    day = params['day']
    taskname = params['taskname']
    start_time = params['start_time']

    ScheduleOperations.delete_schedule(day, taskname, start_time)
  rescue => e
    status 400
    { error: e.message }.to_json
  end
end

# API endpoint to get entire schedule
get '/schedules' do
  schedules = ScheduleOperations.get_schedules
  sorted_schedules = schedules.sort_by { |schedule| schedule['start_time'] }
  sorted_schedules.to_json
end

# Create table if not exists
Database.create_table

