require 'csv'
require 'bigdecimal'

class LineItem

  @values = {}
  @instance_types = {}

  ATTRS = [:Application, :Cluster, :DataType, :Environment, :Name, :Node, :Role, :Service]
  CSV_OFFSET = 22

  ATTRS.each do |attr|
    attr_accessor attr
    @values[attr] = {}
  end

  attr_reader :dollar_amount, :instance_type

  def load(array)
    ATTRS.each_with_index do |attr, index|
      self.send("#{attr}=", array[index + CSV_OFFSET])
    end
    @dollar_amount = BigDecimal.new(array[20])
    @instance_type = array[13].match(/\(.*\d\..*?\)/).to_s
  end

  def save_to_class
    ATTRS.each do |attr|
      unless send(attr).nil? || (dollar_amount == 0)
        self.class.values[attr][send(attr)] ||= BigDecimal.new('0')
        self.class.values[attr][send(attr)] += dollar_amount
      end
    end
    self.class.instance_types[instance_type] = true
  end

  class << self

    attr_accessor :values, :instance_types

    ATTRS.each do |attr|
      attr_accessor attr
    end

    def cost_report
      o = "\n\n#{'=' * 21}\nDAILY SPENDING REPORT\n#{'-' * 21}"
      values.each_pair do |attr, tag_hash|
        o += "\n\nBy #{attr}:\n"
        tag_hash.each_pair do |tag, value|
          o += "  #{tag}:  $#{value.truncate(2).to_s('F')}\n"
        end
      end
      o += "\n\n"
      puts o
    end

    def instance_types_report
      instance_types.delete('')
      puts 'INSTANCES'
      puts "There are #{instance_types.length} unique instance types:"
      instance_types.each_pair do |type, true_value|
        puts "  #{type.gsub(/\(|\)/, '')}"
      end
      puts "\n\n"
    end
  end
end
   
item = LineItem.new
file = ARGV.pop
not_header = false
CSV.foreach(file) do |array|
  if not_header 
    item.load(array)
    item.save_to_class
  end
  not_header ||= true
end

LineItem.cost_report
LineItem.instance_types_report


