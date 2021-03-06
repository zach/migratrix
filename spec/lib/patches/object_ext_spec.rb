require 'spec_helper'

describe Object do
  describe "#deep_copy" do
    let(:ray) { [1,2,3]}
    let(:hash) { {a: 42, b: 69, c: 13, d: 64} }
    let(:struct) { Struct.new(:array, :hash).new(ray, hash)}
    let(:big_hash) { {:struct1 => struct, :struct2 => struct, :hash => hash, :array => ray }}

    describe "sanity check" do
      it "should have objects correctly aliased" do
        big_hash[:struct1].object_id.should == big_hash[:struct2].object_id
      end
    end
  end
end
