require 'rest-client'
require 'json'

module SynapsePayRest
  # Wrapper for HTTP requests using RestClient.
  class HTTPClient
    # @!attribute [rw] base_url
    #   @return [String] the base url of the API (production or sandbox)
    # @!attribute [rw] config
    #   @return [Hash] various settings related to request headers
    attr_accessor :base_url, :config

    # @!attribute [rw] proxy_url
    #   @return [String] the url which is used to proxy outboard requests
    attr_reader :proxy_url

    # @param base_url [String] the base url of the API (production or sandbox)
    # @param client_id [String]
    # @param client_secret [String]
    # @param fingerprint [String]
    # @param ip_address [String]
    # @param logging [Boolean] (optional) logs to stdout when true
    # @param log_to [String] (optional) file path to log to file (logging must be true)
    # @param proxy_url [String] (optional) proxy url which is used to proxy outbound requests
    def initialize(base_url:, client_id:, fingerprint:, ip_address:,
                   client_secret:, **options)
      log_to         = options[:log_to] || 'stdout'
      RestClient.log = log_to if options[:logging]
      @logging       = options[:logging]

      RestClient.proxy = options[:proxy_url] if options[:proxy_url]
      @proxy_url = options[:proxy_url]

      @config = {
        client_id:     client_id,
        client_secret: client_secret,
        fingerprint:   fingerprint,
        ip_address:    ip_address,
        oauth_key:     '',
      }
      @base_url = base_url
    end

    # Returns headers for HTTP requests.
    # 
    # @return [Hash]
    def headers
      user    = "#{config[:oauth_key]}|#{config[:fingerprint]}"
      gateway = "#{config[:client_id]}|#{config[:client_secret]}"

      access_control_headers = {
        'Access-Control-Allow-Methods' => 'GET,PUT,POST,DELETE,OPTIONS',
        'Access-Control-Allow-Headers' => 'X-Requested-With,Content-type,Accept,X-Access-Token,X-Key',
        'Access-Control-Allow-Origin' => '*'
      }

      request_headers = {
        :content_type  => :json,
        :accept        => :json,
        'X-SP-GATEWAY' => gateway,
        'X-SP-USER'    => user,
        'X-SP-USER-IP' => config[:ip_address]
      }

      request_headers.merge!(access_control_headers) if @proxy_url
      request_headers
    end
    # Alias for #headers (legacy name)
    alias_method :get_headers, :headers

    # Updates headers.
    # 
    # @param oauth_key [String,void]
    # @param fingerprint [String,void]
    # @param client_id [String,void]
    # @param client_secret [String,void]
    # @param ip_address [String,void]
    # 
    # @return [void]
    def update_headers(oauth_key: nil, fingerprint: nil, client_id: nil,
                       client_secret: nil, ip_address: nil, **options)
      config[:fingerprint]   = fingerprint if fingerprint
      config[:oauth_key]     = oauth_key if oauth_key
      config[:client_id]     = client_id if client_id
      config[:client_secret] = client_secret if client_secret
      config[:ip_address]    = ip_address if ip_address
      nil
    end

    # Sends a POST request to the given path with the given payload.
    # 
    # @param path [String]
    # @param payload [Hash]
    # @param idempotency_key [String] (optional) avoid accidentally performing the same operation twice
    #
    # @raise [SynapsePayRest::Error] subclass depends on HTTP response
    # 
    # @return [Hash] API response
    def post(path, payload, **options)
      headers = get_headers
      if options[:idempotency_key]
        headers = headers.merge({'X-SP-IDEMPOTENCY-KEY' => options[:idempotency_key]})
      end

      response = RestClient::Request.execute(method: :post,
                                             url: full_url(path),
                                             payload: payload.to_json,
                                             ssl_client_cert: OpenSSL::X509::Certificate.new(SANDBOX_PEM),
                                             verify_ssl: OpenSSL::SSL::VERIFY_NONE,
                                             headers: headers)
      p 'RESPONSE:', JSON.parse(response) if @logging
      JSON.parse(response)
    end

    # Sends a PATCH request to the given path with the given payload.
    # 
    # @param path [String]
    # @param payload [Hash]
    # 
    # @raise [SynapsePayRest::Error] subclass depends on HTTP response
    # 
    # @return [Hash] API response
    def patch(path, payload)
      response = with_error_handling { RestClient::Request.execute(:method => :patch, :url => full_url(path), :payload => payload.to_json, :headers => headers, :timeout => 300) }
      p 'RESPONSE:', JSON.parse(response) if @logging
      JSON.parse(response)
    end

    SANDBOX_PEM = <<~PEM.freeze
      -----BEGIN CERTIFICATE-----
      MIID2TCCAsGgAwIBAgIHAN4Gs/LGhzANBgkqhkiG9w0BAQ0FADB5MSQwIgYDVQQD
      DBsqLnNhbmRib3gudmVyeWdvb2Rwcm94eS5jb20xITAfBgNVBAoMGFZlcnkgR29v
      ZCBTZWN1cml0eSwgSW5jLjEuMCwGA1UECwwlVmVyeSBHb29kIFNlY3VyaXR5IC0g
      RW5naW5lZXJpbmcgVGVhbTAgFw0xNjAyMDkyMzUzMzZaGA8yMTE3MDExNTIzNTMz
      NloweTEkMCIGA1UEAwwbKi5zYW5kYm94LnZlcnlnb29kcHJveHkuY29tMSEwHwYD
      VQQKDBhWZXJ5IEdvb2QgU2VjdXJpdHksIEluYy4xLjAsBgNVBAsMJVZlcnkgR29v
      ZCBTZWN1cml0eSAtIEVuZ2luZWVyaW5nIFRlYW0wggEiMA0GCSqGSIb3DQEBAQUA
      A4IBDwAwggEKAoIBAQDI3ukHpxIlDCvFjpqn4gAkrQVdWll/uI0Kv3wirwZ3Qrpg
      BVeXjInJ+rV9r0ouBIoY8IgRLak5Hy/tSeV6nAVHv0t41B7VyoeTAsZYSWU11deR
      DBSBXHWH9zKEvXkkPdy9tgHnvLIzui2H59OPljV7z3sCLguRIvIIw8djaV9z7FRm
      KRsfmYHKOBlSO4TlpfXQg7jQ5ds65q8FFGvTB5qAgLXS8W8pvdk8jccmuzQXFUY+
      ZtHgjThg7BHWWUn+7m6hQ6iHHCj34Qu69F8nLamd+KJ//14lukdyKs3AMrYsFaby
      k+UGemM/s2q3B+39B6YKaHao0SRzSJC7qDwbWPy3AgMBAAGjZDBiMB0GA1UdDgQW
      BBRWlIRrE2p2P018VTzTb6BaeOFhAzAPBgNVHRMBAf8EBTADAQH/MAsGA1UdDwQE
      AwIBtjAjBgNVHSUEHDAaBggrBgEFBQcDAQYIKwYBBQUHAwIGBFUdJQAwDQYJKoZI
      hvcNAQENBQADggEBAGWxLFlr0b9lWkOLcZtR9IDVxDL9z+UPFEk70D3NPaqXkoE/
      TNNUkXgS6+VBA2G8nigq2Yj8qoIM+kTXPb8TzWv+lrcLm+i+4AShKVknpB15cC1C
      /NJfyYGRW66s/w7HNS20RmrdN+bWS0PA4CVLXdGzUJn0PCsfsS+6Acn7RPAE+0A8
      WB7JzXWi8x9mOJwiOhodp4j41mv+5eHM0reMh6ycuYbjquDNpiNnsLztk6MGsgAP
      5C59drQWJU47738BcfbByuSTYFog6zNYCm7ACqbtiwvFTwjneNebOhsOlaEAHjup
      d4QBqYVs7pzkhNNp9oUvv4wGf/KJcw5B9E6Tpfk=
      -----END CERTIFICATE-----
    PEM

    # Sends a GET request to the given path with the given payload.
    # 
    # @param path [String]
    # 
    # @raise [SynapsePayRest::Error] subclass depends on HTTP response
    # 
    # @return [Hash] API response
    def get(path)
      p "Headers: #{headers}"
      response = RestClient::Request.execute(method: :get,
                                             url: full_url(path),
                                             ssl_client_cert: OpenSSL::X509::Certificate.new(SANDBOX_PEM),
                                             verify_ssl: OpenSSL::SSL::VERIFY_NONE,
                                             headers: headers)

      p 'RESPONSE:', JSON.parse(response) if @logging
      JSON.parse(response)
    end

    # Sends a DELETE request to the given path with the given payload.
    # 
    # @param path [String]
    # 
    # @raise [SynapsePayRest::Error] subclass depends on HTTP response
    # 
    # @return [Hash] API response
    def delete(path)
      response = with_error_handling { RestClient.delete(full_url(path), headers) }
      p 'RESPONSE:', JSON.parse(response) if @logging
      JSON.parse(response)
    end

    private

    def full_url(path)
      "#{base_url}#{path}"
    end

    def with_error_handling
      yield
    rescue RestClient::Exceptions::Timeout
      body = {
        error: {
          en: "Request Timeout"
        },
        http_code: 504
      }
      raise Error.from_response(body)
    rescue RestClient::Exception => e
      if e.response.headers[:content_type] == 'application/json' 
        body = JSON.parse(e.response.body)
      else
        body = {
          error: {
            en: e.response.body
          },
          http_code: e.response.code
        }
      end
      raise Error.from_response(body)
    end
  end
end
