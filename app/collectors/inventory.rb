class InventoryCollector

  def initialize
  end

  def collect(logger, config)
    namespaces = []
    pods = []
    machines = []
    logger.info 'Collecting inventory...'
    verify_organization(logger, config)
    infrastructure = collect_infrastructure(logger, config)
    on_prem_machines = collect_on_prem_machines(config, infrastructure)
    namespaces = collect_namespaces(logger, config)
    logger.info "Collected #{namespaces.count} namespaces."
    namespaces.each do |namespace|
      # Collect the pods for this namespace
      collect_pods(logger, config, namespace).each do |pod|
        collect_machines(logger, config, pod, on_prem_machines).each {|machine| machines << machine}
        pods << pod
      end
      # If there are pods that belong to a service, then tag their machines with the corresponding service
      tag_service_pods_machines(logger, config, namespace)
    end
    logger.info "Collected #{pods.count} pods."
    logger.info "Collected #{machines.count} machines."
  end

  def verify_organization(logger, config)
    begin
      # Verify that the Organization exists in the On Premise API. Otherwise, raise an exception.
      response = OnPremiseApi::request_api("organizations/#{config.on_premise[:organization_id]}", :get, config)
    rescue Exception => e
      raise Exception.new(e.response ? JSON.parse(e.response)['message'] : e)
    end
  end

  def collect_infrastructure(logger, config)
    logger.info 'Collecting infrastructure info...'
    attributes = CAdvisorAPI::request(config, config.kube[:host], 'attributes')
    infrastructure_name = "#{attributes['system_uuid'][0..7]}_#{attributes['machine_id'][0..8]}"
    # Does the infrastructure exist?
    begin
      infrastructure = Infrastructure.find_by(name: infrastructure_name)
    rescue Mongoid::Errors::DocumentNotFound
      infrastructure = Infrastructure.create(name: infrastructure_name,
                                             organization_id: config.on_premise[:organization_id],
                                             tags: %w(kubernetes-collector))
    end
    # Clear host information so we can refresh it
    infrastructure.hosts.each do |host|
      host.host_cpus.delete_all
      host.host_nics.delete_all
      host.host_disks.delete_all
    end
    infrastructure.hosts.delete_all
    # Recreate host information
    host = infrastructure.hosts.create(memory_bytes: attributes['memory_capacity'], infrastructure: infrastructure)
    host.host_cpus.create(cores: attributes['num_cores'], speed_hz: attributes['cpu_frequency_khz'] * 1000)
    attributes['filesystems'].each {|fs| host.host_disks.create(name: fs['device'].split('/').last, storage_bytes: fs['capacity'])}
    attributes['network_devices'].each {|nd| host.host_nics.create(name: nd['name'])}
    # Look for the remote_id of the infrastructure (if it exists on the on-prem db)
    begin
      OnPremiseApi::request_api('infrastructures', :get, config, {organization_id: infrastructure.organization_id})['embedded']['infrastructures'].each do |i|
        if infrastructure.name.eql? i['name']
          infrastructure.remote_id = i['id']
          break
        end
      end
    rescue Exception => e
      raise Exception.new(e.response ? JSON.parse(e.response)['message'] : e)
    end
    infrastructure.save!
    infrastructure
  end

  def collect_namespaces(logger, config)
    logger.info 'Collecting namespaces...'
    response = KubeAPI::request(config, 'namespaces')
    response['items']
  end

  def collect_pods(logger, config, namespace)
    logger.info "Collecting pods for namespace=#{namespace['metadata']['name']}..."
    response = KubeAPI::request(config, "namespaces/#{namespace['metadata']['name']}/pods")
    response['items'].each do |pod|
      # Is this a new or an existing pod?
      begin
        db_object = Pod.find_by(name: pod['metadata']['name'])
      rescue Mongoid::Errors::DocumentNotFound
        db_object = Pod.create(name: pod['metadata']['name'])
      end
      pod['db_object'] = db_object
    end
    response['items']
  end

  def tag_service_pods_machines(logger, config, namespace)
    logger.info "Collecting services for namespace=#{namespace['metadata']['name']}..."
    response = KubeAPI::request(config, "namespaces/#{namespace['metadata']['name']}/services")
    response['items'].each do |service|
      logger.info "Collecting pods for service=#{service['metadata']['name']}..."
      label_selector = ''
      service['spec']['selector'].each {|k, v| label_selector << "#{k}=#{v},"} unless service['spec']['selector'].nil?
      label_selector = label_selector.to_s.chop  # Remove the last comma from the label selector
      service_pods_response = KubeAPI::request(config, "namespaces/#{namespace['metadata']['name']}/pods?labelSelector=#{label_selector}")
      service_pods_response['items'].each do |service_pod|
        Pod.in(name: service_pod['metadata']['name']).each do |pod|
          pod.machines.update(tags: ["type:container", "pod:#{service_pod['metadata']['name']}", "service:#{service['metadata']['name']}"])
        end
      end
    end
  end

  def collect_machines(logger, config, pod, on_prem_machines)
    logger.info "Collecting machines for pod=#{pod['metadata']['name']}..."
    machines = []
    if pod['status']['phase'] == 'Running'
      pod['status']['containerStatuses'].each do |container|
        if container['ready']
          container_id = container['containerID'].split("//").last
          host = pod['status']['hostIP']
          # Is this a new or an existing machine?
          begin
            machine = Machine.find_by(virtual_name: container_id)
          rescue Mongoid::Errors::DocumentNotFound
            machine = Machine.new(virtual_name: container_id, name: "#{container['name']}-#{container_id[0...8]}")
          end
          machine.status = container["state"].keys.first
          machine.tags = ['type:container', "pod:#{pod['metadata']['name']}"]
          host_attributes = CAdvisorAPI::request(config, host, 'attributes')
          container_attributes = CAdvisorAPI::request(config, host, "spec/#{container_id}?type=docker")
          machine.cpu_count = host_attributes['num_cores']
          machine.cpu_speed_hz = host_attributes['cpu_frequency_khz'] * 1000
          machine.memory_bytes = host_attributes["memory_capacity"]
          machine.remote_id = get_machine_remote_id(machine, on_prem_machines)
          machine.pod = pod['db_object']

          collect_machine_disks(logger, config, machine)
          collect_machine_nics(logger, config, machine)

          machine.save!

          machines << machine
        end
      end
    end
    machines
  end

  def collect_machine_disks(logger, config, machine)
    logger.info "Collecting disks for machine=#{machine.name}..."
    # NOTE: should storage_bytes be the node disk size?
    disk_name = "disk-#{machine.virtual_name[0...8]}"
    # Is this a new or an existing disk?
    begin
      disk = machine.disks.find_by(name: disk_name)
    rescue Mongoid::Errors::DocumentNotFound
      disk = machine.disks.new(name: disk_name, storage_bytes: 0)
    end
    disk.remote_id = get_disk_remote_id(config, machine, disk_name)
    disk.machine = machine
    disk.save!
  end

  def collect_machine_nics(logger, config, machine)
    logger.info "Collecting nics for machine=#{machine.name}..."
    nic_name = "nic-#{machine.virtual_name[0...8]}"
    # Is this a new or an existing nic?
    begin
      nic = machine.nics.find_by(name: nic_name)
    rescue Mongoid::Errors::DocumentNotFound
      nic = machine.nics.new(name: nic_name, kind: 'LAN')
    end
    nic.remote_id = get_nic_remote_id(config, machine, nic_name)
    nic.machine = machine
    nic.save!
  end

  def collect_on_prem_machines(config, infrastructure)
    begin
      infrastructure.remote_id ?
        OnPremiseApi::request_api('machines', :get, config, {organization_id: config.on_premise[:organization_id],
                                                             infrastructure_id: infrastructure.remote_id})['embedded']['machines']
        :
        []
    rescue Exception => e
      raise Exception.new(e.response ? JSON.parse(e.response)['message'] : e)
    end
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

  def get_disk_remote_id(config, machine, disk_name)
    remote_id = nil
    begin
      machine_disks = machine.remote_id ?
                      OnPremiseApi::request_api('disks', :get, config)['embedded']['disks']
                      :
                      []
    rescue Exception => e
      raise Exception.new(e.response ? JSON.parse(e.response)['message'] : e)
    end
    machine_disks.each do |md|
      if disk_name.eql? md['name']
        remote_id = md['id']
        break
      end
    end
    remote_id
  end

  def get_nic_remote_id(config, machine, nic_name)
    remote_id = nil
    begin
      machine_nics = machine.remote_id ?
                     OnPremiseApi::request_api('nics', :get, config)['embedded']['nics']
                     :
                     []
    rescue Exception => e
      raise Exception.new(e.response ? JSON.parse(e.response)['message'] : e)
    end
    machine_nics.each do |mn|
      if nic_name.eql? mn['name']
        remote_id = mn['id']
        break
      end
    end
    remote_id
  end

end