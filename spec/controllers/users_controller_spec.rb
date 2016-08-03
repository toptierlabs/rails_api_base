# encoding: utf-8

require 'spec_helper'

describe Api::V1::UsersController do
  render_views

  let!(:user) { create(:user) }

  describe "PUT 'update/:id'" do
    let(:params) { { username: 'new username' } }

    context 'with the correct data' do
      it 'updates the user' do
        request.headers['X-USER-TOKEN'] = user.authentication_token
        put :update, id: user.id, user: params, format: 'json'

        expect(response.response_code).to be(200)
        expect(user.reload.username).to eq(params[:username])
      end
    end

    context 'with the incorrect auth' do
      let(:params) { { username: 'new username' } }

      it 'does not update the user' do
        request.headers['X-USER-TOKEN'] = user.authentication_token + 'wrong'
        put :update, id: user.id, user: params, format: 'json'

        expect(response.status).to eq(401)
        expect(user.reload.username).to_not eq(params[:username])
      end
    end

    context 'with incorrect data' do
      let(:params) { { email: 'notanemail' } }

      it 'does not update the user' do
        request.headers['X-USER-TOKEN'] = user.authentication_token
        put :update, id: user.id, user: params, format: 'json'

        expect(user.reload.username).to_not eq(params[:username])
        expect(response.response_code).to eq(400)
      end
    end
  end
end
