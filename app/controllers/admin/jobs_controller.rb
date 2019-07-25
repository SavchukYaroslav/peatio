# encoding: UTF-8
# frozen_string_literal: true

module Admin
  class JobsController < BaseController
    skip_load_and_authorize_resource

    def index
      @jobs = Job.page(params[:page]).per(30)
    end

    def show
      @job = Job.find(params[:id])
    end

    def create
      begin
        @job = Job.trigger_compactor
        redirect_to admin_jobs_path
      rescue StandartError => e
        flash[:alert] = 'Cannot create trigger. Try again later'
        render :show
      end
  end
end
