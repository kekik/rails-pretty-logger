desc "Split log with hourly"
task :split_log, [:log_name, :log_path] do |t, arg|

  start = false
  new_path = nil
  file_path = nil

  def get_date(line)
    if line.include?("Started")
      date_index = line.index("at ")
      date = line[date_index .. date_index + 18]
      date.to_datetime
    end
  end

  IO.foreach(arg[:log_path]) do |line|
    date = get_date(line) rescue nil
    if date
      start = true
      new_path = File.join(Rails.root, 'log', 'hourly', date.strftime('%Y'), date.strftime('%m'), date.strftime('%d'))
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
