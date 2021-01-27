# frozen_string_literal: true

def extract_date(line)
  return unless line.include?('Started')

  date_index = line.index('at ')
  date = line[date_index, 19]
  date.to_datetime
end

desc 'Split log with hourly'
task split_log: %i[log_name log_path] do |_, arg|
  start = false
  new_path = nil
  file_path = nil

  IO.foreach(arg[:log_path]) do |line|
    date = begin
      extract_date(line)
    rescue StandardError
      nil
    end

    if date
      start = true
      new_path = Rails.root.join('log', 'hourly', date.strftime('%Y'),
                                 date.strftime('%m'), date.strftime('%d'))
      FileUtils.mkdir_p new_path unless File.directory?(new_path)
      file_path = "#{new_path}/#{arg[:log_name]}.log.#{date.strftime('%Y%m%d_%H00')}"
      File.open(file_path, 'a') do |file|
        file << line
      end
    elsif start
      File.open(file_path, 'a') do |file|
        file << line
      end
    end
  end
  puts "It's done"
end
