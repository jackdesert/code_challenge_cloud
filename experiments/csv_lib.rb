require 'csv'
require 'pry'


FILE = 'detailed-line-items-2013-05.csv'

temp = nil
CSV.foreach(FILE) do |row|
  temp = row
  binding.pry

end

#real  0m20.948s
#user  0m20.589s
#sys 0m0.260s
