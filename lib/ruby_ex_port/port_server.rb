
require 'bundler'
require 'erlang/etf'
require 'stringio'

require 'toolrack'

module RubyExPort
  class PortServer
    include TR::CondUtils

    def initialize(opts = []) 
    end

    def start()

      inp, oup = nostdio()

      context = binding
      while (cmd = read(inp))
        puts "Ruby Command: #{cmd[0]}\r"
        if cmd[0] == "invoke"
          # puts "command : #{cmd[1]}.send(:#{cmd[2]}, *#{cmd[3].to_a})}"
          res = if not_empty?(cmd[1])
            eval("#{cmd[1]}.send(:#{cmd[2]}, *#{cmd[3].to_a})", context, __FILE__, __LINE__)
          else
            eval("send(:#{cmd[2]}, *#{cmd[3].to_a})", context, __FILE__, __LINE__)
          end
          puts "Eval result: #{res.inspect}\n\r"
          write(oup)
        end
      end


    end

    def nostdio()
      input = IO.new(3)
      output = IO.new(4)
      output.sync = true
      [input, output]
    end

    def stdio_io()
      [STDIN, STDOUT]
    end

    def read(inp)
      encoded_length = inp.read(4)
      return nil unless encoded_length

      length = encoded_length.unpack1('N')
      cmd = Erlang.binary_to_term(inp.read(length))
      puts "Received command : #{cmd}"
      cmd
    end

    def write(oup, value)
      # response = Erlang.term_to_binary(Erlang::Tuple[@request_id, value])
      response = Erlang.term_to_binary(Erlang::Tuple[Erlang::Atom['ok'], value])
      oup.write([response.bytesize].pack('N'))
      oup.write(response)
      true
    end

  end
end
