#!/usr/bin/env ruby

# file: rexle-xpath

require 'rexle-xpath-parser'


module ArrayClone
  
  refine Array do
    
    def deep_clone()
      Marshal.load( Marshal.dump(self) )
    end
    
  end
end

class RexleXPath
  
  using ArrayClone

  def initialize(node=nil, debug: false)

    @node = node
    @debug = debug
    
  end

  def parse(s)

    # it's an xpath function only
    if /^(?<name>\w+)\(\)$/ =~ s
      
      @node.method((name).to_sym).call
      
    # it's an element only
    elsif /^(?<name>\w+)$/ =~ s
      
      select(@node, [name])
      
    else

      xpath_instructions = RexleXPathParser.new(s).to_a
      
      query xpath_instructions, @node
    end
  end

  
  def query(xpath_instructions=[], node=@node)

    debug :query, node: node, xpath_instructions: xpath_instructions

    row = xpath_instructions.shift
    method_name, *args = row    

    return query xpath_instructions, node if row == :|
    
    if row.is_a? Array and row.first.is_a? Array then      
      
      unless row.any? {|x| x == :|} then
        
        return query row + xpath_instructions, node         
      else
  
        a = row

        a2 = a.inject([[]]) do |r, x|

          if x != :| then

            if r.last.is_a? Array then
              r.last << x
            else
              r << [x]
            end

          else
            r.unshift x
            r << []
          end
          r
        end

        name = a2.shift
        r3 =  method(name).call(a2, node)
        return r3
        
      end
    end

    result = if method_name == :predicate then

      result2 = method(method_name.to_sym).call node, args,[]
      
      if result2 and xpath_instructions.any? then
        query xpath_instructions, node
      else
        result2
      end
      
    else

      r3 = method(method_name.to_sym).call node, args, xpath_instructions
      r3
    end

    result.is_a?(Array) ? result.flatten : result

  end 
  
  private
  
  
  def |(args=[], node)
    r = args.flat_map {|x| query x, node}
    r.any?
  end
    
  
  def attribute(node, args, xpath_instructions)

    debug :attribute, args: args, node: node, 
        xpath_instructions: xpath_instructions
    
    key = args.first.is_a?(Array) ? args.first.first.to_sym : args.first.to_sym

    attr = node.attributes[key]
    
    xi = xpath_instructions

    if xi[0] and xi[0][0].to_sym == :value then

      _, operator, value = xi.shift
      attr.method(operator.to_sym).call value
    else
      attr ? Rexle::Element::Attribute.new(attr) : nil
    end
    
    
  end
  
  def count(node, args, xpath_instructions)    
    
    r = query xpath_instructions, node
    [r.length]
  end   
  
  def index(node, args, xpath_instructions)    

    debug :index, node: node, args: args, 
        xpath_instructions: xpath_instructions    
    
    i = args.first.to_i
    r = query xpath_instructions, node

    [r[i-1]]
  end
  
  def not(node, args, xpath_instructions)
    
    r = query xpath_instructions, node
    !(r ? r.any? : r)
  end  
  
  def predicate(node, args, xpath_instructions)
    
    debug :predicate, node: node, args: args, 
        xpath_instructions: xpath_instructions

    r = query args, node

    r.is_a?(Array) ? r.any? : r

  end
  
  def recursive(node, args, xpath_instructions)
    
    xi = args #xpath_instructions

    a = []
    a << query(xi.deep_clone, node)
    
    node.each_recursive {|e| a << query(xi.deep_clone, e) }
    
    a
  end
  
  def select(node, args, xpath_instructions=[])

    debug :select, node: node, args: args, 
        xpath_instructions: xpath_instructions

    selector = args.first
    
    nodes_found = if selector == '*' then
      node.elements.to_a
    elsif selector == '.'
      [node]
    else
      node.elements.select {|x| x.name == selector }
    end

    flat_xpi = xpath_instructions.flatten

    predicate = flat_xpi.first.to_s == 'predicate'
    
    if predicate and flat_xpi[1] == :index then
      
      i = flat_xpi[2].to_i - 1
      return nodes_found[i]
      
    end
    
    if xpath_instructions.any? and nodes_found.any? then

      nodes_found.inject([]) do |r, child_node| 

        # deep clone the xpath instructions
        xi = xpath_instructions.deep_clone
        operand = xi.shift  if xi.first == :|

        r2 = query(xi, child_node)

        r3 = case r2.class.to_s.to_sym
        when :'Rexle::Element' then r << r2
        when :TrueClass        
          predicate ? r << child_node : r << true
        when :FalseClass
          !predicate ? r << false : r
        when :'Rexle::Element::Attribute'
          r << child_node
        when :NilClass
          r
        else
          r2.any? ? r << r2 : r #<< child_node
        end # /case
        
        if operand == :| then
          nodes_found + r3
        else
          r3
        end
        
      end # /inject
      
    elsif xpath_instructions.any? and nodes_found.empty?
      
      operator = xpath_instructions.shift
      
      if operator == :| then
        query xpath_instructions, node
      else
        nodes_found
      end
      
    else
      nodes_found
    end  # /if
    
  end
  
  def value(node, args, xpath_instructions)
    
    debug :value, node: node, args: args, 
        xpath_instructions: xpath_instructions
    
    
    
    operator, operand = args
    
    if operator then
      
      return false unless node.value
      node.value.method(operator.to_sym).call operand
      
    else
      [node.text]
    end
        
  end
  
  alias text value
  
  def debug(method, h={})
    
    return unless @debug
    
    puts
    puts '# inside ' + method.to_s
    h.each {|k,v| puts "... %s: %s" % [k,v.inspect] }
    puts
    
  end
end