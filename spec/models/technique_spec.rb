require 'spec_helper'

describe Technique do

  describe "validates" do
    describe "name" do
      let(:obj) { FactoryGirl.build(:technique, name: name) }
      context "is presence" do
        let(:name) { "technique" }
        it { expect(obj).to be_valid }
      end
      context "is blank" do
        let(:name) { "" }
        it { expect(obj).not_to be_valid }
      end
      context "is 255 characters" do
        let(:name) { "a" * 255 }
        it { expect(obj).to be_valid }
      end
      context "is 256 characters" do
        let(:name) { "a" * 256 }
        it { expect(obj).not_to be_valid }
      end
    end
  end

end
