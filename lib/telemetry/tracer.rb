require "./lib/telemetry/span"
require "./lib/telemetry/runner"
require "./lib/telemetry/helpers/id_maker"
require "./lib/telemetry/helpers/time_maker"
require "./lib/telemetry/helpers/jsonifier"
require "forwardable"

module Telemetry
  class Tracer
    include Helpers::IdMaker
    include Helpers::TimeMaker
    include Helpers::Jsonifier
    extend Forwardable

    attr_reader :spans, :id, :current_span, :root_span, :reason, :runner, 
      :start_time, :stop_time, :flushed

    def_delegator :@runner, :run?, :run?
    def_delegator :@runner, :override=, :override=
    def_delegator :@current_span, :annotations, :annotations

    def initialize(opts={})
      check_dirty_bits(opts)
      @id = opts[:trace_id] || generate_id
      #current span in the context of this RPC call
      @current_span = Span.new({:id => opts[:parent_span_id]})
      @spans = [@current_span]
      @runner = Runner.new(opts)
      @in_progress = false
      @flushed = false
    end

    def dirty?
      !!@dirty
    end

    def in_progress?
      !!@in_progress
    end

    def annotate(params={})
      current_span.annotate(params)
    end

    def start
      if run?
        @start_time = time
        @in_progress = true
      end
    end

    def stop
      if run?
        @stop_time = time
        @in_progress = false
        flush!
      end
    end

    def apply(&block)
      if run?
        start
        yield self
        stop
      else
        yield
      end
    end

    def to_hash
      {:id => id,
       :pid => pid,
       :start_time => start_time,
       :stop => stop_time,
       :current_span_id => @current_span.id,
       :spans => spans.map(&:to_hash)}
    end

    def flushed?
      !!@flushed
    end

    def flush!
      @flushed = true
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
