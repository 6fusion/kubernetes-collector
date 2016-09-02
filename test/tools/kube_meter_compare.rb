#!/usr/bin/env ruby
# Script to easily compare containers in Kubernetes 'spec' api to machines in a 6fusion OP meter API
# 8/17/16 Bob S.

require 'rest-client'
require 'trollop'
require 'pry'

Default_kube_url  = 'http://54.183.194.114:4194/api/v2.0/spec/?type=docker&recursive=true'
Default_meter_url = 'http://ab5ec009b60c911e69b73026e4be77e2-790933066.us-west-1.elb.amazonaws.com/api/v1'

# Constants
Org=0; Inf=1; Mach=2;

machs = []
containers = []

opts = Trollop.options do 
    banner <<-EOS

kube_meter_compare:  Compare Kubernetes containers with machines on an On-prem meter.  Used to
                     verify the Kubernetes collector.
Usage:
    ruby kube_meter_compare.rb [options]

Where [options] are:
EOS
    # Don't use a -n option, doesn't seem to work on short form?
    opt :kube, 'Kubernetes spec API url', :default => Default_kube_url
    opt :meter, '6fusion meter API url', :default => Default_meter_url
end

# To colorize log output
class String
    def red;    "\033[31m#{self}\033[0m" end
    def green;  "\033[32m#{self}\033[0m" end
end

# Get url
def get_url (url, type)

    puts"#{type} URL: #{url}"

    # GET request from API
    begin
        response = RestClient.get url
    rescue => e
        puts "  #{JSON.parse(e.response)["message"]}  (#{e.message})"
        JSON.parse(e.response)["errors"].each do 
            |err| puts "  #{err}".red 
        end
        abort "Aborting!"
    end
    # Convert JSON response to a hash using symbols
    resp_hash = JSON.parse(response, symbolize_names: true)
    
    return resp_hash    
end

#### Main ####

# Get list of containers from Kube API
resp_hash = get_url(opts[:kube], "Kube")
ccount = resp_hash.length

if ccount > 0

    for i in 0..ccount - 1

        cname = resp_hash.values[i][:labels][:"io.kubernetes.container.name"]
        # Meter calls 'POD' a 'container' for some reason
        cname = "container" if cname == "POD"

        # trunc container id to 8 chars
        cid = resp_hash.values[i][:aliases][1][0..7]
        mid = cid[0..7]

        # Meter has mach field 'name' set to 'alias-id'
        mname = "#{cname}-#{mid}"

        #puts "#{i} - #{mname}"
        containers.push(mname)
    end
else
    puts "No Kube data found!"
end

# Get list of machines from Meter API
resp_hash = get_url("#{opts[:meter]}/machines.json", "Meter")
mcount = resp_hash[:embedded][:machines].length

if mcount > 0

    for i in 0..mcount -1
        #puts "#{i} - #{resp_hash[:embedded][:machines][i][:name]} - #{resp_hash[:embedded][:machines][i][:status]}"
        # Put all mach names in an array
        machs.push([resp_hash[:embedded][:machines][i][:name], resp_hash[:embedded][:machines][i][:status]])
    end
else
    puts "No meter machines found!"
end

# Compare the mach array with the containers array
machs.each do |mach|

    if containers.include?(mach[0])
        result = "YES"
    else 
        result = "NO"
    end
    mach.push(result)
end

# Add a record as a test of this code
#machs.push(["capacity-calculator-e8ca96ed","poweredOff","YES"])

# Sort by result (in reverse) then by name
machs = machs.sort_by { |a| [ a[2] ,  a[0] ] }.reverse

puts
line_format = "%-35.35s %-12.12s %-8.8s"
puts sprintf(line_format, 'Machine Name','Status','Match?').green

# Output & count
match_cnt = 0
machs.each do |mach|

    # Highlight potential mismatches in red
    if mach[2] == 'YES' && mach[1] == "poweredOn"
        match_cnt += 1 
        puts sprintf(line_format, mach[0], mach[1], mach[2])
    elsif mach[2] == 'NO' && mach[1] == "poweredOff"
        puts sprintf(line_format, mach[0], mach[1], mach[2])
    else
        puts sprintf(line_format, mach[0], mach[1], mach[2]).red
    end
end

# Compare counts and output
if match_cnt == ccount
    puts "Machines that match kube containers: #{match_cnt} of #{ccount}".green
else
    puts "Machines that match kube containers: #{match_cnt} of #{ccount}".red
end

#binding.pry

