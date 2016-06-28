# This class is responsible for synchronizing the cluster infrastructure items
# with the 6fusion meter On Premise API and for submitting their samples
# collected during the process
class OnPremiseConnector
  def initialize(logger, config)
    @logger       = logger
    @config       = config
    @method       = { post: :post,
                      put:  :put }
    @stats        = { start_time:        nil,
                      end_time:          nil,
                      created_machines:  0,
                      created_nics:      0,
                      created_disks:     0,
                      updated_machines:  0,
                      updated_nics:      0,
                      updated_disks:     0,
                      samples_submitted: 0,
                      infrastructure:    nil,
                      machines:          [],
                      machine_samples:   [],
                      powered_off_machines: [] }
  end

  def sync
    return if Infrastructure.count == 0

    reset_statistics
    obtain_data
    sync_structures
    statistics_report
  end

  def obtain_data
    obtain_powered_off_machines
    obtain_last_samples
    obtain_records
  end

  def sync_structures
    @logger.info 'Syncing Infrastructure...'
    sync_infrastructures

    @logger.info 'Syncing machines...'
    sync_powered_off_machines
    sync_machines

    @logger.info 'Submitting samples...'
    submit_samples
  end

  def reset_statistics
    # Created
    @stats[:created_machines] = 0
    @stats[:created_nics] = 0
    @stats[:created_disks] = 0

    # Updated
    @stats[:updated_machines] = 0
    @stats[:updated_nics] = 0
    @stats[:updated_disks] = 0

    # Submitted
    @stats[:samples_submitted] = 0
  end

  def statistics_report
    @logger.info "Created #{@stats[:created_machines]} machines."
    @logger.info "Created #{@stats[:created_disks]} disks."
    @logger.info "Created #{@stats[:created_nics]} nics."
    @logger.info "Updated #{@stats[:updated_machines]} machines."
    @logger.info "Updated #{@stats[:updated_disks]} disks."
    @logger.info "Updated #{@stats[:updated_nics]} nics."
    @logger.info "Submitted #{@stats[:samples_submitted]} samples."
  end

  def obtain_powered_off_machines
    @stats[:powered_off_machines] = Machine.all.select{|x| powered_off_machine?(x)}
  end

  def powered_off_machine?(machine)
    machine.machine_samples.exists? == false && machine.status == Machine::STATUS_POWERED_OFF
  end

  def obtain_last_samples
    current_time = Time.now.utc
    seconds = current_time.sec
    @stats[:end_time] = current_time - seconds
    @stats[:start_time] = @stats[:end_time] - 5.minutes

    @stats[:machine_samples] = MachineSample.where(reading_at: (@stats[:start_time]..@stats[:end_time]))
  end

  def obtain_records
    @stats[:machines] = @stats[:machine_samples].map(&:machine).uniq
  end

  # Creates/Updates infrastructure and synchronize it with the on-premise api
  def sync_infrastructures
    begin
      @stats[:infrastructure] = Infrastructure.find_by(organization_id: @config.on_premise[:organization_id])
      @stats[:infrastructure].remote_id ? update_infrastructure(@stats[:infrastructure]) : create_infrastructure(@stats[:infrastructure])
    rescue Mongoid::Errors::DocumentNotFound
      message = 'Infrastructure not found'
      raise Exceptions::OnPremiseException, message
    end
  end

  # Creates/Updates machines and synchronizes with the on-premise api
  def sync_machines
    @stats[:machines].each do |machine|
      begin
        machine.remote_id ? update_machine(machine) : create_machine(machine)
        sync_disks(machine)
        sync_nics(machine)
      rescue StandardError => e
        message = e.response ? JSON.parse(e.response)['message'] : e
        raise Exceptions::OnPremiseException, message
      end
    end
  end

  # Updates machines with status = 'powerOff'
  def sync_powered_off_machines
    @stats[:powered_off_machines].each do |machine|
      begin
        machine.remote_id ? update_machine(machine) : create_machine(machine)
      rescue StandardError => e
        message = e.response ? JSON.parse(e.response)['message'] : e
        raise Exceptions::OnPremiseException, message
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
        message = e.response ? JSON.parse(e.response)['message'] : e
        raise Exceptions::OnPremiseException, message
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
        message = e.response ? JSON.parse(e.response)['message'] : e
        raise Exceptions::OnPremiseException, message
      end
    end
  end

  # Creates samples and synchronizes with the on-premise api
  def submit_samples
    @stats[:machines].each do |machine|
      begin
        create_samples(machine)
      rescue StandardError => e
        message = e.response ? JSON.parse(e.response)['message'] : e
        raise Exceptions::OnPremiseException, message
      end
    end
  end

  def create_infrastructure(infrastructure)
    endpoint = "organizations/#{@config.on_premise[:organization_id]}/infrastructures"
    payload = infrastructure.to_payload
    response = request_api(endpoint, @method[:post], @config, payload)
    update_remote_id(infrastructure, response)
    @logger.info "Creating infrastructure #{infrastructure.name} completed successfully."
  end

  def update_infrastructure(infrastructure)
    endpoint = "infrastructures/#{infrastructure.remote_id}"
    payload = infrastructure.to_payload
    request_api(endpoint, @method[:put], @config, payload)
    @logger.info "Updating infrastructure #{infrastructure.name} completed successfully."
  end

  def create_machine(machine)
    endpoint = "infrastructures/#{@stats[:infrastructure].remote_id}/machines"
    payload = machine.to_payload
    response = request_api(endpoint, @method[:post], @config, payload)
    update_remote_id(machine, response)
    @logger.info "Creating machine #{machine.name} completed successfully."
    @stats[:created_machines] += 1
  end

  def update_machine(machine)
    endpoint = "machines/#{machine.remote_id}"
    payload = machine.to_payload
    request_api(endpoint, @method[:put], @config, payload)
    @logger.info "Updating machine #{machine.name} completed successfully."
    @stats[:updated_machines] += 1
  end

  def create_disk(disk)
    endpoint = "machines/#{disk.machine.remote_id}/disks"
    payload = disk.to_payload
    response = request_api(endpoint, @method[:post], @config, payload)
    update_remote_id(disk, response)
    @logger.info "Creating disk #{disk.name} completed successfully."
    @stats[:created_disks] += 1
  end

  def update_disk(disk)
    endpoint = "disks/#{disk.remote_id}"
    payload = disk.to_payload
    request_api(endpoint, @method[:put], @config, payload)
    @logger.info "Updating disk #{disk.name} completed successfully."
    @stats[:updated_disks] += 1
  end

  def create_nic(nic)
    endpoint = "machines/#{nic.machine.remote_id}/nics"
    payload = nic.to_payload
    response = request_api(endpoint, @method[:post], @config, payload)
    update_remote_id(nic, response)
    @logger.info "Creating nic #{nic.name} completed successfully."
    @stats[:created_nics] += 1
  end

  def update_nic(nic)
    endpoint = "nics/#{nic.remote_id}"
    payload = nic.to_payload
    request_api(endpoint, @method[:put], @config, payload)
    @logger.info "Updating nic #{nic.name} completed successfully."
    @stats[:updated_nics] += 1
  end

  def create_samples(machine)
    endpoint = "machines/#{machine.remote_id}/samples"
    payload = machine.to_samples_payload(@stats[:start_time], @stats[:end_time])
    request_api(endpoint, @method[:post], @config, payload)
    @logger.info "Submitting samples for machine #{machine.name} completed successfully."
    @stats[:samples_submitted] += 1
  end

  def update_remote_id(structure, response)
    parameters = { remote_id: response['id'] }
    structure.update(parameters)
  end
end
