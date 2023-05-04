module SpreeChimpy
  module Workers
    class Resque
      delegate :log, to: SpreeChimpy

      QUEUE = :default
      @queue = QUEUE

      def self.perform(payload)
        SpreeChimpy.perform(payload.with_indifferent_access)
      rescue Excon::Errors::Timeout, Excon::Errors::SocketError
        log "Mailchimp connection timeout reached, closing"
      end
    end
  end
end
