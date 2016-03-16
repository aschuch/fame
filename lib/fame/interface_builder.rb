require 'nokogiri' 		# to rewrite the storyboard
require 'plist'				# to parse the localizable.plist file
require 'colorize'		# colorful console output
require_relative 'models'

module Fame
  class InterfaceBuilder
    # Keypaths to custom runtime attributes (provided by iOS Extenstion, see Fame.swift)
    LOCALIZATION_ENABLED_KEYPATH = "i18n_enabled".freeze
    LOCALIZATION_COMMENT_KEYPATH = "i18n_comment".freeze

    # All accepted Interface Builder file types
    ACCEPTED_FILE_TYPES = [".storyboard", ".xib"].freeze

    #
    # Initializer
    # @param ib_path The path to an Interface Builder file that should be localized.
    #
    def initialize(ib_path)
      @ib_path = ib_path
    end

    #
    # Searches the current Interface Builder file for XML nodes that should be localized.
    # Localization is only enabled if explicitly set via the fame Interface Builder integration (see Fame.swift file).
    # @return [Array<LocalizedNode>] An array of LocalizedNode objects that represent the localizable elements of the given Interface Builder file
    #
    def nodes
      ib_file = File.open(@ib_path)
      doc = Nokogiri::XML(ib_file)
      ib_file.close

      # Grab raw nokogiri nodes that have a localization keypath
      raw_nodes = doc.xpath("//userDefinedRuntimeAttribute[@keyPath='#{LOCALIZATION_ENABLED_KEYPATH}']")

      # Map raw nodes info to instances of LocalizedNode
      user_defined_nodes = raw_nodes.map do |node|
        parent = node.parent.parent 													# i.e. UILabel, UISwitch, etc.
        vc = parent.xpath("ancestor::viewController")					# the view controller of the element (only available in .storyboard files)
        element_name = parent.name														# i.e. label, switch
        original_id = parent['id'] 														# ugly Xcode ID, e.g. F4z-Kg-ni6
        vc_name = vc.attr('customClass').value rescue nil			# name of custom view controller class

        i18n_enabled = node.parent.xpath("userDefinedRuntimeAttribute[@keyPath='#{LOCALIZATION_ENABLED_KEYPATH}']").attr('value').value == "YES" rescue false
        i18n_comment = node.parent.xpath("userDefinedRuntimeAttribute[@keyPath='#{LOCALIZATION_COMMENT_KEYPATH}']").attr('value').value rescue nil

        LocalizedNode.new(node, original_id, vc_name, element_name, i18n_enabled, i18n_comment)
      end

      # Grab raw nodes that have outlets (i.e. they are dynamically set in code)
      raw_outlet_nodes = doc.xpath("//outlet")

      # Map raw nodes info to instances of LocalizedNode (they will all have i18n_enabled set to false)
      outlet_nodes = raw_outlet_nodes.map do |node|
        original_id = node['destination']
        i18n_enabled = false
        LocalizedNode.new(node, original_id, nil, nil, i18n_enabled, nil)
      end

      user_defined_nodes + outlet_nodes
    end

    #
    # Searches the given path for Interface Builder files (.storyboard & .xib) and returns their paths.
    # @param path The path that should be searched for Interface Builder files.
    # @return [Array<String>] An array of paths to Interface Builder files.
    #
    def self.determine_ib_files!(path)
      raise "The provided file or folder does not exist" unless File.exist? path

      if File.directory?(path)
        files = Dir.glob(path + "/**/*{#{ACCEPTED_FILE_TYPES.join(',')}}")
        raise "The provided folder did not contain any interface files (#{ACCEPTED_FILE_TYPES.join(', ')})" unless files.count > 0
        return files
      else
        raise "The provided file is not an interface file (#{ACCEPTED_FILE_TYPES.join(', ')})" unless ACCEPTED_FILE_TYPES.include? File.extname(path)
        return [path]
      end
    end

  end
end
