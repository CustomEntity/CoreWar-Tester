#!/usr/bin/env ruby
require 'English'
require 'open3'

class Constants
  BINARY_REF_FILE = './asm_ref'
  CHAMPIONS_FOLDER = 'champions/'
  ERROR_CHAMPIONS_FOLDER = 'error/'
  FUNCTIONAL_CHAMPIONS_FOLDER = 'functional/'
end

class String
  def add_style(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def black
    add_style(31)
  end

  def red
    add_style(31)
  end

  def green
    add_style(32)
  end

  def yellow
    add_style(33)
  end

  def blue
    add_style(34)
  end

  def magenta
    add_style(35)
  end

  def cyan
    add_style(36)
  end

  def grey
    add_style(37)
  end

  def bold
    add_style(1)
  end

  def italic
    add_style(3)
  end

  def underline
    add_style(4)
  end
end

if ARGV.size.zero? || !File.file?(ARGV[0])
  puts 'Please specify a binary file !'.red.bold
  return
end
binary_path = ARGV[0].start_with?('./') ? ARGV[0].to_s : './'.concat(ARGV[0].to_s)

puts " ██████╗ ██████╗ ██████╗ ███████╗██╗    ██╗ █████╗ ██████╗      █████╗ ███████╗███╗   ███╗     ██████╗██╗  ██╗███████╗ ██████╗██╗  ██╗███████╗██████╗
██╔════╝██╔═══██╗██╔══██╗██╔════╝██║    ██║██╔══██╗██╔══██╗    ██╔══██╗██╔════╝████╗ ████║    ██╔════╝██║  ██║██╔════╝██╔════╝██║ ██╔╝██╔════╝██╔══██╗
██║     ██║   ██║██████╔╝█████╗  ██║ █╗ ██║███████║██████╔╝    ███████║███████╗██╔████╔██║    ██║     ███████║█████╗  ██║     █████╔╝ █████╗  ██████╔╝
██║     ██║   ██║██╔══██╗██╔══╝  ██║███╗██║██╔══██║██╔══██╗    ██╔══██║╚════██║██║╚██╔╝██║    ██║     ██╔══██║██╔══╝  ██║     ██╔═██╗ ██╔══╝  ██╔══██╗
╚██████╗╚██████╔╝██║  ██║███████╗╚███╔███╔╝██║  ██║██║  ██║    ██║  ██║███████║██║ ╚═╝ ██║    ╚██████╗██║  ██║███████╗╚██████╗██║  ██╗███████╗██║  ██║
 ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝    ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝     ╚═════╝╚═╝  ╚═╝╚══════╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝
                                                                                                                                                      ".green

def progressbar(size, percentage, char)
  bar = '[ '.bold
  filled = (size * percentage / 100).to_i

  (0..filled - 1).each { |_| bar << char.green.bold }
  (0..size - filled - 1).each { |_| bar << char.red.bold }
  bar << ' ]'.bold
end

def handle_file_error_handling(binarypath, filepath, i)
  filename = filepath.split('/')[filepath.count '/']
  executed = fork { Kernel.exec("#{binarypath} #{filepath}", out: File::NULL, err: File::NULL) }
  return if executed.nil?

  Process.wait(executed)
  return if $CHILD_STATUS.nil?

  exit_code = $CHILD_STATUS.exitstatus
  print "[Test ##{i}] #{filename} » ".cyan.bold
  if exit_code == 84
    puts 'SUCCESS ✔'.green.bold
    1
  else
    puts 'FAILURE ✖'.red.bold
  end
end

def check_error_handling(binarypath)
  i = 0
  success = 0
  Dir.glob("#{Constants::CHAMPIONS_FOLDER}#{Constants::ERROR_CHAMPIONS_FOLDER}*.s") do |filepath|
    i += 1
    file = File.open(filepath.to_s)
    success += 1 if handle_file_error_handling(binarypath, filepath, i) == 1
    file.close
  end
  percentage = i != 0 ? success * 100 / i : 100
  puts
  print "  ➥ Error Handling Result: #{progressbar(20, percentage, '|')} ".bold
  print "#{percentage}% Success: #{success} Total: #{i}".bold
  puts
  [i, success]
end

def handle_file_compilation(binarypath, filepath, i)
  filename = filepath.split('/')[filepath.count '/']
  filename_ws = filename.delete_suffix('.s')
  executed = fork { Kernel.exec("#{binarypath} #{filepath}", in: File::NULL, out: File::NULL, err: File::NULL) }
  return if executed.nil?

  Process.wait(executed)

  Open3.capture3("mv #{filename_ws}.cor #{filename_ws}.tmp.cor")
  executed = fork { Kernel.exec("#{Constants::BINARY_REF_FILE} #{filepath}", in: File::NULL, out: File::NULL, err: File::NULL) }
  return if executed.nil?

  Process.wait(executed)
  hexdump1 = Open3.capture3("hexdump #{filename_ws}.tmp.cor")
  hexdump2 = Open3.capture3("hexdump #{filename_ws}.cor")


  print "[Test ##{i}] #{filename} » ".cyan.bold
  if hexdump1 == hexdump2
    puts 'SUCCESS ✔'.green.bold
    1
  else
    puts 'FAILURE ✖'.red.bold
  end
end

def check_compilation(binarypath)
  i = 0
  success = 0
  Dir.glob("#{Constants::CHAMPIONS_FOLDER}#{Constants::FUNCTIONAL_CHAMPIONS_FOLDER}*.s") do |filepath|
    i += 1
    file = File.open(filepath.to_s)
    success += 1 if handle_file_compilation(binarypath, filepath, i) == 1
    file.close
  end
  percentage = i != 0 ? success * 100 / i : 100
  puts
  print "  ➥ ASM Compilation Result: #{progressbar(20, percentage, '|')} ".bold
  print "#{percentage}% Success: #{success} Total: #{i}".bold
  puts
  [i, success]
end

total = 0
success = 0

puts 'Checking ASM error handling..'.blue.bold
puts

error_result = check_error_handling(binary_path)
total += error_result[0]
success += error_result[1]

executed = fork { Kernel.exec('find -name "*.cor" -delete') }
return if executed.nil?

Process.wait(executed)

puts
puts 'Checking ASM Compilation..'.blue.bold
puts
compilation_result = check_compilation(binary_path)
total += compilation_result[0]
success += compilation_result[1]

executed = fork { Kernel.exec('find -name "*.cor" -delete') }
return if executed.nil?

Process.wait(executed)

percentage = total != 0 ? success * 100 / total : 100
puts
puts '-------------------------------'
print "➥ Total Result: #{progressbar(20, percentage, '|')} ".bold
print "#{percentage}% Success: #{success} Total: #{total}".bold
puts

