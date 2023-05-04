module SpreeChimpy
  module Workers
    class Sidekiq
      delegate :log, to: SpreeChimpy
      if defined?(::Sidekiq)
        include ::Sidekiq::Worker
        sidekiq_options queue: :mailchimp, retry: 3,
          backtrace: true
      end

      def perform(payload)
        SpreeChimpy.perform(payload.with_indifferent_access)
      rescue Excon::Errors::Timeout, Excon::Errors::SocketError
        log "Mailchimp connection timeout reached, closing"
      end

    end
  end
end
