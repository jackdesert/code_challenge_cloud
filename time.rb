require 'csv'
require 'pry'


FILE = 'detailed-line-items-2013-05.csv'

temp = nil
CSV.foreach(FILE) do |row|
  temp = row

end
