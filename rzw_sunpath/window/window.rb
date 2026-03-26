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
        return [] if token.nil?

        parts =
          if token.is_a?(Array)
            token
          else
            token.to_s.split('|')
          end
        return parts if method.nil?
        parts.map(&method).to_a
      end

    end
  end
end
