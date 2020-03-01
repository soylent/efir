# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

class Efir
  class Client
    def initialize(uri, **opts)
      @id = 0
      @url = url(uri)
      @http = connect(**opts)
    end

    def request(method, *params)
      request = Net::HTTP::Post.new(@url)
      request['user-agent'] = 'efir'
      request.content_type = 'application/json'
      request.body = JSON.fast_generate(
        jsonrpc: '2.0', method: method, params: params, id: @id += 1
      )

      begin
        response = @http.request(request)
      rescue Net::ReadTimeout
        raise Error, "read timeout: #{@url}"
      end

      json = JSON.parse(response.body)

      id = json['id']
      raise Error, "invalid response id: #{id.inspect}" unless id == @id

      error = json['error']
      if error
        message = error['message']
        data = error['data']

        # Make parity behave like others
        if data.respond_to?(:to_str)
          return data if data.delete_prefix!('Reverted ')

          message << ' ' << data
        end

        raise Error, message
      end

      json['result']
    end

    def close
      @http&.finish
    end

    private

    def url(val)
      begin
        url = URI.parse(val)
      rescue URI::InvalidURIError
        raise Error, "invalid url: #{val.inspect}"
      end
      unless url.scheme == 'http' || url.scheme == 'https'
        raise Error, "invalid url: #{val.inspect}"
      end
      url
    end

    def connect(open_timeout: 5, read_timeout: 60, keep_alive_timeout: 5)
      Net::HTTP.start(
        @url.host,
        @url.port,
        use_ssl: @url.scheme == 'https',
        open_timeout: open_timeout,
        read_timeout: read_timeout,
        keep_alive_timeout: keep_alive_timeout
      )
    rescue Net::OpenTimeout, SystemCallError, SocketError
      raise Error, "cannot connect to: #{@url}"
    end
  end
end
