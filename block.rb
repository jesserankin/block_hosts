#!/usr/bin/env ruby

command = ARGV[0]
domains = ARGV[1..-1]

lines = []

TIME_PREFIX = 'COUNTER'

def disable(lines)
  lines.map!{|l| !l.start_with?('#') && l.include?('#BLOCK') ? '#' + l : l }
end

def enable(lines)
  lines.map!{|l| l.start_with?('#') && l.include?('#BLOCK') ? l[1..-1] : l }
end

def date
  Time.now.strftime('%Y-%m-%d')
end

def counter_value(lines)
  counter_line = lines.find{|l| l.include?("##{TIME_PREFIX} #{date}")}
  counter_line ? counter_line.split(" ")[2].to_i : 0
end

def delete_counter(lines)
  lines.delete_if{|l| l.include?("##{TIME_PREFIX} #{date}")}
end

def set_counter(lines, mins)
  lines << "##{TIME_PREFIX} #{date} #{mins}\n"
end

def add_to_counter(lines, mins)
  total = counter_value(lines) + mins
  delete_counter(lines)
  set_counter(lines, total)
end

def save_file(lines)
  File.open('/etc/hosts', 'w') do |file|
    file.write(lines.join)
  end
end

File.open('/etc/hosts', 'r') do |file|
  lines = file.readlines
  case command
  when 'add'
    domains.each do |domain|
      unless lines.any?{|l| l.include?("#BLOCK #{domain}")}
        lines += ['','www.'].map{|prefix| "0.0.0.0\t" + prefix + domain + "\t#BLOCK "+ domain + "\n"}
      end
    end
  when 'rm'
    domains.each do |domain|
      lines.delete_if{|l| l.include?("#BLOCK #{domain}")}
    end
  when 'disable'
    disable(lines)
  when 'enable'
    enable(lines)
  when 'disable-timer'
    count = counter_value(lines)
    disable(lines)
    save_file(lines)
    duration = ARGV[1].to_i
    duration.times do |i|
      print "\r#{count + i} minutes total today, #{duration - i} minutes left  "
      sleep 60
    end
    print "\rTime's up! #{count + duration} minutes total today                      \n"
    enable(lines)
    add_to_counter(lines, duration)
  else
    puts 'Invalid command'
  end
end

save_file(lines)
