# str = "\\?initialize mixer01 \n-- Raw Dataset \n \\un?initialize mixer01"
# if str =~ /\A(\\?initialize\s+[0-9a-z]+)\s*(.*?)\s*(\\un?initialize\s+[0-9a-z]+)\z/
#   puts $1
#   puts $2
#   puts $3
#   str.gsub!(/\A(\\?initialize\s+[0-9a-z]+)/, '')
#   str.gsub!(/(\\un?initialize\s+[0-9a-z]+)\z/, '')
#   str.strip!
#   puts str
# else
#   puts 'Not present'
# end
# 
# str = "\\initialize mixer01 \n-- Raw Dataset \n \\uninitialize mixer01"
# # Rovnou odstranit
# str.gsub!(/\A\\initialize\s+[0-9a-z]+\s*|\s*\\uninitialize\s+[0-9a-z]+\z/, '')
# str.strip!
# puts str

# str = "\\initialize mixer01\n-- Raw Dataset \n\\uninitialize mixer01\n SET \n"
# # Rovnou odstranit
# str.gsub!(/^\\(un)?initialize\s+[0-9a-zA-Z]+(\r\n|\r|\n)[2,]$/m, '')
# str.strip!
# puts str



# content = File.read(filename)
# cleaned = content.gsub(
#   /\A\\?initialize\s+[0-9a-z]+\s*|\s*\\un?initialize\s+[0-9a-z]+\z/, '',
# )
# cleaned.strip!
# File.write(filename, cleaned)