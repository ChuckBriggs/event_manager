# frozen_string_literal: true
#require 'pry'; binding.pry #rubocop:disable all

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone_number)
  phone_number = phone_number.tr('^[0-9]', '')
  if phone_number.length == 10
    phone_number
  elsif phone_number.length == 11 && phone_number[0] == '1'
    phone_number[1..10]
  else
    '0000000000'
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting ' +
      'www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exists?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def log_time_occurrence(time)
  if @time_occurrences.nil?
    @time_occurrences = Hash.new
  end
  if @time_occurrences[time].nil?
    @time_occurrences[time] = 1
  else
    @time_occurrences[time] += 1
  end
end

def log_day_occurrence(day)
  if @day_occurrences.nil?
    @day_occurrences = Hash.new
  end
  if @day_occurrences[day].nil?
    @day_occurrences[day] = 1
  else
    @day_occurrences[day] += 1
  end
end

def find_most_frequent(hash)
  most_common = [0, 0]
  hash.each do |key, value|
    if value > most_common[1]
      most_common = [key, value]
    end
  end
  most_common[0]
end

def int_to_day(i)
  case i
  when 1
    "Monday"
  when 2
    "Tuesday"
  when 3
    "Wednesday"
  when 4
    "Thursday"
  when 5
    "Friday"
  when 6
    "Saturday"
  when 7
    "Sunday"
  else
    "OOPS!-day"
  end
end

puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_number(row[:homephone])
  registration_time = DateTime.strptime(row[:regdate], '%m/%d/%y %H:%M')

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)

  puts "#{registration_time} #{name} #{zipcode} #{phone_number}"

  log_time_occurrence(registration_time.hour)
  log_day_occurrence(registration_time.cwday)
end

unless @time_occurrences.nil?
  puts "The most common hour to register is #{find_most_frequent(@time_occurrences)}:00."
  puts "The most common day to register is #{int_to_day(find_most_frequent(@day_occurrences))}."
end

