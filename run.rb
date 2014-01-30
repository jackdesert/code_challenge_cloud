require 'pry'
require 'csv'

class LineItem
  ATTRS = [:Application, :Cluster, :DataType, :Environment, :Name, :Node, :Role, :Service]
  @values = {}

  ATTRS.each do |attr|
    attr_accessor attr
  end

  attr_accessor :dollar_amount

  def load(array)
    index = 22
    ATTRS.each do |attr|
      self.send("#{attr}=", array[index])
    end
    @dollar_amount = array[20]
  end

  def save_to_class
    binding.pry
    ATTRS.each do |attr|
      self.class.values[attr][self.attr] += dollar_amount
    end
  end

  class << self

    ATTRS.each do |attr|
      attr_accessor attr
    end
    
  end
end
binding.pry
FILE = 'detailed-line-items-2013-05.csv'
item = LineItem.new
CSV.foreach(FILE) do |array|
  item.load(array)
  item.save_to_class
end
binding.pry

