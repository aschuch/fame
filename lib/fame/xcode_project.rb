require 'pbxplorer'   # grab localization languages from .xcproj file

module Fame
  # Handles the Xcode Project that is subject to localization
  class XcodeProject
    # All accepted Xcode project file types
    ACCEPTED_FILE_TYPES = [".xcodeproj"].freeze

    attr_accessor :xcode_proj_path

    #
    # Initializer
    # @param xcode_proj_path A path to a .xcodeproj file whose contents should be localized.
    #
    def initialize(xcode_proj_path)
      @xcode_proj_path = xcode_proj_path
      validate_xcodeproj_path!
    end

    #
    # Determines all languages that are used in the current Xcode project.
    # @return [Array<String>] An array of language codes, representing all languages used in the current Xcode project.
    #
    def all_languages
      project_file = XCProjectFile.new(@xcode_proj_path)
      project_file.project["knownRegions"].select { |r| r != "Base" }
    end

    # TODO
    # def self.determine_xcproj_files!(path = ".")
    # 	raise "The provided file or folder does not exist" unless File.exist? path
    # end

    private

    #
    # Validates the xcodeproj path
    #
    def validate_xcodeproj_path!
      raise "[XcodeProject] The provided file does not exist" unless File.exist? @xcode_proj_path
      raise "[XcodeProject] The provided file is not a valid Xcode project (#{ACCEPTED_FILE_TYPES.join(', ')})" unless ACCEPTED_FILE_TYPES.include? File.extname(@xcode_proj_path)
    end

  end
end
