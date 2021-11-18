require 'rest-client'
require 'lita-onewheel-beer-base'
require 'json'

module Lita
  module Handlers
    class OnewheelBeerProperpintUntappd < OnewheelBeerBase
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
        beers = self.get_source response
        reply = "Proper Pint taps: "
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

      def get_source(response)
        # Lita.logger.debug "get_source started"
        # unless (response = redis.get('page_response'))
        #   Lita.logger.info 'No cached result found, fetching.'
        uri = 'https://untappd.com/v/proper-pint-taproom/6478413'
        # quick 'n dirty oakroom hack
        Lita.logger.info response.matches
        if response.matches[0] == 'ppo'
          uri = 'https://untappd.com/v/proper-pint-oakroom/10632112'
        end

        Lita.logger.info "Getting #{uri}"
        response = RestClient.get(uri)
          # redis.setex('page_response', 1800, response)
        # end
        parse_response response
      end

      # This is the worker bee- decoding the html into our "standard" document.
      # Future implementations could simply override this implementation-specific
      # code to help this grow more widely.
      def parse_response(response)
        Lita.logger.debug "parse_response started."

        gimme_what_you_got = {}
        noko = Nokogiri.HTML response
        noko.css('div.beer-details').each do |beer_node|
          # beer_node = beer_node.css('div#section_217106141')
          name_n_tap = beer_node.css('h5 a').first.children.to_s
          short_desc = beer_node.css('h5 em').first.children.to_s
          brewery = beer_node.css('h6 a').first.children.to_s
          abv_node = beer_node.css('h6 span').first.children.to_s

          # Lita.logger.info("NnT: #{name_n_tap}")

          tap = name_n_tap[/^\d+/]
          next if tap.nil?
          beer_name = name_n_tap[/[^\..]+$/].strip
          abv = abv_node[/^\d+\.\d+/]
          beer_desc = short_desc

          # full_text_search = "#{tap.sub /\d+/, ''} #{brewery} #{beer_name} #{beer_desc.to_s.gsub /\d+\.*\d*%*/, ''}"
          # prices = get_prices(beer_node)

          gimme_what_you_got[tap] = {
              # type: tap_type,
              # remaining: remaining,
              brewery: brewery.to_s,
              name: beer_name.to_s,
              desc: beer_desc.to_s,
              abv: abv.to_f
              # prices: prices,
              # price: prices[1][:cost],
              # search: full_text_search
          }
        end
        gimme_what_you_got
      end

      Lita.register_handler(self)
    end
  end
end
