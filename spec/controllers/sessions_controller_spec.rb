# encoding: utf-8

require 'spec_helper'

describe Api::V1::SessionsController do
  before :each do
    @request.env['devise.mapping'] = Devise.mappings[:user]
  end

  describe 'create' do
    let(:password) { 'mypass123' }
    let!(:user)    { create(:user, password: password) }
    let(:email)    { user.email }
    let(:params)   { { email: email, password: password } }

    context 'with valid login' do
      it 'returns the user json' do
        post :create, user: params, format: 'json'

        expect(parse_response(response)['token']).to_not be_nil
      end
    end

    context 'with invalid login' do
      context 'when the password is incorrect' do
        let!(:user)    { create(:user, password: 'another_password') }
        let(:password) { 'badPassword' }

        it 'returns an error' do
          post :create, user: params, format: 'json'

          expect(parse_response(response)['error']).to eq('authentication error')
        end
      end

      context 'when the email is not correct' do
        let(:email) { 'bademail@eaea.com' }

        it 'returns an error' do
          post :create, user: params, format: 'json'

          expect(parse_response(response)['error']).to eq('authentication error')
        end
      end
    end
  end

  describe "POST 'facebook_login'" do
    let(:facebook_id) { '1234567890' }
    let(:first_name)  { 'test' }
    let(:last_name)   { 'dude' }
    let(:params)      { { facebook_id: facebook_id, first_name: first_name, last_name: last_name } }

    context 'with valid params' do
      context 'when the user does not exist' do
        it 'creates a new facebook user' do
          expect { post :create, { type: 'facebook', user:  params }, format: 'json' }.to change { User.count }.by(1)
        end

        it 'creates a user with the correct information' do
          post :create, { type: 'facebook', user:  params }, format: 'json'

          fb_user = User.find_by(facebook_id: params[:facebook_id], first_name: params[:first_name], last_name: params[:last_name])

          expect(fb_user).to_not be_nil
          expect(parse_response(response)['token']).to eq(fb_user.authentication_token)
        end

        it 'returns a successful response' do
          post :create, { type: 'facebook', user:  params }, format: 'json'

          expect(response.response_code).to eq(200)
        end
      end

      context 'when the user exists' do
        let!(:user)       { create(:user_with_fb) }
        let(:facebook_id) { user.facebook_id }
        let(:first_name)  { user.first_name }
        let(:last_name)   { user.last_name }

        it 'does not create a new user record' do
          expect { post :create, user: params, format: :json }.not_to change { User.count }
        end
      end
    end

    context 'with invalid params' do
      context 'when the data is empty' do
        it 'does not create a user' do
          expect { post :create, user: { type: 'facebook' }, format: 'json' }.not_to change { User.count }
        end
      end

      context 'when the data is incorrect' do
        let(:facebook_id) { '' }
        let(:first_name)  { 'some' }
        let(:last_name)   { 'last_name' }

        it 'does not create a user' do
          expect { post :create, user: params, format: 'json' }.not_to change { User.count }
        end
      end
    end
  end
end
