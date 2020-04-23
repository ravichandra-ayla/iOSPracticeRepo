# Functions and Lanes common to all Ayla projects.
#
# Code originally Pulled from SepiaApp 6.2.00
#
# File should only be used as an import within Fastlane-related functions.  
# Depends on fastlane functionality.
#
# Functions here can be overridden by those found in app_core.
# In turn, these may be overridden by functions in the Fastfile itself.

# Pulled from SepiaApp 6.2.00
UI.important "Importing Ayla Core fastlane functions and lanes..."

ayla="Ayla"
ENV['ayla'] = "Ayla"
ENV['IS_FASTLANE']="true"

# Intended for use with platform-less projects such as common_sepia
add_extra_platforms(
  platforms: [:independent]
)

def check_env_var(var_arr)
    if var_arr.nil? or var_arr.empty?
        UI.error "Cannot check environment variables if none are provided."
        exit!
    end
    var_arr.each { |v|
        if !ENV.has_key?(v) or ENV[v].empty?
            UI.error "The environment variable #{v} needs to be set before running this command."
            if is_ci?
            	new_val = UI.input("Enter a value for variable \"#{v}\"?  > ")
				if name.nil? or name.empty?
					UI.error "Cannot continue without value."
					exit!
				else
					ENV[v] = new_val
				end
            else
            	exit!
            end
        end
    }
end

def check_required_argument(arg, arg_string_format)
    if arg.nil? or arg.empty?
        UI.error "This action requires the argument #{arg_string_format} which was not included."
        exit!
    end
end

def shell_cmd_succeeds(cmd_str)
	UI.message("Running command: '#{cmd_str}'") 
	output = `#{cmd_str}`
	output = output.chomp
	if $? != 0
		UI.error("#{output}")
		UI.error("Command failed! #{$?}")
		return false
	else
		UI.message("#{output}")
		UI.success("Success")
		return true
	end
end
  
def current_xcode_version
	vXcode = `xcodebuild -version | grep Xcode | cut -d' ' -f 2`
	return vXcode
end

def current_cocoapods_version
	vCocoapods = `pod --version`
	return vCocoapods
end

def update_branch_specifier
    UI.message "No branch specifiers defined for this project."
end

def test_string
	UI.message "test_string from the ayla_core.rb file"
end

def before_all_project(lane, options)
	UI.message "No extra before_all specifications."
end


platform :ios do
	# Use override_lane declarations as required for customization. 
	#   (Note, 'override' is, in that case, a misnomer.  There is no access to super.)
	
  	desc "Runs any tests present in project" 
  	lane :run_all_tests do
    	UI.important "No tests defined for this particular project"
  	end
  	
	desc "Display the current version number as returned from get_version_string function."
	lane :get_version do
       release_number = get_version_string
       UI.success "Current release version is: " + release_number
    end

	desc "Alias to 'get_version' for compatibility"
    lane :show_version do
       get_version
    end

	desc "Set the version number for the project using provided option \"version:x.y.z\"."
	lane :set_version do |options|
		check_required_argument(options[:version], "version:x.y.z")
		set_version_string(options[:version])
	end

	desc "Automatically set the version numbers of tools in the README.md file"
  	lane :set_build_tool_version do
    	set_build_tool_version
	end

	desc "For internal fastfile testing."
  	lane :fasttest_core do
		UI.message("fasttest_core (ios): Ayla Core")
	end
	
	desc "For internal fastfile testing."
	lane :fasttest_base do
		UI.message("fasttest_base (ios): Ayla Core")
	end
end

UI.success "Ayla Core import complete."

# Code Release lanes are defined in required code_release_core.rb
#
import "code_release_core.rb"
