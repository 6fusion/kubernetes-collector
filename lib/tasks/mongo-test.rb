require 'mongoid'
Dir["app/models/*.rb"].each {|file| load file }

Mongoid.load!('config/mongoid.yml', :development)

Machine.destroy_all

machine = Machine.create!({remote_id: "RemoteId1", name: "Test Machine 1", virtual_name: "Visrtual name 1",
						   cpu_count: 1, cpu_speed_mhz: 2, maximum_memory_bytes: 3, tags: [1,2,3], status: "Active"})

puts "---- Machine: #{machine.inspect}"

Disk.destroy_all

disk = machine.disks.create!({remote_id: "RemoteId1", name: "Test Disk 1", maximum_size_bytes: 4, type: "Type1"})

puts "---- Disk: #{disk.inspect}"

Nic.destroy_all

nic = machine.nics.create!({remote_id: "RemoteId1", name: "Test Nic 1", kind: "Kind1", ip_address: "127.0.0.1",
							mac_address: "00:00:00:00:00:00"})

puts "---- Nic: #{nic.inspect}"

MachineSample.destroy_all

machine_sample = machine.machine_samples.create!({reading_at: "2010-10-25 23:48:46 UTC".to_time.iso8601,
								  				  cpu_usage_percent: 1, memory_bytes: 2})

puts "---- Machine Sample: #{machine_sample.inspect}"

DiskSample.destroy_all

disk_sample = disk.disk_samples.create!({reading_at: "2010-10-25 23:48:46 UTC".to_time.iso8601,
								  			usage_bytes: 1, read_kilobytes: 2, write_kilobytes: 3})

puts "---- Disk Sample: #{disk_sample.inspect}"

NicSample.destroy_all

nic_sample = nic.nic_samples.create!({reading_at: "2010-10-25 23:48:46 UTC".to_time.iso8601,
								  	  transmit_kilobits: 1, receive_kilobits: 2})

puts "---- Nic Sample: #{nic_sample.inspect}"

