require 'spec_helper.rb'

describe Ec2_instance do
 it "returns a hash" do
   ec2 = Ec2_instance.new('instance_type')
   expect(ec2.ec2_hash).to be_a(Hash)
  end
 end

 describe Instance_sec_group do
   it "returns a hash" do
     sec_group = Instance_sec_group.new('allow_ssh_from')
     expect(sec_group.sec_group_hash).to be_a(Hash)
   end
 end

describe Outputs do
  it "returns a hash" do
    outputs = Outputs.new
    expect(outputs.outputs_hash).to be_a(Hash)
  end
end

describe Json_file do
  it "is created" do
    json_file = File.open('stack.json')
    if File.exists?(json_file) == true
      puts "stack.json file exists"
    else
      puts "stack.json file is not created"
    end
  end
end

