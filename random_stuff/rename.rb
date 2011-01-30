#!/usr/bin/env ruby

i = 0
puts Dir.getwd
Dir.glob('*.mp3').each do |mfile|
	mmfile = File.stat(mfile)
	if mmfile.file?
		n_name = mfile.gsub(/\s/, '_').gsub(/^-+/,'')
		File.rename(mfile, n_name)
	end
	puts "Treated #{i}"
	i+=1
end
