#!/usr/bin/env ruby

# file: rexle-xpath

require 'rexle-xpath-parser'


class RexleXPath

  def initialize(node=nil)

    @node = XPathObject.new(node)

  end

  def parse(s)

    case s
    when /^(\w+)\(\)$/
      @node.method(($1).to_sym).call
    else
      query RexleXPathParser.new(s).to_a
    end
  end

  def query(a)
    
    r = []
    
    a.each do |row|
      x, *args = row
      if x == :select then
        r = @node.select args.first
      elsif row.is_a? Array then
        r = query row
      end
    end
    r

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