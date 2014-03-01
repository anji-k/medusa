require 'spec_helper'

describe AccountsController do
  let(:user) { FactoryGirl.create(:user) }
  before { sign_in user }

  describe "GET show" do
    before do
      get :show
    end
    context "administrator" do
      it { expect(assigns(:user)).to eq User.current }
      it { expect(response).to render_template("show") }
    end
    context "not administrator" do
      let(:user) { FactoryGirl.create(:user,administrator: false) }
      before { sign_in user }
      it { expect(assigns(:user)).to eq User.current }
      it { expect(response).to render_template("show") }
    end
  end

  describe "GET edit" do
    before do
      get :edit
    end
    context "administrator" do
      it { expect(assigns(:user)).to eq User.current }
      it { expect(response).to render_template("edit") }
    end
    context "not administrator" do
      let(:user) { FactoryGirl.create(:user,administrator: false) }
      before { sign_in user }
      it { expect(assigns(:user)).to eq User.current }
      it { expect(response).to render_template("edit") }
    end
  end

  describe "GET quick_search" do
    let(:stone){FactoryGirl.create(:stone)}
    before do
      stone
      get :quick_search ,global_id: stone.record_property.global_id
    end
    context "administrator" do
      it { expect(response).to redirect_to(record_path(stone.record_property.global_id)) }
    end
    context "not administrator" do
      let(:user) { FactoryGirl.create(:user,administrator: false) }
      before { sign_in user }
      it { expect(response).to redirect_to(record_path(stone.record_property.global_id)) }
    end
  end

  describe "PUT update" do
    before do
      put :update, user: attributes
    end
    describe "with valid attributes password change " do
      let(:attributes) { {username: "update_name",description: "update description",password: "yyyy",password_confirmation: "yyyy"} }
      context "administrator" do
        it { expect(assigns(:user)).to eq User.current }
        it { expect(assigns(:user).username).to eq attributes[:username] }
        it { expect(assigns(:user).description).to eq attributes[:description] }
        it { expect(response).to redirect_to(account_path) }
      end
      context "not administrator" do
        let(:user) { FactoryGirl.create(:user,administrator: false) }
        before { sign_in user }
        it { expect(assigns(:user)).to eq User.current }
        it { expect(assigns(:user).username).to eq attributes[:username] }
        it { expect(assigns(:user).description).to eq attributes[:description] }
        it { expect(response).to redirect_to(account_path) }
      end
    end
    describe "with valid attributes no password change" do
      let(:attributes) { {username: "update_name",description: "update description",password: "",password_confirmation: ""} }
      context "administrator" do
        it { expect(assigns(:user)).to eq User.current }
        it { expect(assigns(:user).username).to eq attributes[:username] }
        it { expect(assigns(:user).description).to eq attributes[:description] }
        it { expect(response).to redirect_to(account_path) }
      end
      context "not administrator" do
        let(:user) { FactoryGirl.create(:user,administrator: false) }
        before { sign_in user }
        it { expect(assigns(:user)).to eq User.current }
        it { expect(assigns(:user).username).to eq attributes[:username] }
        it { expect(assigns(:user).description).to eq attributes[:description] }
        it { expect(response).to redirect_to(account_path) }
      end
    end
    describe "with invalid attributes no username " do
      let(:attributes) { {username: "",description: "update description"} }
      before { allow(user).to receive(:update_attributes).and_return(false) }
      context "administrator" do
        it { expect(assigns(:user)).to eq user }
        it { expect(assigns(:user).username).to eq attributes[:username] }
        it { expect(assigns(:user).description).to eq attributes[:description] }
        it { expect(response).to render_template("edit") }
      end
      context "not administrator" do
        let(:user) { FactoryGirl.create(:user,administrator: false) }
        before { sign_in user }
        it { expect(assigns(:user)).to eq user }
        it { expect(assigns(:user).username).to eq attributes[:username] }
        it { expect(assigns(:user).description).to eq attributes[:description] }
        it { expect(response).to render_template("edit") }
      end
    end
  end

end