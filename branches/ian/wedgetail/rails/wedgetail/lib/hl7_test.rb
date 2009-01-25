#!/usr/bin/ruby

require 'hl7/message'

pp HL7::Message.parse(STDIN.read)
