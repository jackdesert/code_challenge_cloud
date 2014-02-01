require 'fastercsv'
require 'pry'


FILE = 'detailed-line-items-2013-05.csv'

temp = nil
FasterCSV.foreach(FILE) do |row|
  temp = row

end

Doesn't run--says ruby 1.9 has the FasterCSV in it
# seconds
