# This class is responsible for collecting all cluster inventory including the infrastructure information
# as well as the containers running into it
class InventoryCollector

  def initialize(config)
    @config = config
    @data = { running_machines_vnames: [] }
    @hosts = {}
  end

  def collect
    $logger.info 'Collecting inventory'
    infrastructure = collect_infrastructure
    # Collect the pods for this infrastructure so we can update their machines information
    namespaces.each{|namespace|
      collect_pods(infrastructure, namespace)
        .each{|pod|
          collect_containers(pod) }}

    # Power off dead machines so they are not metered anymore
    poweroff_dead_machines
  end

  def collect_infrastructure
    $logger.info 'Collecting infrastructure info'
    # FIXME move to defaults... or maybe a sidecar
    raise "Missing user-defined infrastructure name" if ENV['INFRASTRUCTURE_NAME'].nil? or ENV['INFRASTRUCTURE_NAME'].empty?
    infrastructure_name = ENV['INFRASTRUCTURE_NAME']
    # Does the infrastructure exist?
    begin
      infrastructure = Infrastructure.find_by(name: infrastructure_name)
    rescue Mongoid::Errors::DocumentNotFound
      infrastructure = Infrastructure.new(name: infrastructure_name)
      $logger.info { "Creating #{infrastructure_name} infrastructure" }
    end
    infrastructure.tags = ['platform:kubernetes', 'collector:kubernetes']
    infrastructure.save! # Need to save here to avoid child saving before parent issue

    # Clear infrastructure networks information so we can refresh it
    infrastructure.networks.destroy_all
    host_count = infrastructure.hosts.size
    internal_network = infrastructure.networks.new(name: "internal_network",
                                                   kind: 'LAN',
                                                   speed_bits_per_second: speed_for(kind: :lan, host_count: host_count))
    storage_network = infrastructure.networks.new(name: "storage_network", 
                                                  kind: 'SAN',
                                                  speed_bits_per_second: speed_for(kind: :disk, host_count: host_count))
    external_network = infrastructure.networks.new(name: "external_network",
                                                   kind: 'WAN',
                                                   speed_bits_per_second: speed_for(kind: :disk, host_count: host_count))
    network_speeds = []
    # Clear infrastructure hosts information so we can refresh it
    infrastructure.hosts.each do |host|
      host.host_cpus.destroy_all
      host.host_nics.destroy_all
      host.host_disks.destroy_all
    end
    infrastructure.hosts.destroy_all
    # Recreate hosts information
    nodes_response = KubeAPI::nodes(@config)
    $logger.debug { "Found #{nodes_response.count} node#{nodes_response.count > 1 ? 's' : ''}" }

    nodes_response['items'].each do |node|

      node_name = node['metadata']['name']
      node_ip = node['status']['addresses'].find{|addy| addy['type'].eql?('InternalIP')}['address']
      available_cores = node['status']['allocatable']['cpu']
      begin
        kube_node_attributes = KubeAPI::node(@config, node_name)
        cadvisor_node_attributes = KubeletAPI::node_attributes(@config, node_ip)
        # host = infrastructure.hosts.create(ip_address: node_ip, memory_bytes: node_attributes['memory_capacity'])
        host = infrastructure.hosts.create(ip_address: kube_node_attributes['status']['addresses'][0]['address'],
                                           name: kube_node_attributes['metadata']['name'],
                                           memory_bytes: kube_node_attributes['status']['allocatable']['memory'].to_i * 1000)

        host.host_cpus.create(cores: kube_node_attributes['status']['allocatable']['cpu'],
                              speed_hz: cadvisor_node_attributes['cpu_frequency_khz'] * 1000)
        cadvisor_node_attributes['filesystems'].each {|fs| host.host_disks.create(name: fs['device'].split('/').last, storage_bytes: fs['capacity'])}
        if cadvisor_node_attributes['network_devices']
          cadvisor_node_attributes['network_devices'].each do |nd|
            nd_speed = nd['speed'].to_i * 10**6
            host.host_nics.create(name: nd['name'], speed_bits_per_second: nd_speed)
            network_speeds << nd_speed
          end
        else
          $logger.warn { "No network_devices reported for #{node_ip}" }
          $logger.debug { "Node attributes for #{node_ip}: kubernetes: #{kube_node_attributes}\ncadvisor: #{cadvisor_node_attributes}" }
        end
        @hosts[node_ip] = host
      rescue => e
        $logger.warn { "Could not collect attributes from host #{node_ip}." }
        $logger.error { e.message }
        $logger.error { e.backtrace.join("\n") }
      end
    end
    internal_network.speed_bits_per_second = network_speeds.max unless network_speeds.empty?
    storage_network.save!
    external_network.save!
    infrastructure.save!
    infrastructure.reload
    infrastructure
  end

  def collect_containers(pod)
    $logger.info { "Collecting containers for pod #{pod.namespace}/#{pod.name}" }
    $logger.debug { "Pod: #{pod.inspect}" }
    pod_status = KubeAPI::pod_status(@config, pod)
    any_container = nil  # save one container from this pod to use in initializing our fake pod infrastructure container as the last step

    pod_status['containerStatuses'].each do |container|
      unless @hosts.has_key?(pod_status['hostIP'])
        $logger.warn { "No node data for #{pod.name}. Skipping. " }
        next
      end
      container_id = container['containerID']&.sub('docker://', '')
      container_name = container['name']
      container_image = container['image']

      next unless container_id and container_name and container_image

      container_hash = container_id[0..11] # note: the 'io.kubernetes.container.hash' is not especially unique

      machine = Machine.find_or_initialize_by(custom_id: container_id)

      machine.host_ip = pod_status['hostIP']  # FIXME should this be pod.host_ip?
      host = @hosts[machine.host_ip]

      machine.name = "#{container_name}-#{container_hash}"
      machine.custom_id = container_id
      machine.container_name = container_name
      machine.pod_name = pod.name
      machine.pod_uid = pod.uid
      machine.pod_ip = pod.ip
      machine.namespace = pod.namespace
      machine.is_pod_container = false
      # TODO checky ready containers for status?
      machine.status = case pod.status
                       when 'Running' then 'poweredOn'
                       when 'Succeeded' then 'Deleted'
                       else pod.status
                       end

      machine.tags += ["image:#{container_image}"]
      machine.tags += ["service:#{services[pod.ip]}"] if services.key?(pod.ip)

      memory_capacity = host.memory_bytes  # this is wrong? doesn't factor in quotas?  # kube_node_attributes['memory_capacity']
      machine.cpu_count = host.host_cpus.size   # quotas?
      machine.cpu_speed_hz = host.host_cpus.first.speed_hz  # quotas?
      machine.memory_bytes = memory_capacity

      machine.save!

      any_container = machine

      @data[:running_machines_vnames] << machine.custom_id

      collect_machine_disks(machine, 1) #storage_bytes)
      collect_machine_nics(machine)
    end

    if any_container
      infrastructure_pod = Machine.find_or_create_by(name: pod.name,
                                                     custom_id: pod.uid,
                                                     namespace: pod.namespace,
                                                     host_ip: pod.host_ip,
                                                     pod_ip: pod.ip,
                                                     is_pod_container: true,
                                                     pod_uid: pod.uid,
                                                     pod_name: pod.name,
                                                     cpu_count: any_container.cpu_count,
                                                     cpu_speed_hz: any_container.cpu_speed_hz,
                                                     memory_bytes: any_container.memory_bytes)
      $logger.info { "Saving POD container #{infrastructure_pod.name}/#{infrastructure_pod.custom_id}" }

      infrastructure_pod.tags += ['role:pod-infrastructure']
      infrastructure_pod.status = any_container.status
      infrastructure_pod.save!
      collect_machine_disks(infrastructure_pod, 1) #storage_bytes)
      collect_machine_nics(infrastructure_pod)

      @data[:running_machines_vnames] << infrastructure_pod.custom_id
    end
  end

  def collect_pods(infrastructure, namespace)
    $logger.info { "Collecting pods for infrastructure #{infrastructure.name}" }
    response = KubeAPI::pods(@config, namespace)
    response['items'].map{|pod_json|
      Pod.find_or_create_by(pod_json) }
  end

  def services
    @services ||=
      begin
        ip_to_service = {}
        services = KubeAPI::endpoints(@config)['items'].map{|item| Service.new(item)}
        services.each{|service|
          service.pod_ips.each{|ip| ip_to_service[ip] = service.name } }
        ip_to_service
      end
  end

  def collect_machine_disks(machine, storage_bytes)
    $logger.info { "Collecting disks for container #{machine.name}" }

    disk_name = "disk-#{machine.custom_id[0...8]}"
    disk = machine.disks.find_or_initialize_by(name: disk_name)
    disk.machine = machine
    if ( (disk.storage_bytes != storage_bytes) or
         disk.status != 'Active')
      disk.storage_bytes = storage_bytes
      disk.status = 'Active'
      disk.machine = machine
      disk.save!
    end
  end

  def collect_machine_nics(machine)
    $logger.info { "Collecting nics for machine #{machine.name}" }
    nic_name = "nic-#{machine.custom_id[0...8]}"
    nic = machine.nics.find_or_initialize_by(name: nic_name, kind: 'LAN', status: 'Active')
    nic.save!
  end

  def collect_disk_storage_bytes(disk_map)
    storage_bytes = 0
    disk_map.values.each do |v|
      storage_bytes += v['size']
    end
    storage_bytes
  end


  def poweroff_dead_machines
    $logger.info { "Count of running containers: #{@data[:running_machines_vnames].size}" }
    dead_machines = Machine.where(:custom_id.nin => @data[:running_machines_vnames], :status.ne => 'Deleted')
    $logger.info { "Powering off #{dead_machines.count} dead containers" }
    dead_machines.each do |dm|
      dm.disks.update_all(status: 'Deleted')
      dm.nics.update_all(status: 'Deleted')
    end
    dead_machines.update_all(status: 'Deleted')
  end

  def speed_for(kind:, host_count:)
    case kind
    when :lan  then (ENV['DEFAULT_LAN_IO']  || 10).to_i
    when :wan  then (ENV['DEFAULT_WAN_IO']  || 1).to_i
    when :disk then (ENV['DEFAULT_DISK_IO'] || 10).to_i
    end * 1e9 * host_count  # convert from giga, x by hosts
  end


  def namespaces
    @namespaces ||= begin
                      $logger.info { 'Collecting namespaces...' }
                      response = KubeAPI::namespaces(@config)
                      response['items']
                    end
  end
# define logs 



end
