# Script for ad-hoc experiments
#
# @author Yogesh Prasad Kurmi (ykurmi@vmware.com)

require 'securerandom'
require 'set'
require_relative 'proxy'
require_relative 'direct'

# Wavefront Metrics Data format
#   <metricName> <metricValue> [<timestamp>] source=<source> [pointTags]
#
# Example
#   "new-york.power.usage 42422 1533529977 source=localhost datacenter=dc1"
def send_metrics_via_proxy(proxy_client)
  proxy_client.send_metric(
      "new-york.power.usage", 42422.0, nil, "localhost", {"datacenter"=>"dc1"})

  puts "Sent metric: 'new-york.power.usage' to proxy"
end

# Wavefront Histogram Data format
#   {!M | !H | !D} [<timestamp>] #<count> <mean> [centroids] <histogramName> source=<source>
#   [pointTags]

# Example
#   "!M 1533529977 #20 30.0 #10 5.1 request.latency source=appServer1 region=us-west"
def send_histogram_via_proxy(proxy_client)
  proxy_client.send_distribution(
      "request.latency",
      [[30, 20], [5.1, 10]], Set.new([DAY, HOUR, MINUTE]), nil, "appServer1", {"region"=>"us-west"})

  puts "Sent histogram: 'request.latency' to proxy"
end

# Wavefront Tracing Span Data format
#   <tracingSpanName> source=<source> [pointTags] <start_millis> <duration_milli_seconds>

# Example
#   "getAllProxyUsers source=localhost
#   traceId=7b3bf470-9456-11e8-9eb6-529269fb1459
#   spanId=0313bafe-9457-11e8-9eb6-529269fb1459
#   parent=2f64e538-9457-11e8-9eb6-529269fb1459
#   application=WavefrontRuby http.method=GET service=TestRuby
#   1533529977 343500"
def send_tracing_span_via_proxy(proxy_client)
  proxy_client.send_span(
      "getAllProxyUsers", Time.now.to_i, 343500, "localhost",
      SecureRandom.uuid, SecureRandom.uuid, [SecureRandom.uuid], nil,
      {"application"=>"WavefrontRuby", "http.method"=>"GET", "service"=>"TestRuby"}, nil)

  puts "Sent tracing span: 'getAllProxyUsers' to proxy"
end

# Wavefront Metrics Data format
#   <metricName> <metricValue> [<timestamp>] source=<source> [pointTags]
#
# Example
#   "ruby.direct.new-york.power.usage 42422 1533529977 source=localhost datacenter=dc1"
def send_metrics_via_direct_ingestion(direct_ingestion_client)
  direct_ingestion_client.send_metric("ruby.direct.new york.power.usage",
                                        42422.0, nil, "localhost", nil)
  puts "Sending metrics 'ruby.direct.new-york.power.usage' via direct ingestion client"
end

# Wavefront Histogram Data format
#   {!M | !H | !D} [<timestamp>] #<count> <mean> [centroids] <histogramName> source=<source>
#   [pointTags]

# Example
#   "!M 1533529977 #20 30.0 #10 5.1 ruby.direct.request.latency source=appServer1 region=us-west"
def send_histogram_via_direct_ingestion(direct_ingestion_client)
  direct_ingestion_client.send_distribution(
      "ruby.direct.request.latency", [[30, 20], [5.1, 10]], Set.new([DAY, HOUR, MINUTE]),
      nil, "appServer1", {"region"=>"us-west"})
  puts "Sending histogram 'ruby.direct.request.latency' via direct ingestion client"
end

# Wavefront Tracing Span Data format
#   <tracingSpanName> source=<source> [pointTags] <start_millis> <duration_milli_seconds>

# Example
#   "getAllUsersFromRubyDirect source=localhost
#   traceId=7b3bf470-9456-11e8-9eb6-529269fb1459
#   spanId=0313bafe-9457-11e8-9eb6-529269fb1459
#   parent=2f64e538-9457-11e8-9eb6-529269fb1459
#   application=WavefrontRuby http.method=GET service=TestRuby
#   1533529977 343500"
def send_tracing_span_via_direct_ingestion(direct_ingestion_client)
  direct_ingestion_client.send_span(
      "getAllUsersFromRubyDirect", Time.now.to_i, 343500, "localhost",
      SecureRandom.uuid, SecureRandom.uuid, [SecureRandom.uuid],
      nil, {"application"=>"WavefrontRuby", "http.method"=>"GET", "service"=>"TestRuby"}, nil)
  puts "Sending tracing span 'getAllUsersFromRubyDirect' via direct ingestion client"
end

if __FILE__ == $0
  wavefront_server = ARGV[0]
  token = ARGV[1]
  proxy_host =  ARGV[2] ? ARGV[2] : nil
  metrics_port = ARGV[3] ? ARGV[3] : nil
  distribution_port = ARGV[4] ? ARGV[4] : nil
  tracing_port = ARGV[5] ? ARGV[5] : nil

  # create a client to send data via proxy
  wavefront_proxy_client = Wavefront::WavefrontProxyClient.new(proxy_host, metrics_port, distribution_port, tracing_port)

  # create a client to send data via direct ingestion
  wavefront_direct_client = Wavefront::WavefrontDirectIngestionClient.new(wavefront_server, token)
  begin
    while true do
      send_metrics_via_proxy(wavefront_proxy_client)
      send_histogram_via_proxy(wavefront_proxy_client)
      send_tracing_span_via_proxy(wavefront_proxy_client)
      send_metrics_via_direct_ingestion(wavefront_direct_client)
      send_histogram_via_direct_ingestion(wavefront_direct_client)
      send_tracing_span_via_direct_ingestion(wavefront_direct_client)
      sleep 1
    end
  ensure
    wavefront_proxy_client.close
    wavefront_direct_client.close
  end
end
