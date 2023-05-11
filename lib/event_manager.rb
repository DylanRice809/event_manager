require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def to_days (integer, weekday="")
  weekdays = {
    Sunday: 0,
    Monday: 1,
    Tuesday: 2,
    Wedensday: 3,
    Thursday: 4,
    Friday: 5,
    Saturday: 6
  }
  weekdays.each_pair do |day, number|
    if (number == integer)
      weekday = day
    end
  end
  weekday
end

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def find_hour (date, hour_hash)
  hour = date.split(" ")[1].split(":")[0]
  if hour_hash[hour].nil?
    hour_hash[hour] = 1
  else
    hour_hash[hour] += 1
  end
end

def find_weekday (date, hash)
  date = date.split("/")
  time_object = Time.new(date[2], date[0], date[1])

  weekday = time_object.wday
  weekday = to_days(weekday)

  if hash[weekday].nil?
    hash[weekday] = 1
  else
    hash[weekday] += 1
  end
end

def clean_phone_numbers(phone_number)
  message = "INVALID NUMBER"
  new_number = []
  phone_number.split("").each do |character|
    if character.to_i.to_s == character
      new_number << character
    end
  end
  new_number = new_number.join
  if new_number.nil?
    new_number = message
  elsif new_number.length < 10
    new_number = message
  elsif new_number.length == 10
    phone_number
  elsif new_number.length == 11 && new_number[0] == "1"
    new_number = new_number.split("")
    new_number.delete(new_number[0])
    new_number.join
  elsif new_number.length == 11 && new_number[0] != "1"
    new_number = message
  else
    new_number = ":/"
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

weekday_hash = {}
sorted_hash = {}
contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  date_time = row[:regdate].split(" ")

  registration_time = find_hour(row[:regdate], sorted_hash)

  registration_date = find_weekday(date_time[0], weekday_hash)

  phone_number = clean_phone_numbers(row[:homephone])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

sorted_hash.sort_by { |key, value| key }.each do |element|
  p element
end

weekday_hash.sort_by { |key, value| key.to_s }.each do |element|
  p element
end