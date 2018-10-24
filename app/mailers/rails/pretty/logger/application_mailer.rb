module Rails
  module Pretty
    module Logger
      class ApplicationMailer < ActionMailer::Base
        default from: 'from@example.com'
        layout 'mailer'
      end
    end
  end
end
