module SpreeChimpy
  module Workers
    class DelayedJob
      delegate :log, to: SpreeChimpy

      def initialize(payload)
        @payload = payload
      end

      def perform
        SpreeChimpy.perform(@payload)
      rescue Excon::Errors::Timeout, Excon::Errors::SocketError
        log "Mailchimp connection timeout reached, closing"
      end

      def max_attempts
        return 3
      end
    end
  end
end
