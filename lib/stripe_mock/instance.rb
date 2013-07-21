module StripeMock
  class Instance

    # Handlers are ordered by priority
    @@handlers = []

    def self.add_handler(route, name)
      @@handlers << {
        :route => %r{^#{route}$},
        :name => name
      }
    end

    def self.handler_for_method_url(method_url)
      @@handlers.find {|h| method_url =~ h[:route] }
    end

    include StripeMock::RequestHandlers::Charges
    include StripeMock::RequestHandlers::Customers
    include StripeMock::RequestHandlers::InvoiceItems
    include StripeMock::RequestHandlers::Plans


    attr_reader :charges, :customers, :plans, :error_queue
    attr_accessor :debug, :strict

    def initialize
      @customers = {}
      @charges = {}
      @plans = {}

      @id_counter = 0
      @error_queue = ErrorQueue.new
      @debug = false
      @strict = true
    end

    def mock_request(method, url, api_key, params={}, headers={})
      return {} if method == :xtest

      # Ensure params hash has symbols as keys
      params = Stripe::Util.symbolize_names(params)

      if @debug == true
        puts "[StripeMock req] #{method} #{url}"
        puts "                 #{params}"
      end

      method_url = "#{method} #{url}"

      if handler = Instance.handler_for_method_url(method_url)
        if mock_error = @error_queue.error_for_handler_name(handler[:name])
          @error_queue.dequeue
          raise mock_error
        else
          res = self.send(handler[:name], handler[:route], method_url, params, headers)
          puts "[StripeMock res] #{res}" if @debug == true
          [res, api_key]
        end
      else
        puts "WARNING: Unrecognized method + url: [#{method} #{url}]"
        puts " params: #{params}"
        [{}, api_key]
      end
    end

    private

    def assert_existance(type, id, obj, message=nil)
      return unless @strict == true

      if obj.nil?
        msg = message || "No such #{type}: #{id}"
        raise Stripe::InvalidRequestError.new(msg, type.to_s, 400)
      end
    end

    def new_id(prefix)
      # Stripe ids must be strings
      "test_#{prefix}_#{@id_counter += 1}"
    end

  end
end
