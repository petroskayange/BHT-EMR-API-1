# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/auth', type: :request do
  describe '/login' do
    it 'creates auth token on login' do
      post api_route('auth/login'), params: { username: 'admin', password: 'test' }

      expect(response).to have_http_status(:ok)

      parse_response(response) do |json|
        expect(json).to have_key('authorization')
        expect(json['authorization']).to have_key('token')
        expect(json['authorization']['token']).not_to be_blank
      end
    end

    it 'does not allow logins with wrong passwords' do
      post api_route('auth/login'), params: { username: 'admin', password: 'password' }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'does not allow logins for non-existent users' do
      post api_route('auth/login'), params: { username: 'banner', password: 'strongest-avenger' }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'requires username', exceptions: :catch do
      post api_route('auth/login'), params: { password: 'test' }

      expect(response).to have_http_status(:bad_request)
    end

    it 'requires password', exceptions: :catch do
      post api_route('auth/login'), params: { username: 'admin' }

      expect(response).to have_http_status(:bad_request)
    end
  end
end
