require "test_helper"
require "./lib/telemetry/span"
require "socket"

module Telemetry
  describe Span do
    it "defaults to a root span if no parent_span_id is supplied" do
      span = Span.new()
      assert span.root?
    end

    it "is attached to a trace_id" do
      span = Span.new({:trace_id => "foo"})
      assert_equal "foo", span.trace_id
    end

    it "sets itself up with a human reable name if one is supplied" do
      span = Span.new({:name => "fubar"})
      assert_equal "fubar", span.name
    end

    it "gets its own  4byte id" do
      span = Span.new
      assert span.id.instance_of?(Fixnum)
      assert 8, span.id.size
    end

    it "id is different from the parent_span_id if one is supplied" do
      span = Span.new({:parent_span_id => "fubar123"})
      assert span.id != span.parent_span_id
    end

    it "has a parent_span if a parent_span_id is supplied" do
      parent_span_id = "fubar123"
      span = Span.new({:parent_span_id => parent_span_id})
      assert_equal span.parent_span_id, parent_span_id
      assert !span.root?
    end

    it "has zero to many annotations" do
      span = Span.new
      assert span.annotations.empty?
    end

    it "logs a start time in nano seconds when its initialized" do
      span = Span.new
      time_in_nanos = (Time.now.to_f * 1000000000).to_i
      assert span.start_time < time_in_nanos
    end

    it "stores the process id its executing on" do
      assert_equal Process.pid, Span.new.pid
    end

    it "stores the fully qualified hostname its executing on" do
      assert_equal Socket.gethostname, Span.new.hostname
    end

    it "sets the flushed state to true once its flushed" do
      span = Span.new
      assert_equal false, span.flushed?
      span.flush!
      assert_equal true, span.flushed?
    end
  end
end
