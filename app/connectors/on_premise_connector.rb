class OnPremiseConnector

  def initialize(logger, config)
    @logger       = logger
    @config       = config
    @method       = { post: :post,
                      put:  :put }
  end

  def sync
    return if Infrastructure.count == 0

    reset_statistics
    obtain_last_samples
    obtain_records

    @logger.info "Syncing Infrastructure..."
    sync_infrastructures

    @logger.info 'Syncing machines...'
    sync_machines

    @logger.info 'Submitting samples...'
    submit_samples

    statistics_report
  end

  def reset_statistics
    #created
    @created_machines = 0
    @created_nics = 0
    @created_disks = 0

    #Updated
    @updated_machines = 0
    @updated_nics = 0
    @updated_disks = 0

    #submitted
    @samples_submitted = 0
  end

  def statistics_report
    @logger.info "Created #{@created_machines} machines."
    @logger.info "Created #{@created_disks} disks."
    @logger.info "Created #{@created_nics} nics."
    @logger.info "Updated #{@updated_machines} machines."
    @logger.info "Updated #{@updated_disks} disks."
    @logger.info "Updated #{@updated_nics} nics."
    @logger.info "Submitted #{@samples_submitted} samples."
  end

  def obtain_last_samples
    current_time = Time.now.utc
    seconds = current_time.sec
    @end_time = current_time - seconds
    @start_time = @end_time - 5.minutes

    @machine_samples = MachineSample.where(reading_at: (@start_time..@end_time))
  end

  def obtain_records
    @machines = @machine_samples.map{|sample| sample.machine}.uniq
  end


  # Creates/Updates infrastructure and synchronize it with the on-premise api
  def sync_infrastructures
    begin
      @infrastructure = Infrastructure.find_by(organization_id: @config.on_premise[:organization_id])
      @infrastructure.remote_id ? update_infrastructure(@infrastructure) : create_infrastructure(@infrastructure)
    rescue Mongoid::Errors::DocumentNotFound => e
      raise Exception.new("Infrastructure not found")
    end
  end

  # Creates/Updates machines and synchronizes with the on-premise api
  def sync_machines
    @machines.each do |machine|
      begin
        machine.remote_id ? update_machine(machine) : create_machine(machine)
        sync_disks(machine)
        sync_nics(machine)
      rescue StandardError => e
        raise Exception.new(e.response ? JSON.parse(e.response)['message'] : e)
      end
    end
  end

  # Creates/Updates disks and synchronizes with the on-premise api
  def sync_disks(machine)
    @logger.info "Syncing disks for #{machine.name}..."
    machine.disks.each do |disk|
      begin
        disk.remote_id ? update_disk(disk) : create_disk(disk)
      rescue StandardError => e
        raise Exception.new(e.response ? JSON.parse(e.response)['message'] : e)
      end
    end
  end

  # Creates/Updates nics and synchronizes with the on-premise api
  def sync_nics(machine)
    @logger.info "Syncing nics for #{machine.name}..."
    machine.nics.each do |nic|
      begin
        nic.remote_id ? update_nic(nic) : create_nic(nic)
      rescue StandardError => e
        raise Exception.new(e.response ? JSON.parse(e.response)['message'] : e)
      end
    end
  end

  # Creates samples and synchronizes with the on-premise api
  def submit_samples
    @machines.each do |machine|
      begin
        create_samples(machine)
      rescue StandardError => e
        raise Exception.new(e.response ? JSON.parse(e.response)['message'] : e)
      end
    end
  end

  def create_infrastructure(infrastructure)
    endpoint = "organizations/#{@config.on_premise[:organization_id]}/infrastructures"
    payload = infrastructure.to_payload
    response = OnPremiseApi::request_api(endpoint, @method[:post], @config, payload)
    update_remote_id(infrastructure, response)
    @logger.info "Creating infrastructure #{infrastructure.name} completed successfully."
  end

  def update_infrastructure(infrastructure)
    endpoint = "infrastructures/#{infrastructure.remote_id}"
    payload = infrastructure.to_payload
    OnPremiseApi::request_api(endpoint, @method[:put], @config, payload)
    @logger.info "Updating infrastructure #{infrastructure.name} completed successfully."
  end

  def create_machine(machine)
    endpoint = "infrastructures/#{@infrastructure.remote_id}/machines"
    payload = machine.to_payload
    response = OnPremiseApi::request_api(endpoint, @method[:post], @config, payload)
    update_remote_id(machine, response)
    @logger.info "Creating machine #{machine.name} completed successfully."
    @created_machines += 1
  end

  def update_machine(machine)
    endpoint = "machines/#{machine.remote_id}"
    payload = machine.to_payload
    OnPremiseApi::request_api(endpoint, @method[:put], @config, payload)
    @logger.info "Updating machine #{machine.name} completed successfully."
    @updated_machines += 1
  end

  def create_disk(disk)
    endpoint = "machines/#{disk.machine.remote_id}/disks"
    payload = disk.to_payload
    response = OnPremiseApi::request_api(endpoint, @method[:post], @config, payload)
    update_remote_id(disk, response)
    @logger.info "Creating disk #{disk.name} completed successfully."
    @created_disks += 1
  end

  def update_disk(disk)
    endpoint = "disks/#{disk.remote_id}"
    payload = disk.to_payload
    OnPremiseApi::request_api(endpoint, @method[:put], @config, payload)
    @logger.info "Updating disk #{disk.name} completed successfully."
    @updated_disks += 1
  end

  def create_nic(nic)
    endpoint = "machines/#{nic.machine.remote_id}/nics"
    payload = nic.to_payload
    response = OnPremiseApi::request_api(endpoint, @method[:post], @config, payload)
    update_remote_id(nic, response)
    @logger.info "Creating nic #{nic.name} completed successfully."
    @created_nics += 1
  end

  def update_nic(nic)
    endpoint = "nics/#{nic.remote_id}"
    payload = nic.to_payload
    OnPremiseApi::request_api(endpoint, @method[:put], @config, payload)
    @logger.info "Updating nic #{nic.name} completed successfully."
    @updated_nics += 1
  end

  def create_samples(machine)
    endpoint = "machines/#{machine.remote_id}/samples"
    payload = machine.to_samples_payload(@start_time, @end_time)
    OnPremiseApi::request_api(endpoint, @method[:post], @config, payload)
    @logger.info "Submitting samples for machine #{machine.name} completed successfully."
    @samples_submitted += 1
  end

  def update_remote_id(structure, response)
    parameters = { remote_id: response["id"] }
    structure.update(parameters)
  end
end