# frozen_string_literal: true

require_relative '../../../rails_helper'
require_relative '../../../support/dummy_log'

describe Rails::PrettyLogger::DashboardsController, type: :controller do
  let(:file_path) { Rails.root.join('log', 'rspec_test.log').to_s }
  let(:current_day) { Date.today.to_s }

  routes { Rails::PrettyLogger::Engine.routes }

  before do
    logs = Support::DUMMY_LOG
    File.open(file_path, 'w') { |f| f.write(logs) }
  end

  after do
    File.delete(file_path)
  end

  describe 'GET #index' do
    it 'returns http success' do
      get :index
      expect(response).to be_successful
    end
  end

  describe 'GET #log_file' do
    it 'returns http success' do
      get :logs, params: {
        log_file: file_path,
        date_range: { start: current_day, end: current_day },
      }
      expect(response).to be_successful
    end
  end
end
