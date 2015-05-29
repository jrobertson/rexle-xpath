#!/usr/bin/env ruby

# file: rexle-xpath


class RexleXPath

  def initialize(node=nil)

    @node = XPathObject.new(node)

  end

  def parse(s)

    case s
    when /^(\w+)\(\)$/
      @node.method(($1).to_sym).call
    end
  end

  def query()

    @nodes.each do |node|
    end

  end

  class XPathObject

    def initialize(element)
      @element = element
    end

    def name()
      @element.name()
    end

    def text()
      @element.text()
    end

  end

end
