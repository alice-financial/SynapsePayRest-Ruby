module SynapsePayRest
  class Nodes
    # TODO: Should refactor this to HTTPClient
    VALID_QUERY_PARAMS = [:page, :per_page, :type].freeze

    attr_accessor :client

    def initialize(client)
      @client = client
    end

    def add(payload: raise('payload is required'))
      path = create_node_path
      client.post(path, payload)
    end

    # if node_id is nil then returns all nodes
    def get(node_id: nil, **options)
      # TODO: Should factor this out into HTTPClient and separate args for paginate/search(name/email)/per_page
      params = VALID_QUERY_PARAMS.map do |p|
        options[p] ? "#{p}=#{options[p]}" : nil
      end.compact

      # TODO: Probably should use CGI or RestClient's param builder instead of
      # rolling our own, probably error-prone and untested version
      # https://github.com/rest-client/rest-client#usage-raw-url
      path = create_node_path(node_id: node_id)
      path += '?' + params.join('&') if params.any?
      client.get(path)
    end

    # TODO: separate this into different methods
    def verify(node_id: nil, payload: raise('payload is required'))
      if node_id
        # verify microdeposits
        path = create_node_path(node_id: node_id)
        @client.patch(path, payload)
      else
        # verify MFA question(s)
        path = create_node_path
        @client.post(path, payload)
      end
    end

    def delete(node_id: raise('node_id is required'))
      path = create_node_path(node_id: node_id)
      client.delete(path)
    end

    private

    def create_node_path(node_id: nil)
      path = ['/users', client.user_id, 'nodes' ]
      path << node_id if node_id
      path.join('/')
    end
  end
end
