# encoding: utf-8


module Api
  module V1
    class SessionsController < Devise::SessionsController
      skip_before_filter :verify_authenticity_token, if: :json_request?

      # POST /resource/sign_in
      def create
        if params[:type] == 'facebook'
          user = obtain_facebook_user(params[:fb_access_token])
          render json: { error: 'Not Authorized' }, status: :forbidden and return if user.nil?
          user_params = {
           facebook_id: user['id'],
           first_name:  user['first_name'],
           last_name:   user['last_name'],
           email:       user['email']
          }
          resource = User.find_or_create_by_fb user_params
        else
          resource = warden.authenticate! scope: resource_name, recall: "#{controller_path}#failure"
        end
        sign_in_and_redirect(resource_name, resource)
      end

      def sign_in_and_redirect(resource_or_scope, resource = nil)
        scope = Devise::Mapping.find_scope! resource_or_scope
        resource ||= resource_or_scope
        sign_in(scope, resource) unless warden.user(scope) == resource
        render json: { token: resource.authentication_token, email: resource.email }
      end

      # DELETE /resource/sign_out
      def destroy
        # expire auth token
        current_user.invalidate_token
        head :no_content
      end

      def failure
        render json: { errors: ['Login failed.'] }, status: :bad_request
      end

      protected

      def json_request?
        request.format.json?
      end

      def obtain_facebook_user(fb_access_token)
        begin
          graph = Koala::Facebook::API.new(fb_access_token)
          graph.get_object('me?fields=first_name,last_name,email')
        rescue Koala::Facebook::AuthenticationError => ex
          return nil
        end
      end
    end
  end
end
