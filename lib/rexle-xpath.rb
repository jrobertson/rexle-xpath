#!/usr/bin/env ruby

# file: rexle-xpath

require 'rexle-xpath-parser'


class RexleXPath

  def initialize(node=nil)

    @node = node

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

  def query(node=@node, xpath_instructions)

    r = []

    row = xpath_instructions.shift        
    method_name, *args = row

    return query node, row if row.first.is_a? Array    

    result = method(method_name.to_sym).call node, args, xpath_instructions
    result.is_a?(Array) ? result.flatten : result

  end
  
  private
  
  def attribute(node, args, xpath_instructions)

    key = args.first.to_sym
    r = node.attributes[key]
    r ? true : false    
  end
  
  def not(node, args, xpath_instructions)
    
    r = query node, xpath_instructions
    !(r ? r.any? : r)
  end  
  
  def predicate(node, args, xpath_instructions)
    
    r = query node, args
    r ? r.any? : r    
  end
  
  def select(node, args, xpath_instructions)

    a = node.elements.select {|x| x.name == args.first }

    predicate = xpath_instructions.flatten.first.to_s == 'predicate'

    if xpath_instructions.any? and a.any? then
      
      a.inject([]) do |r, child_node| 
        
        r2 = query(child_node, xpath_instructions.clone)

        case r2.class.to_s.to_sym
        when :'Rexle::Element' then r << r2
        when :TrueClass        
          predicate ? r << child_node : r << true
        when :FalseClass
          !predicate ? r << false : r
        else
          
          r2.any? ? r << r2 : r
          
        end # /case
        
      end # /inject
      
    else
      a
    end  # /if
    
  end
  
  def value(node, args, xpath_instructions)

    operator, operand = args
    
    case operator.to_sym
    when :== then  node.text == operand
    when :>  then  node.value > operand
    when :<  then  node.value < operand
    end
        
  end
  
  alias text value
  
end