require "option_parser"
require "json"

option_parser = OptionParser.parse do |parser|
  parser.banner = "grey repo parser (www.greyrepo.xyz/posts/folder-parser)"

  parser.on "-v", "--version", "Show version" do
    puts "version 1.0"
    exit
  end
  parser.on "-h", "--help", "Show help" do
    puts parser
    exit
  end
  parser.missing_option do |option_flag|
    STDERR.puts "ERROR: #{option_flag} is missing something."
    STDERR.puts ""
    STDERR.puts parser
    exit(1)
  end
  parser.invalid_option do |option_flag|
    STDERR.puts "ERROR: #{option_flag} is not a valid option."
    STDERR.puts parser
    exit(1)
  end
end

ENV["EDITOR"] ||= "vi"
editor = ENV["EDITOR"]

puts "actions:"
puts "[1] import project"
puts "[2] export a local folder"

selected_action  = gets

if selected_action == "1"
  puts "(optional, you can press enter to skip and use the root folder name provided in the import string)\nroot folder name:"
  root_folder_name = gets
  # output = IO::Memory.new
  # Process.run("pwd", output: output)
  # output.close
  current_path = Dir.current
  root_folder = Dir.open current_path

  File.delete "/tmp/input" if File.exists? "/tmp/input"
  system "#{editor} /tmp/input"
  string = File.read "/tmp/input"

  file_table = {} of String => File | Dir

  table = Hash(String, Hash(String, String)).from_json(string)
  table.each do |key, value|
    if value["parent"] == ""
      parent_folder = root_folder
      file_path = "#{parent_folder.path}/#{root_folder_name || value["name"]}"
      # Dir.rmdir file_path if Dir.exists? file_path
      system "rm -rf #{file_path}" if Dir.exists? file_path
    else
      parent_folder = file_table[value["parent"]]
      file_path = "#{parent_folder.path}/#{value["name"]}"
    end

    if value["type"] == "folder"
      Dir.mkdir(file_path)
      file = Dir.open(file_path)
    else
      File.touch(file_path)
      file = File.open(file_path)
      File.write(file_path, value["content"])
    end
    file_table[key] = file
    puts "created #{value["type"]} #{file_path}"
  end
end

def get_folder_table(folder, table = {} of String => Hash(Symbol, String), parent = "")
  index = table.size
  folder_name = folder.path.split("/").last
  obj = {parent: parent, type: "folder", name: folder_name}.to_h
  table[index.to_s] = obj
  parent = index.to_s
  index += 1

  scripts = [] of File
  folders = [] of Dir

  folder.each do |file_name|
    next if [".", ".."].includes? file_name
    file_path = "#{folder.path}/#{file_name}"
    if File.directory? file_path
      folders << Dir.open(file_path)
    else
      scripts << File.open(file_path)
    end
  end

  scripts.each do |script|
    file_name = script.path.split("/").last
    obj = {parent: parent, type: "script", name: file_name, content: File.read(script.path)}.to_h
    table[index.to_s] = obj
    index += 1
  end

  folders.each do |folder|
    table = get_folder_table(folder, table, parent)
  end

  table
end

if selected_action == "2"
  puts "full path of the folder:"
  full_path =  gets.to_s.chomp
  folder = Dir.open full_path
  export_obj = get_folder_table(folder)
  puts "this is your export string:"
  puts export_obj.to_json
end
