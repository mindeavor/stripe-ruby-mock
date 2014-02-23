module StripeMock
  module RequestHandlers
    module Coupons

      def Coupons.included(klass)
        klass.add_handler 'post /v1/coupons',        :new_coupon
        klass.add_handler 'get /v1/coupons/(.*)',    :get_coupon
        klass.add_handler 'delete /v1/coupons/(.*)', :delete_coupon
        klass.add_handler 'get /v1/coupons',         :list_coupons
      end

      def new_coupon(route, method_url, params, headers)
        params[:id] ||= new_id('coupon')
        coupons[ params[:id] ] = Data.mock_coupon(params)
      end

      def get_coupon(route, method_url, params, headers)
        route =~ method_url
        assert_existance :coupon, $1, coupons[$1]
        coupons[$1] ||= Data.mock_coupon(:id => $1)
      end

      def delete_coupon(route, method_url, params, headers)
        route =~ method_url
        assert_existance :coupon, $1, coupons[$1]
        coupons.delete($1)
      end

      def list_coupons(route, method_url, params, headers)
        coupons.values
      end

    end
  end
end
