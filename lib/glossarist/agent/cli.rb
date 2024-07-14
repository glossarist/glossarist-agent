require "thor"
require_relative "iho/cli"

module Glossarist
  module Agent
    class Cli < Thor
      desc "iho SUBCOMMAND ...ARGS", "IHO-related commands"
      subcommand "iho", Iho::Cli
    end
  end
end
