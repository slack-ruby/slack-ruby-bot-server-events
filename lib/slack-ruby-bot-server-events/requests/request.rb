# frozen_string_literal: true

module SlackRubyBotServer
  module Events
    module Requests
      class Request < ActiveSupport::HashWithIndifferentAccess
        attr_reader :request

        def initialize(params, request)
          @request = request
          super params
        end

        def logger
          SlackRubyBotServer::Api::Middleware.logger
        end
      end
    end
  end
end
