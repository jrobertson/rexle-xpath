# Introducing the Rexle-xpath gem

This gem is designed for returning an XPath result from an XPath and a XML node e.g.

    require 'rexle'
    require 'rexle-xpath'

    doc = Rexle.new("<a><b>234<c><d></d></c></b></a>")
    xp = RexleXPath.new doc.root
    xp.parse 'name()'


It can also work with a REXML document

    require 'rexle-xpath'
    require 'rexml/document'
    include REXML

    doc = Document.new("<a><b>234<c><d></d></c></b></a>")
    xp = RexleXPath.new doc.root
    xp.parse 'name()'

## Resources

* ?rexle-xpath https://rubygems.org/gems/rexle-xpath?

rexlexpath gem xpath xml rexle
