require 'log4r'

module VagrantPlugins
  module Kernel_V2
    # Represents a single configured provisioner for a VM.
    class VagrantConfigProvisioner
      # Unique name for this provisioner
      #
      # @return [String]
      attr_reader :name

      # Internal unique name for this provisioner
      # Set to the given :name if exists, otherwise
      # it's set as a UUID.
      #
      # Note: This is for internal use only.
      #
      # @return [String]
      attr_reader :id

      # The type of the provisioner that should be registered
      # as a plugin.
      #
      # @return [Symbol]
      attr_reader :type

      # The configuration associated with the provisioner, if there is any.
      #
      # @return [Object]
      attr_accessor :config

      # When to run this provisioner. Either "once", "always", or "never"
      #
      # @return [String]
      attr_accessor :run

      # Whether or not to preserve the order when merging this with a
      # parent scope.
      #
      # @return [Boolean]
      attr_accessor :preserve_order

      # The name of a provisioner to run before it has started
      #
      # @return [String]
      attr_accessor :before

      # The name of a provisioner to run after it is finished
      #
      # @return [String]
      attr_accessor :after

      def initialize(name, type)
        @logger = Log4r::Logger.new("vagrant::config::vm::provisioner")
        @logger.debug("Provisioner defined: #{name}")

        @id = name || SecureRandom.uuid
        @config  = nil
        @invalid = false
        @name    = name
        @preserve_order = false
        @run     = nil
        @type    = type
        @before  = nil
        @after   = nil

        # Attempt to find the provisioner...
        if !Vagrant.plugin("2").manager.provisioners[type]
          @logger.warn("Provisioner '#{type}' not found.")
          @invalid = true
        end

        # Attempt to find the configuration class for this provider
        # if it exists and load the configuration.
        @config_class = Vagrant.plugin("2").manager.
          provisioner_configs[@type]
        if !@config_class
          @logger.info(
            "Provisioner config for '#{@type}' not found. Ignoring config.")
          @config_class = Vagrant::Config::V2::DummyConfig
        end
      end

      def initialize_copy(orig)
        super
        @config = @config.dup if @config
      end

      def add_config(**options, &block)
        return if invalid?

        current = @config_class.new
        current.set_options(options) if options
        block.call(current) if block
        current = @config.merge(current) if @config
        @config = current
      end

      def finalize!
        return if invalid?

        @config.finalize!
      end

      # Returns whether the provisioner used was invalid or not. A provisioner
      # is invalid if it can't be found.
      #
      # @return [Boolean]
      def invalid?
        @invalid
      end
    end
  end
end
