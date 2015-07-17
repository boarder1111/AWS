require 'rubygems'
require 'bundler/setup'
require 'optparse'
require 'aws-sdk'
require 'json'

# Create classes and methods
class Ec2_instance
  attr_accessor :instance_type, :ec2_hash
  def initialize (instance_type)
    @instance_type = instance_type
    @ec2_hash = {
        'Properties' => {
            'ImageId' => 'ami-b97a12ce',
            'InstanceType' => @instance_type,
            'SecurityGroups'=> [{
                                    'Ref' => 'InstanceSecurityGroup'
                                }]
        },
        'Type' => 'AWS::EC2::Instance'
    }
  end
end

class Instance_sec_group
  attr_accessor :cidr_ip, :sec_group_hash
  def initialize (cidr_ip)
    @cidr_ip = cidr_ip
    @sec_group_hash = {
        'Properties' => {
            'GroupDescription' => 'Enable SSH access via port 22',
            'SecurityGroupIngress' => [{
                                           'CidrIp' => @cidr_ip,
                                           'FromPort' => '22',
                                           'IpProtocol' => 'tcp',
                                           'ToPort' => '22'
                                       }]
        },
        'Type' => 'AWS::EC2::SecurityGroup'
    }
  end
end

class Outputs
  attr_accessor :outputs_hash
  def initialize
    @outputs_hash = {
        'PublicIP' => {
            'Description' => 'Public IP address of the newly created EC2 instance',
            'Value' => {
                'Fn::GetAtt' => ['EC2Instance', 'PublicIp']
            }
        }
    }
  end
end

class Json_file
  def initialize(outputs_hash, ec2_hash, nr_instances, security_group_hash)
    @outputs_hash = outputs_hash
    @ec2_hash = ec2_hash
    @nr_instances = nr_instances
    @security_group_hash = security_group_hash
    json_file = File.open("stack.json", "w")
    json_file.puts '{'
    json_file.puts '"AWSTemplateFormatVersion": "2010-09-09",'
    json_file.puts '"Outputs": ' + JSON.pretty_generate(@outputs_hash) + ','
    json_file.puts '"Resources": {'
    json_file.puts '"' + 'EC2Instance' + '": ' + JSON.pretty_generate(@ec2_hash) + ','

    if @nr_instances > 1
      2.upto(@nr_instances) {
          |number| json_file.puts '"' + 'EC2Instance' + number.to_s + '": ' + JSON.pretty_generate(@ec2_hash) + ','
      }
    end
    json_file.puts '"' + 'InstanceSecurityGroup' + '": ' + JSON.pretty_generate(@security_group_hash)
    json_file.puts '}'
    json_file.puts '}'
    json_file.close
  end
end

# Create options hash with default values
options_hash = {
    'nr_instances' => 1,
    'instance_type' => 't2.micro',
    'allow_ssh_from' => '0.0.0.0/0'
}
# Parse the options and change the default values of the options_hash
OptionParser.new do|opts|
  opts.on('--instances instances') do |nr_instances|
    options_hash['nr_instances'] = nr_instances.to_i
  end
  opts.on('--instance-type instance-type') do |instance_type|
    options_hash['instance_type'] = instance_type
  end
  opts.on('--allow-ssh-from allow-ssh-from') do |allow_ssh_from|
    options_hash['allow_ssh_from'] = (allow_ssh_from + '/32')
  end
end.parse!

# Execution
sec_group = Instance_sec_group.new (options_hash['allow_ssh_from'])
ec2 = Ec2_instance.new(options_hash['instance_type'])
outputs = Outputs.new
Json_file.new(outputs.outputs_hash, ec2.ec2_hash, options_hash['nr_instances'], sec_group.sec_group_hash)

# Create AWS stack
creds = JSON.load(File.read('../key.json'))
Aws.config[:credentials] = Aws::Credentials.new(creds['AccessKeyId'], creds['SecretKey'])
Aws.config.update({
                      region: 'eu-west-1'
                  })

cloudformation = Aws::CloudFormation::Client.new

cloudformation.create_stack({
                                stack_name: "TestStack",
                                template_body: File.open("stack.json", "r").read
                            })









