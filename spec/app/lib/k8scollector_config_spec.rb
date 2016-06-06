RSpec.describe K8scollectorConfig do

  let(:secrets_dir) { "#{File.expand_path(File.dirname(__FILE__))}/../../kubernetes/secrets" }
  let(:kube) { {
    host:              '172.17.8.201',
    url:               'http://172.17.8.201:8080/api/v1',
    token:             'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiI2ZnVzaW9uLXN5c3RlbSIsImt1YmVybmV0ZXMuaW8vc2V',
    headers:           {Authorization: 'Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiI2ZnVzaW9uLXN5c3RlbSIsImt1YmVybmV0ZXMuaW8vc2V'},
    verify_ssl:        '0',
    cadvisor_port:     '4194',
    cadvisor_protocol: 'http'
  } }
  let(:on_premise) { {
    url:               'http://172.17.8.201:80',
    token:             'ydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJkZWZhdWx0LXRva2VuLXgyZnBmIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6ImRlZmF1bHQiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW5',
    verify_ssl:        '0',
    organization_id:   '776163-55844452c8424317a20a7077fda22588'
  } }

  describe 'initialize' do

    it 'verifies the kube host' do
      allow(File).to receive(:exists?) { true }
      kube_host = File.read("#{secrets_dir}/kube/kube-host").chomp.strip
      allow(File).to receive(:read) { kube_host }
      subject { K8scollectorConfig.new }
      expect(subject.kube[:host]).to eql(kube[:host])
    end

    it 'verifies the kube url' do
      allow(File).to receive(:exists?) { true }
      kube_url = File.read("#{secrets_dir}/kube/kube-url").chomp.strip
      allow(File).to receive(:read) { kube_url }
      subject.kube[:url] = kube_url
      expect(subject.kube[:url]).to eql(kube[:url])
    end

    it 'verifies the kube token' do
      allow(File).to receive(:exists?) { true }
      kube_token = File.read("#{secrets_dir}/kube/kube-token").chomp.strip
      allow(File).to receive(:read) { kube_token }
      subject.kube[:token] = kube_token
      expect(subject.kube[:token]).to eql(kube[:token])
    end

    it 'verifies the kube verify ssl option' do
      allow(File).to receive(:exists?) { true }
      kube_verify_ssl = File.read("#{secrets_dir}/kube/kube-verify-ssl").chomp.strip
      allow(File).to receive(:read) { kube_verify_ssl }
      subject.kube[:verify_ssl] = kube_verify_ssl
      expect(subject.kube[:verify_ssl]).to eql(kube[:verify_ssl])
    end

    it 'verifies the cAdvisor port' do
      allow(File).to receive(:exists?) { true }
      cadvisor_port = File.read("#{secrets_dir}/kube/cadvisor-port").chomp.strip
      allow(File).to receive(:read) { cadvisor_port }
      subject.kube[:cadvisor_port] = cadvisor_port
      expect(subject.kube[:cadvisor_port]).to eql(kube[:cadvisor_port])
    end

    it 'verifies the cAdvisor protocol' do
      expect(subject.kube[:cadvisor_protocol]).to eql(kube[:cadvisor_protocol])
    end

    it 'verifies the On Premise API url' do
      allow(File).to receive(:exists?) { true }
      on_premise_url = File.read("#{secrets_dir}/on-premise/url").chomp.strip
      allow(File).to receive(:read) { on_premise_url }
      subject.on_premise[:url] = on_premise_url
      expect(subject.on_premise[:url]).to eql(on_premise[:url])
    end

    it 'verifies the On Premise API token' do
      allow(File).to receive(:exists?) { true }
      on_premise_token = File.read("#{secrets_dir}/on-premise/token").chomp.strip
      allow(File).to receive(:read) { on_premise_token }
      subject.on_premise[:token] = on_premise_token
      expect(subject.on_premise[:token]).to eql(on_premise[:token])
    end

    it 'verifies the On Premise API verify ssl option' do
      allow(File).to receive(:exists?) { true }
      on_premise_verify_ssl = File.read("#{secrets_dir}/on-premise/verify-ssl").chomp.strip
      allow(File).to receive(:read) { on_premise_verify_ssl }
      subject.on_premise[:verify_ssl] = on_premise_verify_ssl
      expect(subject.on_premise[:verify_ssl]).to eql(on_premise[:verify_ssl])
    end

    it 'verifies the On Premise API Organization ID' do
      allow(File).to receive(:exists?) { true }
      on_premise_orgid = File.read("#{secrets_dir}/on-premise/organization-id").chomp.strip
      allow(File).to receive(:read) { on_premise_orgid }
      subject.on_premise[:organization_id] = on_premise_orgid
      expect(subject.on_premise[:organization_id]).to eql(on_premise[:organization_id])
    end

  end

end