require 'ruby-mpd'

module MPD::Plugins

  # Batch send multiple commands at once for speed.
  module CommandList
    # Send multiple commands as a block.
    # 
    # For a list of supported commands, see CommandList::Commands
    #
    # @param [Hash] opts the options to create a message with.
    # @option opts [Boolean] :results Return results (`true`) or ignore them, for speed
    # @return [Array] of command results.
    # @return [nil] if no commands have any results.
    # @see CommandList::Commands
    def command_list(opts={results:true},&commands)
      @mutex.synchronize do
        begin
          socket.puts "command_list_begin"
          CommandList::Commands.new(self).instance_eval(&commands)
          socket.puts "command_list_end"
          response = handle_server_response
          parse_response(:commandlist, response) if opts[:results]
        rescue Errno::EPIPE
          reconnect
          retry
        end
      end
    end
  end

  class CommandList::Commands
    def initialize(mpd)
      @mpd = mpd
    end

    include MPD::Plugins::Controls
    include MPD::Plugins::PlaybackOptions
    include MPD::Plugins::Queue
    include MPD::Plugins::Stickers

    private
      def send_command(command,*args)
        puts "PRIVATE #{command}"
        @mpd.send(:socket).puts @mpd.send(:convert_command, command, *args)
      end
  end
end
