# require 'pry-byebug'
# require 'digest/sha3'
# require 'faraday'
#
# module Ethereum
#   class Client
#     Error = Class.new(StandardError)
#
#     class ConnectionError < Error; end
#
#     class ResponseError < Error
#       def initialize(code, msg)
#         super "#{msg} (#{code})"
#       end
#     end
#
#     def initialize(endpoint, idle_timeout: 5)
#       @json_rpc_endpoint = URI.parse(endpoint)
#       @json_rpc_call_id = 0
#       @idle_timeout = idle_timeout
#     end
#
#     def json_rpc(method, params = [])
#       response = connection.post \
#           '/',
#           {jsonrpc: '2.0', id: rpc_call_id, method: method, params: params}.to_json,
#           {'Accept' => 'application/json',
#            'Content-Type' => 'application/json'}
#       response.assert_success!
#       response = JSON.parse(response.body)
#       response['error'].tap { |error| raise ResponseError.new(error['code'], error['message']) if error }
#       response.fetch('result')
#     rescue Faraday::Error => e
#       raise ConnectionError, e
#     rescue StandardError => e
#       raise Error, e
#     end
#
#     private
#
#     def rpc_call_id
#       @json_rpc_call_id += 1
#     end
#
#     def connection
#       @connection ||= Faraday.new(@json_rpc_endpoint) do |f|
#         # f.adapter :net_http_persistent, pool_size: 5, idle_timeout: @idle_timeout
#       end.tap do |connection|
#         # unless @json_rpc_endpoint.user.empty?
#         #   connection.basic_auth(@json_rpc_endpoint.user, @json_rpc_endpoint.password)
#         # end
#       end
#     end
#   end
# end

def client
  @client ||= Ethereum::Client.new('https://mainnet.infura.io/v3/06f27c7a2e6b458cac8937b33675c3dc')
end

def abi_encode(method, *args)
  '0x' + args.each_with_object(Digest::SHA3.hexdigest(method, 256)[0...8]) do |arg, data|
    data.concat(arg.gsub(/\A0x/, '').rjust(64, '0'))
  end
end

def contract_name
  data = abi_encode('name()')
  abi = client.json_rpc(:eth_call, [{ to: '0xdac17f958d2ee523a2206206994597c13d831ec7', data: data }, 'latest'])
  decoder = Ethereum::Decoder.new
  decoder.decode('string', abi)
end


contract_name

pp 'kek'
