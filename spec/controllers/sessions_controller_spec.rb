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

    let(:fb_access_token )  { '1234567890_VALID'}
    let(:first_name)        { 'Test' }
    let(:last_name)         { 'test' }
    let(:email)             { 'test2@api_base.com' }
    let!(:user)    { create(:user, facebook_id: '1234567890',first_name: first_name, last_name:last_name, email: email) }
    let!(:user_2)    { create(:user, facebook_id: '2222222222',first_name: first_name, last_name:last_name) }

    context 'with valid params' do
      context 'when the user does not exist' do
        it 'creates a new facebook user' do
          expect { post :create, { type: 'facebook', fb_access_token:  '1111111111_VALID' }, format: 'json' }.to change { User.count }.by(1)
        end

        it 'creates two new facebook user without mail' do 
          post :create, { type: 'facebook', fb_access_token:  '1111111111_VALID' }, format: 'json'
          fb_user1 = User.find_by(facebook_id: 1111111111)
          expect(fb_user1).to_not be_nil
        end

        it 'creates a user with the correct information' do
          post :create, { type: 'facebook', fb_access_token:  fb_access_token}, format: 'json'

          fb_user = User.find_by(facebook_id: 1234567890 , first_name: first_name, last_name: last_name, email: email)
          expect(fb_user).to_not be_nil
          expect(fb_user.first_name).to eq(first_name)
          expect(fb_user.last_name).to eq(last_name)
          expect(fb_user.email).to eq(email)
          expect(parse_response(response)['token']).to eq(fb_user.authentication_token)
        end

        it 'returns a successful response' do
          post :create, { type: 'facebook', fb_access_token:  fb_access_token }, format: 'json'
          expect(response.response_code).to eq(200)
        end
      end

      context 'when the user exists' do
        let!(:user)       { create(:user_with_fb, facebook_id: 1234567890) }

        it 'does not create a new user record' do
          expect { post :create, {type: 'facebook', fb_access_token:  fb_access_token }, format: :json }.not_to change { User.count }
        end
      end
    end

    context 'with invalid params' do
      context 'without fb_access_token' do
        it 'does not create a user' do
           post :create, {  type: 'facebook'}, format: 'json' 
           expect(response.status).to eq(403)
        end
      end

      context 'when the data is incorrect' do
        it 'does not create a user' do 
          post :create, {  type: 'facebook', invalid_param:  fb_access_token  }, format: 'json' 
          expect(response.status).to eq(403)
        end
      end

      context 'when the authentication is invalid'  do
        context 'the authentication token is invalid' do
          let(:fb_access_token )  { '1234567890_INVALID'}
          
          it 'rais 403 error' do
            post :create, {type: 'facebook', fb_access_token:  fb_access_token  }, format: 'json'
            expect(response.status).to eq(403)
          end
        end
      end
    end
  end
end
