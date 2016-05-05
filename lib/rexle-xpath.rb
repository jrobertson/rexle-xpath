#!/usr/bin/env ruby

# file: rexle-xpath

require 'rexle-xpath-parser'


class RexleXPath

  def initialize(node=nil)

    @node = XPathObject.new(node)

  end

  def parse(s)

    case s
      
    # it's an xpath function
    when /^(\w+)\(\)$/
      @node.method(($1).to_sym).call
    else
      query @node, RexleXPathParser.new(s).to_a
    end
  end

  def query(node, xpath_instructions)
    
    r = []
    row = xpath_instructions.shift    

    method_name, *args = row
    
    a = if method_name == :select then
      
      r = node.select args.first

      if xpath_instructions.any? and r.any? then
        r.map {|child_node| query(child_node, xpath_instructions) }
      else
        r
      end
      
    elsif row.is_a? Array then
      query node, row
    else
      []
    end

    a.flatten

  end

  class XPathObject

    def initialize(element)
      @element = element
    end

    def name()
      @element.name()
    end
    
    def not()
      @element
    end
    
    def select(name)
      @element.select(name)
    end

    def text()
      @element.text()
    end

  end

end