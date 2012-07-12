#!/usr/bin/env ruby

command = ARGV[0]
domains = ARGV[1..-1]

lines = []

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
    lines.map!{|l| !l.start_with?('#') && l.include?('#BLOCK') ? '#' + l : l }
  when 'enable'
    lines.map!{|l| l.start_with?('#') && l.include?('#BLOCK') ? l[1..-1] : l }
  else
    puts 'Invalid command'
  end
end

File.open('/etc/hosts', 'w') do |file|
  file.write(lines.join)
end
