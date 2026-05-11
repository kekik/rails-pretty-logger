require "fileutils"

desc "Split log with hourly"
task :split_log, [:log_name, :log_path] => :environment do |_task, arg|
  log_name = File.basename(arg[:log_name].to_s)
  log_path = arg[:log_path].to_s

  abort "Usage: bin/rails 'split_log[new_log_file_name,/path/to/log.file]'" if log_name.blank? || log_path.blank?
  abort "Log file does not exist: #{log_path}" unless File.file?(log_path)

  parse_date = lambda do |line|
    next unless line.include?("Started")

    date_index = line.index("at ")
    next unless date_index

    line[date_index..date_index + 18].to_datetime
  rescue ArgumentError
    nil
  end

  current_file_path = nil
  output = nil

  begin
    IO.foreach(log_path) do |line|
      if (date = parse_date.call(line))
        new_path = File.join(Rails.root, 'log', 'hourly', date.strftime('%Y'), date.strftime('%m'), date.strftime('%d'))
        file_path = File.join(new_path, "#{log_name}.log.#{date.strftime('%Y%m%d_%H00')}")

        if file_path != current_file_path
          output&.close
          FileUtils.mkdir_p new_path
          output = File.open(file_path, "a")
          current_file_path = file_path
        end
      end

      output << line if output
    end
  ensure
    output&.close
  end

  puts "It's done"
end
