
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
        puts "Ruby Command Options: #{convert_map(cmd[4].to_hash)}\r"
        opts = convert_map(cmd[4].to_hash)
        if cmd[0].to_s == "invoke"
          # puts "command : #{cmd[1]}.send(:#{cmd[2]}, *#{cmd[3].to_a})}"
          begin
            res = if not_empty?(cmd[1])
              eval("#{cmd[1]}.send(:#{cmd[2]}, *#{cmd[3].to_a})", context, __FILE__, __LINE__)
            else
              eval("send(:#{cmd[2]}, *#{cmd[3].to_a})", context, __FILE__, __LINE__)
            end
            puts "Eval result: #{res.inspect}\n\r"

            if opts.keys.include?(:as_var)
              instance_variable_set("@#{opts[:as_var]}", res)
              write(oup, 'ok')
            else
              write(oup, 'ok', res)
            end

            #write(oup, 'ok', res)
          rescue StandardError => exception
            write(oup, 'error', exception.message)  
          end
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

    def convert_map(map)
      map.collect do |k,v|
        case k
        when Erlang::Atom
          kk = k.to_s.to_sym
        else
        kk = k.to_s
        end

        case v
        when Erlang::Atom
          vv = v.to_s.to_sym
        else
          vv = v.to_s
        end

        [kk, vv]
      end.to_h
    end

    def read(inp)
      encoded_length = inp.read(4)
      return nil unless encoded_length

      length = encoded_length.unpack1('N')
      cmd = Erlang.binary_to_term(inp.read(length))
      puts "Received command : #{cmd}"
      cmd
    end

    def write(oup, prefix, value = nil)
      #if value.nil?
      #  response = Erlang.term_to_binary(Erlang::Atom[prefix])
      #else
        # response = Erlang.term_to_binary(Erlang::Tuple[@request_id, value])
        response = Erlang.term_to_binary(Erlang::Tuple[Erlang::Atom[prefix], value])
      #end

      oup.write([response.bytesize].pack('N'))
      oup.write(response)
      true
    end
  end
end
