require 'spec_helper'

describe NestedResources::SpotsController do
  let(:parent_name){:attachment_file}
  let(:child_name){:spot}
  let(:parent) { FactoryGirl.create(parent_name) }
  let(:child) { FactoryGirl.create(child_name) }
  let(:user) { FactoryGirl.create(:user) }
  let(:url){"where_i_came_from"}
  let(:spot_x){1}
  let(:attributes) { {spot_x: spot_x,spot_y: 0} }
  before { request.env["HTTP_REFERER"]  = url }
  before { sign_in user }
  before { parent }
  before { child }

  describe "POST create" do
    let(:method){post :create, parent_resource: parent_name, attachment_file_id: parent, spot: attributes, association_name: :spots}
    before{child}
    it { expect{method}.to change(Spot, :count).by(1) }
    context "validate" do
      before { method }
      it { expect(parent.spots.exists?(spot_x: spot_x)).to eq true}
      it { expect(response).to redirect_to request.env["HTTP_REFERER"]}
    end
    context "invalidate" do
      let(:spot_x){""}
      before { method }
      it { expect {method}.to change(Spot, :count).by(0) }
      it { expect(parent.spots.exists?(spot_x: spot_x)).to eq false}
      it { expect(response).to render_template("error")}
    end
  end
  describe "PUT update" do
    let(:method){put :update, parent_resource: parent_name, attachment_file_id: parent, id: child_id, association_name: :spots}
    let(:child_id){child.id}
    it { expect {method}.to change(Spot, :count).by(0) }
    context "present child" do
      before { method }
      it { expect(assigns(child_name)).to eq child }
      it { expect(parent.spots.exists?(id: child.id)).to eq true}
    end
    context "none child" do
      let(:child_id){0}
      it { expect{method}.to raise_error(ActiveRecord::RecordNotFound)}
    end
  end

  describe "DELETE destory" do
    let(:method){delete :destroy, parent_resource: parent_name, attachment_file_id: parent, id: child_id, association_name: :spots}
    before { parent.spots << child}
    let(:child_id){child.id}
    it { expect {method}.to change(Spot, :count).by(-1) }
    context "present child" do
      before { method }
      it { expect(parent.spots.exists?(id: child.id)).to eq false}
      it { expect(response).to redirect_to request.env["HTTP_REFERER"] }
    end
    context "none child" do
      let(:child_id){0}
      it {expect{method}.to raise_error(ActiveRecord::RecordNotFound)}
    end
  end

end
