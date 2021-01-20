# Functions and Lanes specific to the application/project (Aura)
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

# Gets whatever is currently defined in the Info.plist file. 
#    Assumes, unguarded, that get_version_file provides a plist file
def get_version_string
    buildScheme = ENV["BUILD_SCHEME"]
    appVersionNumber = get_version_number(target: buildScheme)
    puts "appVersionNumber = #{appVersionNumber}"
    return appVersionNumber
end

# Sets the value in the Info.plist file to the provided new version number
def set_version_string(version)
    
    create_prerelease_branch(version)
    
    vFile = get_version_file
    [vFile].each do |f|
    	UI.message "Updating version value in file #{vFile}"
        file_contents = File.read(f)
        file_contents.gsub!(/(.*<key>CFBundleShortVersionString<\/key>\n.*<string>)(.*)(<\/string>.*)/, "\\1#{version}\\3")
        File.write(f, file_contents)
    end
    commit_prerelease_changes(version)
    #create_prerelease_pr(version)
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

# This updates the version specifier string in the Podfile to a new 'default' branchname
def update_branch_specifier(branch_name)
    script_contents = File.read(ENV['BUILD_SCRIPT_F'])
    # do replacement in this line: conditional_assign("ayla_sdk_branch", "") #or @ayla_build_branch)
    script_contents.gsub!(/(.*)(release\/[\d]*\.[\d]*\.[\d]*)(.*)/, "\\1#{branch_name}\\3")
    File.write(BUILD_SCRIPT_F, script_contents)
end

# Called at the beginning and end of the respective build lanes
def pre_beta_build
	set_include_wechat
end

def post_beta_build
	unset_include_wechat
end

def pre_app_store_build
	set_include_wechat
end
	
def post_app_store_build
	unset_include_wechat
end


platform :ios do
  	
    private_lane :set_include_wechat do
  	    #ENV["INCLUDE_WECHAT_OAUTH"]="yes"
            inludeWeChat = ENV["INCLUDE_WECHAT_OAUTH"]
  	    UI.important "WeChat OAuth is included = #{inludeWeChat} if need to include use INCLUDE_WECHAT_OAUTH='yes' env to set"
    end
  
    private_lane :unset_include_wechat do
  	    ENV["INCLUDE_WECHAT_OAUTH"]=""
        UI.important "Unsetting inclusion of WeChat OAuth"
    end

end
