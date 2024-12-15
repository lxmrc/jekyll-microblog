# frozen_string_literal: true

require_relative 'microblog/version'

module Jekyll
  module Microblog
    class Error < StandardError; end

    class LogCommand < Command
      class << self
        def init_with_program(prog)
          prog.command(:"microblog:setup") do |c|
            c.syntax 'microblog:setup'
            c.description 'Set up microblog collection'

            c.action do |_args, _options|
              print 'Collection name (default: microposts): '
              collection_name = $stdin.gets.chomp
              collection_name = 'microposts' if collection_name.empty?

              update_config(collection_name)
              FileUtils.mkdir_p("_#{collection_name}")

              Jekyll.logger.info 'Microblog setup complete:', "Collection '#{collection_name}' configured"
            end
          end

          prog.command(:log) do |c|
            c.syntax 'log TEXT'
            c.description 'Create a new micropost'

            c.action do |args, _options|
              site = Jekyll::Site.new(Jekyll.configuration)
              collection_name = site.config.dig('microblog', 'collection')

              unless collection_name
                Jekyll.logger.error 'Microblog not configured.', "Run 'jekyll microblog:setup' first"
                exit 1
              end

              text = args.join(' ')
              timestamp = Time.now.strftime('%Y-%m-%d-%H-%M-%S')
              path = "_#{collection_name}/#{timestamp}.md"

              FileUtils.mkdir_p("_#{collection_name}")

              File.open(path, 'w') do |f|
                f.puts '---'
                f.puts "date: #{Time.now.strftime('%Y-%m-%d %H:%M:%S %z')}"
                f.puts '---'
                f.puts
                f.puts text
              end

              Jekyll.logger.info 'Created micropost:', path
            end
          end
        end

        private

        def update_config(collection_name)
          config_lines = File.exist?('_config.yml') ? File.readlines('_config.yml') : []
          yaml = begin
            YAML.load_file('_config.yml')
          rescue StandardError
            {}
          end

          if yaml.dig('collections', collection_name)
            microblog_index = config_lines.find_index { |l| l.strip.start_with?('microblog:') }
            if microblog_index
              config_lines[microblog_index..microblog_index + 1] = "microblog:\n  collection: #{collection_name}\n"
            else
              config_lines << "\nmicroblog:\n  collection: #{collection_name}\n"
            end
          else
            yaml['collections'] ||= {}
            yaml['collections'][collection_name] = { 'output' => true }
            yaml['microblog'] = { 'collection' => collection_name }

            collections_index = config_lines.find_index { |l| l.strip.start_with?('collections:') }
            microblog_index = config_lines.find_index { |l| l.strip.start_with?('microblog:') }

            if collections_index
              config_lines.insert(collections_index + 1, "  #{collection_name}:\n    output: true\n")
            else
              config_lines << "\ncollections:\n  #{collection_name}:\n    output: true\n"
            end

            if microblog_index
              config_lines[microblog_index..microblog_index + 1] = "microblog:\n  collection: #{collection_name}\n"
            else
              config_lines << "\nmicroblog:\n  collection: #{collection_name}\n"
            end
          end

          File.write('_config.yml', config_lines.join)
        end
      end
    end
  end
end
