# encoding: UTF-8
# frozen_string_literal: true

module Admin
  class BaseController < ::ApplicationController
    layout 'admin'

    skip_before_action :verify_authenticity_token

    before_action :auth_admin!
    before_action :auth_member!

    def current_ability
      @current_ability ||= Admin::Ability.new(current_user)
    end

  end
end

