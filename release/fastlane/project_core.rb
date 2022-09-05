# Functions and Lanes specific to the application/project
#
#
# File should only be used as an import within Fastlane-related functions.  
# Depends on ayla_core.rb and fastlane functionality.
#
# Functions here can override those found in ayla_core.
#   In turn, these may be overridden by functions in the Fastfile itself.

# Because this file should only be 'include'd by a Fastfile, it can contain direct 
#   references to fastlane actions and objects. Those references resolve when 
#   used correctly.
UI.important "Importing Project-specific Functions and Lanes for #{ENV['REPO_NAME']}"
default_platform(:ios)

# Note: Many of the required environment variables are defined in the Appfile.

# App Store/TestFlight lanes are defined in optional app_store_core.rb
unless !ENV.has_key?("HAS_APPLICATION") or ENV["HAS_APPLICATION"].empty?
	UI.important "Importing iOS App Store Functions and Lane"
	import "app_store_core.rb"
end

def test_string
	puts "test_string from the project core file"
	puts "test_string: #{ENV['ayla']} #{ENV['app_name']}"

end

# Finds the header file (where version number values are stored)
def get_version_file
    file_name = `find #{ENV['SOURCE_DIR']} -name #{ENV['VERSION_FILE']}`
    if file_name.nil? or file_name.empty?
        puts "Can not find version file by command #{file_name}. Please double check path and file name"
        exit!
    else
        file_name=file_name.chomp
    end
end

# Gets whatever is currently defined in the source header file. 
#    Assumes, unguarded, that get_version_file provides a plist file
def get_version_string
    vFile=get_version_file
    version_sentence = `cat #{vFile} | grep "AYLA_SDK_VERSION "`
    version_string = version_sentence.gsub!(/.*"(.*)".*/, "\\1")
    version_string.chomp
end

# Sets the value in the source files and Podspec to the provided new version number
def set_version_string(version)
    #create prerelease branch to push version changes
    create_prerelease_branch(version)

	# Handles main version declaration in header file.
    vFile = get_version_file
    file_contents = File.read(vFile)
    file_contents.gsub!(/(.*AYLA_SDK_VERSION @)"(.*)"(.*)/, "\\1\"#{version}\"\\3")
    File.write(vFile, file_contents)

    # Handles Podspec file
    p_contents = File.read(ENV['PODSPEC_FILE'])
    p_contents.gsub!(/(.*s.version      = )"(.*)"(.*)/, "\\1\"#{version}\"\\3")
    File.write(ENV['PODSPEC_FILE'], p_contents)
    
    #commit version changes into pre-release branch
    commit_prerelease_changes(version)
end

# Updates the version numbers for CocoaPods and Xcode called out in the README file
def set_build_tool_version
    vXcode = current_xcode_version
    vCocoapods = current_cocoapods_version
    readmeFile = "../README.md"

    puts "Current Xcode: #{vXcode.chomp}"
    puts "CocoaPods: #{vCocoapods}"
    puts "Updating strings in README file."
    
    file_contents = File.read(readmeFile)
    file_contents.gsub!(/(.*- \[Xcode )(.*[\s])(\]\(.*)/, "\\1#{vXcode}\\3")
    file_contents.gsub!(/(.*- \[CocoaPods.*\) )(.*[\s])(\]\(.*)/, "\\1#{vCocoapods}\\3")
    File.write(readmeFile, file_contents)
end

# After a release is complete, this would bump the internal release version to the next patch version
def post_release_version
    cur_release = get_version_string

    # increment version number
    vStrings = cur_release.split('.')
    minor = vStrings[1].to_i
    minor += 1
    cur_release.gsub!(/([\d]*\.)([\d]*\.)([\d]*)(.*)/, "\\1#{minor.to_s}.00\\4")

    # add "-rc1" to construct a new version string
    cur_release + "-rc1"
end

# Uncomment as required for custom data
#def default_github_release_name(tag_name)
#	return "#{tag_name} Release"
#end

#def default_github_release_description(tag_name)
#	return "See README.md file for details"
#end

def before_all_project(lane, options)
	UI.message "Override of before_all function by project_core"
end
	

platform :ios do
	
  	desc "Runs any tests"
  	lane :test do
    	scan
  	end
end
