require 'json'

module SuperCat
  module Sunpath
    module Window

      def destroy_dlg(dlg)
        dlg.close
        if dlg && dlg.visible?
          dlg.close
        end
      end

      def callback_dlg(window, function, &block)
        window.add_action_callback("callback_json") { |dialog, token|
          token_splited = token2data(token, nil)
          f = token_splited[0]
          if function == f
            if token_splited.size > 1
              d = token_splited[1..-1].map { |str|
                hash = JSON.parse(str)
                # Hash[hash.keys[0].to_sym =>hash.values[0] ]
              }
            else
              d = ''
            end
            block.call(d)
          end
          Sketchup.active_model.active_view.invalidate
        }
      end

      def show_dlg(window, &block)
        if window.visible?
          window.bring_to_front
        else
          if Sketchup.platform == :platform_osx
            window.show_modal() {} # Empty block to prevent the block from propagating.
          else
            window.show() {}
          end
        end
        window.add_action_callback("ready") { block.call }
      end

      def token2data(token, method = :to_i)
        token.split('|').map(&method).to_a
      end


    end
  end
end
