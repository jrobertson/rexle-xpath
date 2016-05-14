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

    case s
      
    # it's an xpath function
    when /^(\w+)\(\)$/
      @node.method(($1).to_sym).call
    else
      a = RexleXPathParser.new(s).to_a
      #puts 'a: ' + a.inspect
      query @node, a
    end
  end

  def query(node=@node, xpath_instructions)

    debug :query, node: node, xpath_instructions: xpath_instructions

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
    attr = node.attributes[key]
    
    xi = xpath_instructions

    if xi[0] and xi[0][0].to_sym == :value then
      
      _, operator, value = xi.shift
      attr.method(operator.to_sym).call value
    else
      attr ? true : false      
    end
    
    
  end
  
  def not(node, args, xpath_instructions)
    
    r = query node, xpath_instructions
    !(r ? r.any? : r)
  end  
  
  def predicate(node, args, xpath_instructions)
    
    debug :predicate, node: node, args: args, 
        xpath_instructions: xpath_instructions

    r = query node, args
    r.is_a?(Array) ? r.any? : r

  end
  
  def recursive(node, args, xpath_instructions)
    
    xi = args #xpath_instructions

    a = []
    a << query(node, xi.deep_clone)
    
    node.each_recursive do |e|
      a << query(e, xi.deep_clone)
    end    
    
    a
  end
  
  def select(node, args, xpath_instructions)

    a = node.elements.select {|x| x.name == args.first }
    predicate = xpath_instructions.flatten.first.to_s == 'predicate'

    if xpath_instructions.any? and a.any? then
      
      a.inject([]) do |r, child_node| 

        # deep clone the xpath instructions
        xi = xpath_instructions.deep_clone
        
        r2 = query(child_node, xi)

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
    
    node.value.method(operator.to_sym).call operand
        
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