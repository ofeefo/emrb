# frozen_string_literal: true

module Emrb
  # Instruments provide the class methods to create metrics.
  module Instruments
    def self.included(base) = base.extend(ClassMethods)

    # CollidingNameError indicates that a declared instrument will clash with a library method. Use another name.
    class CollidingNameError < StandardError
      def initialize(name) = super("Identifying an instrument with #{name} will override the class method")
    end

    # Provides the instrumentation facilities when including/extending Instruments.
    module ClassMethods
      FORBIDDEN_IDENTIFIERS = instance_methods

      # Initializes a new Prometheus counter using the provided identifier, documentation,
      # and either optional keyword arguments or a block that returns the keyword arguments.
      # The block takes precedence when supplied.
      #
      # identifier - The counter identifier.
      # docs       - The instrument docstring. Defaults to "..."
      #
      # Usage example:
      #
      # class MyApp
      #   class Metrics
      #     include Emrb::Instruments
      #     counter :visits, "Number of visits the app has received"
      #   end
      #
      #   def handle_visits
      #     Metrics.visits.inc
      #     ...
      #   end
      # end
      #
      # For a complete list of options and functionalities for creating and utilizing a Counter,
      # refer to the Prometheus client documentation:
      # https://github.com/prometheus/client_ruby?tab=readme-ov-file#counter
      def counter(identifier, docs = "...", **, &)
        check_identifier!(identifier)
        opts = block_opts(**, &)
        State.counter(id_for(identifier), docs, **opts).tap do |c|
          define_singleton_method(identifier) { c }
        end
      end

      # Initializes a new Prometheus gauge using the provided identifier, documentation,
      # and either optional keyword arguments or a block that returns the keyword arguments.
      # The block takes precedence when supplied.
      #
      # identifier - The counter identifier.
      # docs       - The instrument docstring. Defaults to "..."
      #
      # Usage example:
      #
      # class Thermometer
      #   class Metrics
      #     include Emrb::Instruments
      #     gauge :current_temperature, "current temperature"
      #   end
      #
      #   def set_current_temp
      #     temp = < ... >
      #     Metrics.current_temperature.set(temp)
      #   end
      # end
      #
      # For a full list of options and functionalities for creating and utilizing a Gauge,
      # refer to the Prometheus client documentation:
      # https://github.com/prometheus/client_ruby?tab=readme-ov-file#gauge
      def gauge(identifier, docs = "...", **, &)
        check_identifier!(identifier)
        opts = block_opts(**, &)
        State.gauge(id_for(identifier), docs, **opts).tap do |g|
          define_singleton_method(identifier) { g }
        end
      end

      # Initializes a new Prometheus histogram using the provided identifier, documentation,
      # and either optional keyword arguments or a block that returns the keyword arguments.
      # The block takes precedence when supplied.
      #
      # identifier - The counter identifier.
      # docs       - The instrument docstring. Defaults to "..."
      #
      # Usage example:
      #
      # class MyApp
      #   class Metrics
      #     include Emrb::Instruments
      #     histogram :request_duration, "Duration of requests" do
      #       { labels: [:path, :method], buckets: [0.1, 0.2] }
      #      end
      #   end
      #
      #   def measure_request_duration
      #     labels = { path: request.path, method: request.env["REQUEST_METHOD"].downcase }      #
      #     Metrics.request_duration.observe(Benchmark.realtime { yield }, labels: )
      #   end
      #
      #   get "/" do
      #     measure_request_duration { [200, "OK"] }
      #   end
      # end
      #
      # For all available options and functionalities for creating and utilizing a Histogram,
      # refer to the Prometheus client documentation:
      # https://github.com/prometheus/client_ruby?tab=readme-ov-file#histogram
      def histogram(identifier, docs = "...", **, &)
        check_identifier!(identifier)
        opts = block_opts(**, &)
        State.histogram(id_for(identifier), docs, **opts).tap do |h|
          define_singleton_method(identifier) { h }
        end
      end

      # Initializes a new Prometheus summary using the provided identifier, documentation,
      # and either optional keyword arguments or a block that returns the keyword arguments.
      # The block takes precedence when supplied.
      #
      # identifier - The counter identifier.
      # docs       - The instrument docstring. Defaults to "..."
      #
      # Usage example:
      #
      # class MyApp
      #   class Metrics
      #     include Emrb::Instruments
      #     summary :call_duration, "Duration of a given call"
      #   end

      #   def do_a_call
      #     Metrics.call_duration.observe(Benchmark.realtime { < ... > })
      #   end
      # end
      #
      # For a complete list of options and functionalities for creating and utilizing a Summary,
      # refer to the Prometheus client documentation:
      # https://github.com/prometheus/client_ruby?tab=readme-ov-file#summary
      def summary(identifier, docs = "...", **, &)
        check_identifier!(identifier)
        opts = block_opts(**, &)
        State.summary(id_for(identifier), docs, **opts).tap do |s|
          define_singleton_method(identifier) { s }
        end
      end

      # push the current registry state to a Pushgateway.
      # It receives an obligatory job identifier, and optionally all supported
      # keyword arguments of a Prometheus::Client::Push.
      #
      # job - Job identifier
      #
      # Usage example:
      #
      # class MyJob
      #   class Metrics
      #     include Emrb::Instruments
      #     counter :processed_tasks
      #   end
      #
      #   def do_the_things
      #     begin
      #       tasks.each do |t|
      #         < ... >
      #         Metrics.processed_tasks.inc
      #       end
      #     rescue
      #         < ... >
      #     ensure
      #       Metrics.push("job_name")
      #     end
      #   end
      # end
      def push(job, **) = State.push(job, **)

      # Periodically invokes #push in a given frequency.
      #
      # job       - Job identifier
      # frequency - Frequency, in seconds, in which #push will be called.
      #
      # Returns nothing.
      def push_periodically(job, frequency = 10)
        Thread.new do
          sleep(frequency)
          push(job)
        end
      end

      # Allows instruments to be declared with preset labels.
      #
      # labels - A hash containing the preset labels and values
      #
      # Usage example:
      #
      # class Metrics
      #   include Emrb::Instruments
      #   with_presets my: "label", other: "label" do
      #     counter :my_counter, "a counter"
      #   end
      # end
      #
      # Metrics.my_counter.labels => [:my, :other]
      # Metrics.my_counter.preset_labels => { my: "label", other: "label" }
      def with_presets(**labels, &)
        raise LocalJumpError, "no block given" unless block_given?
        raise ArgumentError, "labels are empty" if labels.nil? || labels.empty?

        old = (@presets ||= {})
        current = old.merge labels
        @presets = current
        instance_eval(&)
        @presets = old
      end

      # Provides a way to compose metrics for different subsystems.
      # All instruments created within a subsystem will have their identifiers
      # prefixed with the prefix param.
      #
      # prefix          - determines the prefix of all instruments declared
      #                   within the subsystem and how to access those instruments
      #                   within the implementation.
      #
      # inherit_presets - determines whether or not to inherit presets from
      #                   the parent. Defaults to false.
      #
      # presets         - preset of labels to be used by all Instruments
      #                   of a given subsystem.
      #
      # Usage example:
      #
      # class Metrics
      #   subsystem :http do
      #     histogram :request_duration, "duration of requests" do
      #       { labels: [:method, :path] }
      #     end
      #   end
      #
      #   subsystem :postgres do
      #     subsystem :master, op: "write" do
      #       counter :op_count
      #     end
      #
      #     subsystem :replica, op: "read" do
      #       counter :op_count
      #     end
      #   end
      # end
      #
      # # Acessing instruments:
      # Metrics.http.request_duration
      # Metrics.postgres.master.op_count
      # Metrics.postgres.replica.op_count
      # rubocop:disable Metrics/MethodLength
      def subsystem(prefix, inherit_presets: false, **presets, &)
        raise LocalJumpError, "no block given" unless block_given?

        s_prefix = prefix.to_s
        s_prefix.delete_suffix! "_" if s_prefix.end_with? "_"
        subsystem = id_for(s_prefix.to_sym)

        presets.merge! @presets if inherit_presets && !@presets.nil?

        s = Class.new
        s.include(Instruments)
        s.instance_variable_set(:@subsystem, subsystem)
        s.instance_variable_set(:@presets, presets)
        s.instance_eval(&)
        define_singleton_method(prefix) { s }
      end
      # rubocop:enable Metrics/MethodLength

      # Internal: validates whether to concatenate the given identifier with
      # a pre-existing susbsystem name.
      def id_for(identifier)
        return identifier unless @subsystem

        :"#{@subsystem}_#{identifier}"
      end

      # Internal: Validates the provided options to create a given instrument
      # and performs the merge of all options with presets when they are present.
      def block_opts(**opts, &)
        res = block_given? ? yield : opts
        return res if @presets.nil?

        res[:labels] = [] if res[:labels].nil?
        res[:labels].append(*@presets.keys)

        if res[:preset_labels].nil?
          res[:preset_labels] = @presets
          return res
        end

        res[:preset_labels].merge!(**@presets)
        res
      end

      # Internal: Validates whether the given identifier might override one of the class methods.
      # In a positive case, raises CollidingNameError.
      def check_identifier!(id)
        raise Instruments::CollidingNameError, id if FORBIDDEN_IDENTIFIERS.include? id
      end
    end
  end
end
