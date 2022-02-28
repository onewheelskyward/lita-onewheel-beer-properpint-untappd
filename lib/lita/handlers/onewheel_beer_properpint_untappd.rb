require 'rest-client'
require 'lita-onewheel-beer-untappd-lib'
require 'json'

module Lita
  module Handlers
    class OnewheelBeerProperpintUntappd < OnewheelBeerUntappdLib
      route /^ppo*$/i,
            :taps_list,
            command: true,
            help: {'pp' => 'Display the current taps.'}

      route /^ppo* ([\w ]+)$/i,
            :taps_deets,
            command: true,
            help: {'pp 4' => 'Display the tap 4 deets, including prices.'}

      route /^ppo* ([<>=\w.\s]+)%$/i,
            :taps_by_abv,
            command: true,
            help: {'pp >4%' => 'Display beers over 4% ABV.'}

      route /^ppo* ([<>=\$\w.\s]+)$/i,
            :taps_by_price,
            command: true,
            help: {'pp <$5' => 'Display beers under $5.'}

      route /^ppo* (roulette|random)$/i,
            :taps_by_random,
            command: true,
            help: {'pp roulette' => 'Can\'t decide?  Let me do it for you!'}

      # route /^pplow$/i,
      #       :taps_by_remaining,
      #       command: true,
      #       help: {'pplow' => 'Show me the kegs at <10% remaining, or the lowest one available.'}

      route /^ppo*abvlow$/i,
            :taps_low_abv,
            command: true,
            help: {'ppabvlow' => 'Show me the lowest abv keg.'}

      route /^ppo*abvhigh$/i,
            :taps_high_abv,
            command: true,
            help: {'ppabvhigh' => 'Show me the highest abv keg.'}

      def taps_list(response)
        # wakka wakka
        beers = self.get_source
        oakroom = ''
        if response.matches[0] == 'ppo'
          oakroom = 'Oakroom '
        end

        reply = "Proper Pint #{oakroom}taps: "
        beers.each do |tap, datum|
          reply += "#{tap}) "
          reply += get_tap_type_text(datum[:type])
          reply += datum[:brewery].to_s + ': '
          reply += (datum[:name].to_s.empty?)? '' : datum[:name].to_s + '  '
        end
        reply = reply.strip.sub /,\s*$/, ''

        Lita.logger.info "Replying with #{reply}"
        response.reply reply
      end

      def send_response(tap, datum, response)
        reply = "Proper Pint tap #{tap}) #{get_tap_type_text(datum[:type])}"
        reply += "#{datum[:brewery]}: "
        reply += "#{datum[:name]} "
        reply += "- #{datum[:desc].sub /\.$/, ''}, "
        reply += "#{datum[:abv]}% ABV."
        # reply += "Served in a #{datum[1]['glass']} glass.  "
        # reply += "#{get_display_prices datum[:prices]}, "
        # reply += "#{datum[:remaining]}"

        Lita.logger.info "send_response: Replying with #{reply}"

        response.reply reply
      end

      def get_display_prices(prices)
        price_array = []
        prices.each do |p|
          price_array.push "#{p[:size]} - $#{p[:cost]}"
        end
        price_array.join ' | '
      end

      def get_source
        # Lita.logger.debug "get_source started"
        # unless (response = redis.get('page_response'))
        #   Lita.logger.info 'No cached result found, fetching.'
        uri = 'https://untappd.com/v/proper-pint-taproom/6478413'
        # quick 'n dirty oakroom hack
        # Lita.logger.info response.matches
        # if response.matches[0] == 'ppo'
        #   uri = 'https://untappd.com/v/proper-pint-oakroom/10632112'
        # end

        Lita.logger.info "Getting #{uri}"
        response = RestClient.get(uri)
          # redis.setex('page_response', 1800, response)
        # end
        parse_response response
      end

      Lita.register_handler(self)
    end
  end
end
