require 'sinatra'
require 'mysql2'

# Module - for database operations
module Database
  def self.truncate_table
    # Truncate the schedules table
    query = "TRUNCATE TABLE schedules"
    self.query(query)
  end
  def self.connect
  # Connect to the MySQL database
    Mysql2::Client.new(host: 'localhost', username: 'root', password: 'Madusri@2002', database: 'scheduler')
  end

  def self.create_table
  # Create the schedules table if it does not exist
    truncate_table
    db = connect
    db.query('CREATE TABLE IF NOT EXISTS schedules (id INT AUTO_INCREMENT PRIMARY KEY, day VARCHAR(255), start_time TIME, end_time TIME, description VARCHAR(255))')
  end

  def self.query(sql)
  # Execute a SQL query on the database
    db = connect  # Connect to the database
    db.query(sql) # Execute the SQL query using the connected database connection
  end

  def self.close
  # Close the database connection
    db = connect
    db.close
  end
end

# Module for operations related to schedules
module ScheduleOperations

  def schedule_overlap?(day, start_time, end_time)
  # Check if there is any overlap with existing schedules
    query = "SELECT * FROM schedules WHERE day = '#{day}' AND ((start_time < '#{end_time}' AND end_time > '#{start_time}') OR (start_time <= '#{start_time}' AND end_time >= '#{end_time}') OR (start_time >= '#{start_time}' AND end_time <= '#{end_time}'))"
    result = Database.query(query)
    return result.any?
  end

  def insert_schedule(day, start_time, end_time, description)
   # Insert a new schedule into the database
    query = "INSERT INTO schedules (day, start_time, end_time, description) VALUES ('#{day}', '#{start_time}', '#{end_time}', '#{description}')"
    Database.query(query)
  end

  def delete_schedule(id)
  # Delete a schedule from the database by ID
    query = "SELECT id FROM schedules WHERE id = #{id}"
    result = Database.query(query)

    if result.any?
      Database.query("DELETE FROM schedules WHERE id = #{id}")
      return { message: "Schedule with ID #{id} deleted successfully" }.to_json
    else
      return { error: "Invalid schedule ID. Please provide a valid ID." }.to_json
    end
  end

  def list_schedules
   # List all schedules grouped by day with process ids-for deletion
    query = "SELECT day, GROUP_CONCAT(CONCAT(id, ': ', description, ' (', start_time, ' - ', end_time, ')') SEPARATOR ', ') AS descriptions FROM schedules GROUP BY day ORDER BY FIELD(day, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')"
    result = Database.query(query)
    result.to_a
  end
  
  def list_scheduless
     # List all schedules grouped by day-for User's View
    query = "SELECT day, GROUP_CONCAT(CONCAT( description, ' (', start_time, ' - ', end_time, ')') SEPARATOR ', ') AS descriptions FROM schedules GROUP BY day ORDER BY FIELD(day, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')"
    result = Database.query(query)
    result.to_a
  end

end

# Sinatra application class for the scheduler server

class SchedulerServer < Sinatra::Base
  include ScheduleOperations

  before do
    content_type 'application/json'
  end
  # API endpoint to create a new schedule
  post '/schedule' do
    start_time = params['start_time']
    end_time = params['end_time']
    description = params['description']
    day = params['day'].capitalize

    if schedule_overlap?(day, start_time, end_time)
      halt 400, { error: "Schedule overlaps with existing schedule" }.to_json
    else
      insert_schedule(day, start_time, end_time, description)
      { message: "Schedule created successfully" }.to_json
    end
  end
  # API endpoint to delete a schedule by ID
  delete '/schedule/:id' do |id|
    response = delete_schedule(id)
    parsed_response = JSON.parse(response)#string response to hash
    if parsed_response.key?('error')
      status 400
    else
      status 200
  end

  parsed_response.to_json
end


  # API endpoint to get a list of all schedules- for deletion
  get '/schedules' do
    list_schedules.to_json
  end
  # API endpoint to get a list of all schedules -User's View
  get '/scheduless' do
    list_scheduless.to_json
  end
end

# Create table if not exists
Database.create_table

# Run the server
SchedulerServer.run!

