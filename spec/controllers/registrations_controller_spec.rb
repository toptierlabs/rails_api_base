# encoding: utf-8

require 'spec_helper'

describe Api::V1::RegistrationsController do
  render_views

  let!(:user) { create(:user) }

  before(:each) do
    @request.env['devise.mapping'] = Devise.mappings[:user]
  end

  describe "POST 'users/'" do
    let(:username)              { 'test' }
    let(:email)                 { 'test@test.com' }
    let(:password)              { '12345678' }
    let(:password_confirmation) { '12345678' }

    let(:attrs) do
      {
        username: username,
        email: email,
        password: password,
        password_confirmation: password_confirmation
      }
    end

    it 'returns a successful response' do
      post :create, user: attrs, format: 'json'

      expect(response.status).to eq(200)
    end

    it 'creates the user' do
      post :create, user: attrs, format: 'json'

      new_user = User.find_by_email('test@test.com')
      expect(new_user).to_not be_nil
    end

    context 'when the email is not correct' do
      let(:email) { 'invalid_email' }

      it 'does not create a user' do
        expect { post :create, user: attrs, format: 'json' }.not_to change { User.count }
      end

      it 'does not return a successful response' do
        post :create, user: attrs, format: 'json'

        expect(response.response_code).to eq(400)
      end
    end

    context 'when the password is incorrect' do
      let(:password)              { 'short' }
      let(:password_confirmation) { 'short' }

      let(:new_user)              { User.find_by_email('test@test.com') }

      it 'does not create a user' do
        post :create, user: attrs, format: 'json'

        expect(new_user).to be_nil
      end

      it 'does not return a successful response' do
        post :create, user: attrs, format: 'json'

        expect(response.response_code).to eq(400)
      end
    end

    context 'when passwords don\'t match' do
      let(:password)              { 'shouldmatch' }
      let(:password_confirmation) { 'dontmatch' }

      let(:new_user)              { User.find_by_email('test@test.com') }

      it 'does not create a user' do
        post :create, user: attrs, format: 'json'

        expect(new_user).to be_nil
      end

      it 'does not return a successful response' do
        post :create, user: attrs, format: 'json'

        expect(response.response_code).to eq(400)
      end
    end
  end
end
