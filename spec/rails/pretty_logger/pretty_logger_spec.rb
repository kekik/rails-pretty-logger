# frozen_string_literal: true

require_relative '../../rails_helper'
require_relative '../../support/dummy_log'

describe Rails::PrettyLogger::PrettyLogger do
  describe 'check log file' do
    subject(:pretty_logger) do
      described_class.new(
        ActionController::Parameters.new(
          date_range: date_range,
          log_file: file_path,
        ),
      )
    end

    let(:file_path) { Rails.root.join('log', 'rspec_test.log').to_s }
    let(:current_day) { Date.today.to_s }

    before do
      logs = Support::DUMMY_LOG
      File.open(file_path, 'w') { |f| f.write(logs) }
    end

    after do
      File.delete(file_path)
    end

    context 'when the paramaters are valid' do
      let(:date_range) { { 'start': current_day, 'end': current_day } }

      it { expect(pretty_logger.log_data[:error]).to be_nil }
      it { expect(pretty_logger.log_data[:logs_count]).to eq(1) }

      it {
        expect(pretty_logger.log_data[:paginated_logs][0]).to include(current_day)
      }
    end

    context 'when the end date is not valid' do
      let(:date_range) { { 'start': current_day, 'end': Date.yesterday.to_s } }

      it do
        expect(pretty_logger.log_data[:error]).to eq('End Date should not be less than Start Date.')
      end
    end

    it 'gets log file list' do
      log_file_count = described_class.get_log_file_list.count
      described_class.highlight(File.exist?(file_path))
      expect(log_file_count).to be_positive
    end
  end
end
