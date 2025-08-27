# frozen_string_literal: true

require 'nokogiri'
require 'time'
module PlistLite
  DTD = Dir.chdir(__dir__) do
    Nokogiri::XML::Document.parse(
      IO.read("#{__dir__}/minimal.plist"), nil, nil,
      Nokogiri::XML::ParseOptions.new(Nokogiri::XML::ParseOptions::DTDLOAD)
    )
  end.external_subset

  class << self
    def load(source)
      doc = Nokogiri::XML::Document.parse(
        source, nil, nil,
        Nokogiri::XML::ParseOptions.new(Nokogiri::XML::ParseOptions::STRICT)
      )
      raise doc.errors.first unless doc.errors.empty?

      errors = DTD.validate(doc)
      raise errors.first unless errors.empty?

      load_node(doc.root.elements.first)
    end

    def dump(obj)
      output = +'<?xml version="1.0" encoding="UTF-8"?>' \
      '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' \
      '<plist version="1.0">'
      dump_node(obj, output)
      output << '</plist>'
    end

    private

    def load_node(node)
      case node.name
      when 'dict'
        hash = {}
        node.elements.each_slice(2) do |key_node, value_node|
          hash[key_node.text] = load_node(value_node)
        end
        hash
      when 'array'
        array = []
        node.elements.each { |element| array << load_node(element) }
        array
      when 'integer' then node.text.to_i
      when 'real' then node.text.to_f
      when 'date' then Time.iso8601(node.text)
      when 'string' then node.text
      when 'data' then node.text.unpack1('m')
      when 'true' then true
      when 'false' then false
      end
    end

    def dump_node(obj, output)
      case obj
      when Hash
        output << '<dict>'
        obj.each do |key, value|
          case key
          when String then output << "<key>#{key.encode(xml: :text)}</key>"
          when Symbol then output << "<key>#{key}</key>"
          else output << "<key>#{key}</key>"
          end
          dump_node(value, output)
        end
        output << '</dict>'
      when Array
        output << '<array>'
        obj.each { |i| dump_node(i, output) }
        output << '</array>'
      when Symbol then output << "<string>#{obj}</string>"
      when String
        output <<
          case obj.encoding
          when Encoding::ASCII_8BIT then "<data>#{[obj].pack('m')}</data>"
          when Encoding::UTF_8 then "<string>#{obj.encode(xml: :text)}</string>"
          else "<string>#{obj.encode(Encoding::UTF_8, xml: :text)}</string>"
          end
      when Integer then output << "<integer>#{obj}</integer>"
      when Float then output << "<real>#{obj}</real>"
      when true then output << '<true/>'
      when false then output << '<false/>'
      when Time then output << "<date>#{Time.at(obj).utc.iso8601}</date>"
      when DateTime then output << "<date>#{obj.to_time.utc.iso8601}</date>"
      when Date
        warn 'Consider not using Date object because it does not contain time zone information'
        output << "<date>#{obj.iso8601}T00:00:00Z</date>"
      else raise ArgumentError, "unknown type: #{obj.class}"
      end
    end
  end
end

require 'plist_lite/ext'
