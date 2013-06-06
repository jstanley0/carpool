ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...
end

def compute_digest(user, pw, realm = Carpool::REALM)
  Digest::MD5.hexdigest([user, realm, pw].join(':'))
end

# the below was stolen from https://gist.github.com/denisahearn/1282275
# ---
# Adds support for http digest authentication in Rails 3
# Inspired by: http://lightyearsoftware.com/2009/04/testing-http-digest-authentication-in-rails/
# Place this code in test/test_helper.rb
# In your test, call authenticate_with_http_digest prior to calling get, post, put or delete
# Tested with Rails 3.0.7

class ActionController::TestCase
  require 'digest/md5'

  def authenticate_with_http_digest(user, password, realm = Carpool::REALM)
    ActionController::Base.class_eval { include ActionController::Testing }

    @controller.instance_eval %Q(
      alias real_process_with_new_base_test process_with_new_base_test

      def process_with_new_base_test(request, response)
        credentials = {
	  :uri => request.url,
	  :realm => "#{realm}",
	  :username => "#{user}",
	  :nonce => ActionController::HttpAuthentication::Digest.nonce(request.env['action_dispatch.secret_token']),
	  :opaque => ActionController::HttpAuthentication::Digest.opaque(request.env['action_dispatch.secret_token'])
        }
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Digest.encode_credentials(request.request_method, credentials, "#{password}", false)

        real_process_with_new_base_test(request, response)
      end
    )
  end
end