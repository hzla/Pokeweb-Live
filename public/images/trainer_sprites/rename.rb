


Dir.glob('./*').sort.each do |entry|
  new_name = File.basename(entry).downcase
  p new_name
   File.rename( entry, new_name )
end