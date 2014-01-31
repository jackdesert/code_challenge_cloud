require 'pry'
require 'csv'
require 'bigdecimal'

class LineItem

  @values = {}
  ATTRS = [:Application, :Cluster, :DataType, :Environment, :Name, :Node, :Role, :Service]
  CSV_OFFSET = 22

  ATTRS.each do |attr|
    attr_accessor attr
    @values[attr] = {}
  end

  attr_accessor :dollar_amount

  def load(array)
    ATTRS.each_with_index do |attr, index|
      self.send("#{attr}=", array[index + CSV_OFFSET])
    end
    @dollar_amount = BigDecimal.new(array[20])
  end

  def save_to_class
    ATTRS.each do |attr|
      unless send(attr).nil? || (dollar_amount == 0)
        self.class.values[attr][send(attr)] ||= BigDecimal.new('0')
        self.class.values[attr][send(attr)] += dollar_amount
      end
    end
  end

  class << self

    attr_accessor :values

    ATTRS.each do |attr|
      attr_accessor attr
    end
    
  end
end
FILE = 'detailed-line-items-2013-05.csv'
item = LineItem.new
not_header = false
CSV.foreach(FILE) do |array|
  if not_header 
    item.load(array)
    item.save_to_class
  end
  not_header ||= true
end

binding.pry
def report
  o = "Report"
  LineItem.values.each_pair do |attr, tag_hash|
    o += "\n\nBy #{attr}:\n"
    tag_hash.each_pair do |tag, value|
      o += "  #{tag}:  $#{value.truncate(2).to_s('F')}\n"
    end
  end
  puts o
end

