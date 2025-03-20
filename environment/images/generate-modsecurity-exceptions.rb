#!/bin/ruby

# Takes a YaML file describing mod security exceptions and generates a .conf file
# of the correct format for the modsecurity module. Format of the YAML file is broadly:
# 	version: '1'
# 	exceptions:
#    		not_field_based:
#        		rules:
#            			- 1
#    		some_fields:
#        		fields:
#            			- ARGS:A
#            			- ARGS:/B\[.*\]/
#	    			- REQUEST_HEADERS
#        		rules:
#            			- 2
#            			- 3
# Which would generate the following modsecurity exceptions:
#	SecRuleRemoveById 1
#	SecRuleUpdateTargetById 2 !ARGS:A 
#	SecRuleUpdateTargetById 2 !ARGS:B
#	SecRuleUpdateTargetById 2 !REQUEST_HEADERS
#	SecRuleUpdateTargetById 3 !ARGS:A 
#	SecRuleUpdateTargetById 3 !ARGS:B
#	SecRuleUpdateTargetById 3 !REQUEST_HEADERS

require 'yaml'
require 'date'

def merge_rules!(a, b)
  a.merge!(b){ |key,oldval,newval| oldval | newval }
end

def transform_rule(rule, fields)
	transformed = Hash.new []
	if rule.to_s.include? "-"
		range = rule.split("-").map(&:to_i)
		(range[0]..range[1]).each do |n|
			merge_rules!(transformed, transform_rule(n, fields))
		end
	elsif fields.nil?
		transformed[rule] = nil
	else
		fields.each { |f| transformed[rule] += [f] }
	end
	return transformed
end

def transform_exceptions(exception_dict)
	transformed = Hash.new
	exception_dict['rules'].each { |r| merge_rules!(transformed, transform_rule(r, exception_dict['fields'])) }
	return transformed
end

def write_rule(rule, fields, file)
	if fields.nil?
		file.puts "SecRuleRemoveById "+rule.to_s
	else
		fields.each { |f| file.puts "SecRuleUpdateTargetById " + rule.to_s + " !" + f}
	end
	file.puts
end

def write_rules(rules, src_file, output_file)
	File.open(output_file, "w") do |h|
		h.puts "# File generated from " + src_file + " at " + DateTime.now().strftime("%d/%m/%Y %H:%M")
		h.puts
		rules.each { |r,f| write_rule r, f, h}
	end
end

# Check command line arguments, we've got 3 or 4 of them, and that the files exist)
*arguments = ARGV
raise "This script requires 2 arguments. The first is the location of the modsecurity exception file, and the 2nd is where to place the generated file" unless arguments.length == 2
raise "Unable to locate the modsecurity exception file: "+arguments[0] unless File.exists?(arguments[0])

# load the modsecurity exception file
template = YAML.load_file(arguments[0])
exceptions = template['exceptions']
rules = Hash.new

exceptions.each { |k,v| merge_rules!(rules, transform_exceptions(v)) }
write_rules Hash[rules.sort], arguments[0], arguments[1]
