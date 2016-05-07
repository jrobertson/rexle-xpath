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
    
    result = if method_name.to_sym == :select then

      method(:select).call node, args, xpath_instructions
      
    elsif method_name.to_sym == :text or method_name.to_sym == :value then

      method(:value).call node, args, xpath_instructions
      
    elsif method_name.to_sym == :predicate then

      method(:predicate).call node, args, xpath_instructions      
      
    elsif row.is_a? Array then
      query node, row
    else
      []
    end

    result.is_a?(Array) ? result.flatten : result

  end
  
  private
  
  def predicate(node, args, xpath_instructions)
    
    a = args
    r = query node, a
    r ? r.any? : r
  end
  
  def select(node, args, xpath_instructions)

    a = node.select args.first

    if xpath_instructions.any? and a.any? then
      
      a.inject([]) do |r, child_node| 
        
        r2 = query(child_node, xpath_instructions.clone)

        if r2.is_a? Rexle::Element then
          r << r2
        elsif r2 == true
          r << child_node
        elsif r2 == false
          r
        else

          if r2.any? then
            r << r2
          else
            r
          end
        end
        
      end
    else
      a
    end    
  end
  
  def value(node, args, xpath_instructions)

    operator, operand = args
    
    r = case operator.to_sym
    when :== then  node.text == operand
    when :>  then  node.value > operand
    when :<  then  node.value < operand
    end

    r
        
  end
  
end