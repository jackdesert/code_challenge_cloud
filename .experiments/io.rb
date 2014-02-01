require 'csv'
require 'pry'


FILE = 'detailed-line-items-2013-05.csv'


def process(arr_of_arrs)
  tmp = nil
  arr_of_arrs.each do |arr|
    tmp = arr
  end
end



lines = []
IO.foreach(FILE) do |line|
  lines << line
  if lines.size >= 1000
    lines = CSV.parse(lines.join) rescue next
    process lines
    lines = []
  end
end
process lines


#real  0m22.018s
#user  0m21.577s
#sys 0m0.340s
