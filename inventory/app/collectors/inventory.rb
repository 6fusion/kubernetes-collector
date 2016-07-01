# This class is responsible for collecting all cluster inventory including the infrastructure information
# as well as the containers running into it
class InventoryCollector

  CONTAINER_NAME_PREFIX = 'container-'

  def initialize(logger, config)
    @logger = logger
    @config = config
    @data = { running_machines_vnames: [] }
  end

  def collect
    @logger.info 'Collecting inventory...'
    infrastructure = collect_infrastructure
    on_prem_machines = collect_on_prem_machines(infrastructure)
    collect_machines(infrastructure, on_prem_machines)
    # Collect the pods for this infrastructure so we can update their machines information
    collect_pods(infrastructure).each {|pod| update_pod_machines(pod)}
    # If there are pods that belong to a service, then tag their machines with the corresponding service
    tag_service_pods_machines
    # Power off dead machines so they are not metered anymore
    poweroff_dead_machines
    # Reset metering status if all running machines have been metered
    reset_machines_metering_status
  end

  def collect_infrastructure
    @logger.info 'Collecting infrastructure info...'
    attributes = CAdvisorAPI::request(@config, @config.kube[:cadvisor_host], 'attributes')
    infrastructure_name = "#{attributes['system_uuid'][0..7]}_#{attributes['machine_id'][0..8]}"
    # Does the infrastructure exist?
    begin
      infrastructure = Infrastructure.find_by(name: infrastructure_name)
      # If the infrastructure's organization doesn't match the config organization, then
      # delete everything and start from scratch
      reset_cache_db if infrastructure.organization_id != @config.on_premise[:organization_id]
    rescue Mongoid::Errors::DocumentNotFound
      infrastructure = Infrastructure.create(name: infrastructure_name,
                                             organization_id: @config.on_premise[:organization_id],
                                             tags: %w(kubernetes-collector))
    end
    # Clear host information so we can refresh it
    infrastructure.hosts.each do |host|
      host.host_cpus.destroy_all
      host.host_nics.destroy_all
      host.host_disks.destroy_all
    end
    infrastructure.hosts.destroy_all
    # Recreate hosts information
    nodes_response = KubeAPI::request(@config, 'nodes')
    nodes_response['items'].each do |node|
      node_ip = node['status']['addresses'][0]['address']
      begin
        node_attributes = CAdvisorAPI::request(@config, node_ip, 'attributes')
        host = infrastructure.hosts.create(ip_address: node_ip, memory_bytes: node_attributes['memory_capacity'], infrastructure: infrastructure)
        host.host_cpus.create(cores: node_attributes['num_cores'], speed_hz: node_attributes['cpu_frequency_khz'] * 1000)
        node_attributes['filesystems'].each {|fs| host.host_disks.create(name: fs['device'].split('/').last, storage_bytes: fs['capacity'])}
        node_attributes['network_devices'].each {|nd| host.host_nics.create(name: nd['name'])}
      rescue Exception
        @logger.warn "Could not collect attributes from host #{node_ip}. CAdvisor is not enabled. Skipping..."
      end
    end
    # Look for the remote_id of the infrastructure (if it exists on the on-prem db)
    OnPremiseApi::request_api('infrastructures', :get, @config, {organization_id: infrastructure.organization_id})['embedded']['infrastructures'].each do |i|
      if infrastructure.name.eql? i['name']
        infrastructure.remote_id = i['id']
        break
      end
    end
    infrastructure.save!
    infrastructure.reload
    infrastructure
  end

  def collect_machines(infrastructure, on_prem_machines)
    on_prem_disks = collect_machine_resources('disks')
    on_prem_nics = collect_machine_resources('nics')
    infrastructure.hosts.each do |host|
      @logger.info "Collecting machines for host #{host.ip_address}..."
      response = CAdvisorAPI::request(@config, host.ip_address, 'stats/?type=docker&recursive=true&count=1')
      response.each do |k,v|
        container_id = k.split('/').last.split('docker-').last.split('.scope').first
        # Is this a new or an existing machine?
        begin
          machine = Machine.find_by(virtual_name: container_id)
        rescue Mongoid::Errors::DocumentNotFound
          machine = Machine.new(virtual_name: container_id, name: "#{CONTAINER_NAME_PREFIX}#{container_id[0...8]}")  # The container name might be updated later if this container is attached to a pod
        end
        machine.status = 'poweredOn'  # Containers retrieved through cAdvisor are running by default
        machine.tags = ['type:container', 'platform:kubernetes']
        host_attributes = CAdvisorAPI::request(@config, host.ip_address, 'attributes')
        machine.host_ip_address = host.ip_address
        machine.cpu_count = host_attributes['num_cores']
        machine.cpu_speed_hz = host_attributes['cpu_frequency_khz'] * 1000
        machine.memory_bytes = host_attributes['memory_capacity']
        machine.remote_id = get_machine_remote_id(machine, on_prem_machines)
        machine.save!

        @data[:running_machines_vnames] << machine.virtual_name

        disk_map = host_attributes['disk_map']
        storage_bytes = collect_disk_storage_bytes(disk_map)

        collect_machine_disks(machine, storage_bytes, on_prem_disks)
        collect_machine_nics(machine, on_prem_nics)
      end
    end
    @logger.info "Total of infrastructure machines: #{Machine.count}."
  end

  def collect_pods(infrastructure)
    @logger.info 'Collecting pods for the infrastructure...'
    response = KubeAPI::request(@config, 'pods')
    response['items'].each do |pod|
      # Is this a new or an existing pod?
      begin
        db_object = Pod.find_by(name: pod['metadata']['name'])
      rescue Mongoid::Errors::DocumentNotFound
        db_object = Pod.create(name: pod['metadata']['name'], infrastructure: infrastructure)
      end
      pod['db_object'] = db_object
    end
    response['items']
  end

  def update_pod_machines(pod)
    @logger.info "Updating machines for pod=#{pod['metadata']['name']}..."
    if pod['status']['phase'] == 'Running'
      pod['status']['containerStatuses'].each do |container|
        if container['ready']
          container_id = container['containerID'].split("//").last
          # Look for this machine in the cache db
          begin
            machine = Machine.find_by(virtual_name: container_id)
          rescue Mongoid::Errors::DocumentNotFound
            next
          end
          machine.name = "#{container['name']}-#{container_id[0...8]}"
          machine.status = 'poweredOn'
          machine.tags = machine.tags + ["pod:#{pod['metadata']['name']}"]
          machine.pod = pod['db_object']
          machine.save!
        end
      end
    end
  end

  def tag_service_pods_machines
    @logger.info 'Collecting services for the infrastructure...'
    response = KubeAPI::request(@config, 'services')
    response['items'].each do |service|
      next if service['spec']['selector'].nil?
      @logger.info "Collecting pods for service=#{service['metadata']['name']}..."
      label_selector = ''
      service['spec']['selector'].each {|k, v| label_selector << "#{k}=#{v},"}
      label_selector = label_selector.to_s.chop  # Remove the last comma from the label selector
      service_pods_response = KubeAPI::request(@config, "pods?labelSelector=#{label_selector}")
      service_pods_response['items'].each do |service_pod|
        Pod.in(name: service_pod['metadata']['name']).each do |pod|
          pod.machines.update(tags: ['type:container', 'platform:kubernetes', "pod:#{service_pod['metadata']['name']}", "service:#{service_pod['metadata']['name']}"])
        end
      end
    end
  end

  def collect_machine_disks(machine, storage_bytes, on_prem_disks)
    @logger.info "Collecting disks for machine=#{machine.name}..."
    disk_name = "disk-#{machine.virtual_name[0...8]}"
    # Is this a new or an existing disk?
    begin
      disk = machine.disks.find_by(name: disk_name)
    rescue Mongoid::Errors::DocumentNotFound
      disk = machine.disks.new(name: disk_name, storage_bytes: storage_bytes)
    end
    disk.remote_id = get_resource_remote_id('disks', machine, disk_name, on_prem_disks)
    disk.machine = machine
    disk.save!
  end

  def collect_machine_nics(machine, on_prem_nics)
    @logger.info "Collecting nics for machine=#{machine.name}..."
    nic_name = "nic-#{machine.virtual_name[0...8]}"
    # Is this a new or an existing nic?
    begin
      nic = machine.nics.find_by(name: nic_name)
    rescue Mongoid::Errors::DocumentNotFound
      nic = machine.nics.new(name: nic_name, kind: 'LAN')
    end
    nic.remote_id = get_resource_remote_id('nics', machine, nic_name, on_prem_nics)
    nic.machine = machine
    nic.save!
  end

  def collect_disk_storage_bytes(disk_map)
    storage_bytes = 0
    disk_map.values.each do |v|
      storage_bytes += v['size']
    end

    storage_bytes
  end

  def collect_on_prem_machines(infrastructure)
    infrastructure.remote_id ?
      OnPremiseApi::request_api('machines', :get, @config, {organization_id: @config.on_premise[:organization_id],
                                                           infrastructure_id: infrastructure.remote_id})['embedded']['machines']
      :
      []
  end

  def get_machine_remote_id(machine, on_prem_machines)
    remote_id = nil
    on_prem_machines.each do |opm|
      if machine.name.eql? opm['name']
        remote_id = opm['id']
        break
      end
    end
    remote_id
  end

  def collect_machine_resources(type)
      OnPremiseApi::request_api(type, :get, @config)['embedded'][type]
  end

  def get_resource_remote_id(type, machine, name, on_prem_resources)
    remote_id = nil
    on_prem_resources.each do |opr|
      if name.eql? opr['name']
        remote_id = opr['id']
        break
      end
    end if machine.remote_id
    remote_id
  end

  def poweroff_dead_machines
    @logger.info 'Powering off dead machines...'
    Machine.where(:virtual_name.nin => @data[:running_machines_vnames]).update_all(status: 'poweredOff')
  end

  def reset_machines_metering_status
    @logger.info 'Verifying the metering status of machines...'
    pending_machines_count = get_pending_machines.count
    if pending_machines_count > 0
      # Do not do anything if there are still machines to be metered on in-process metering
      @logger.info "There are still #{pending_machines_count} machines left to be metered. They will be checked on the next run."
    else
      @logger.info 'All machines are ready for metrics. Preparing them to be metered again...'
      get_ready_machines.update_all(metering_status: 'PENDING', last_metering_start: nil, locked: false, locked_by: '')
    end
  end

  def get_pending_machines
    Machine.where(status: 'poweredOn')
      .or(
        { metering_status: 'PENDING' },
        { metering_status: 'METERING', :last_metering_start.gt => Time.now - METERING_TIMEOUT }
      )
  end

  def get_ready_machines
    Machine.where(status: 'poweredOn')
      .or(
        { :metering_status.in => [nil, 'METERED'] },
        { metering_status: 'METERING', :last_metering_start.lte => Time.now - METERING_TIMEOUT }
      )
  end

  def reset_cache_db
    NicSample.destroy_all
    DiskSample.destroy_all
    MachineSample.destroy_all
    Nic.destroy_all
    Disk.destroy_all
    Machine.destroy_all
    Pod.destroy_all
    HostNic.destroy_all
    HostDisk.destroy_all
    HostCpu.destroy_all
    Host.destroy_all
    Infrastructure.destroy_all
    raise Mongoid::Errors::DocumentNotFound
  end

end