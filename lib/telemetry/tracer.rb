require "./lib/telemetry/span"
require "./lib/telemetry/helpers/id_maker"
require "./lib/telemetry/helpers/time_maker"

module Telemetry
  class Tracer
    include Helpers::IdMaker
    include Helpers::TimeMaker

    attr_reader :spans, :id, :current_span, :root_span, :reason

    def initialize(opts={})
      check_dirty_bits(opts)
      @id = opts[:trace_id] || generate_id
      #current span in the context of this RPC call
      @current_span = Span.new({:id => opts[:parent_span_id]})
      @spans = [@current_span]
      @enabled = opts[:enabled]
    end

    def dirty?
      !!@dirty
    end

    def enabled?
      !!@enabled
    end

    def annotate(params={})
      current_span.annotate(params)
    end

    private
    def check_dirty_bits(opts={})
      if (!opts[:trace_id] && opts[:parent_span_id]) 
        @dirty = true
        @reason = "trace_id not present; parent_span_id present. Auto generating trace id"
      elsif (opts[:trace_id] && !opts[:parent_span_id])
        @dirty = true
        @reason = "trace_id present; parent_span_id not present."
      end
    end

    class << self
      def current(opts={})
        @tracer ||= Tracer.new(opts)
      end
      alias_method :find_or_create, :current
    end
  end
end
