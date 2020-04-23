# iOS App Store Core Functionality for Fastlane
#
# File conditionally imported by main Fastfile (indirectly requires project_core, ayla_core)
#
UI.important "Importing App Store & Beta-related Functions and Lanes"


	
def pre_beta_build
	UI.message "No special setup"
end

def post_beta_build
	UI.message "No special teardown"
end

def pre_app_store_build
	UI.message "No special setup"
end
	
def post_app_store_build
	UI.message "No special teardown"
end

def get_live_version_number
	require 'spaceship'
	check_env_var(["APPLE_ID"])
	Spaceship::Tunes.login(ENV["APPLE_ID"])
	bundle_id = CredentialsManager::AppfileConfig.try_fetch_value(:app_identifier)
	app = Spaceship::Tunes::Application.find(bundle_id)
	version = app.edit_version
	latest_app_version = nil
	if version
		latest_app_version = version.raw_data["version"]["value"]
		File.open('itc_edit_app_info.txt', 'w') do |fo|
			fo.puts "#{version}"
		end
		File.open('current_itc_version.txt', 'w') do |fo|
			fo.puts "#{latest_app_version}"
		end
		puts "Latest pending app version: #{latest_app_version}"
	else
		puts "No pending versions found"
		version = app.live_version
		latest_app_version = version.raw_data["version"]["value"]
		
		File.open('itc_live_app_info.txt', 'w') do |fo|
			fo.puts "#{version}"
		end
		File.open('current_itc_version.txt', 'w') do |fo|
			fo.puts "#{latest_app_version}"
		end
		puts "Latest live version: #{latest_app_version}"
		
	end
	
	#this issue faced in AMAP repo, to remove v from version string 
	if latest_app_version.start_with? "v"
        puts "version contains alphabets, removing it"
        latest_app_version = latest_app_version.tr('v', '')
        puts "Latest live version: #{latest_app_version}"
    end

	#puts version
	return "#{latest_app_version}"
end

def version_valid_for_build
	UI.important "Comparing local version number with app store versions."
	live = get_live_version_number
	live_v = Gem::Version.new(live)
	local = get_version_string
	local_v = Gem::Version.new(local)
	valid = true
	if live == local
		UI.important "Same version! #{live}"
	else
		UI.important "Versions are different. Live: #{live}, Local: #{local}"
		if live_v > local_v
			valid = false
			UI.important "Live version #{live} is higher than the local one (#{local}). Will need to set it higher to push a new build."
		else
			UI.important "Local version is #{local}, which is higher than the live version #{live}. Build away."
		end
	end
	return valid
end



def set_build_number_for_testflight
	UI.header "Setting the correct build number for TestFlight"
	last_build = get_build_number.to_i

	# Check build number from any existing TestFlight build (default zero)
	tf_build = latest_testflight_build_number(
				username: ENV["APPLE_ID"],
				version: get_version_string,
				initial_build_number:0
		   )
		   
	# Set next build number accordingly
	if tf_build == 0
		UI.important "App does not yet have a build for this version uploaded. This is the first build."
	end
	next_build = tf_build + 1

	UI.message "Last build (from project file): #{last_build}"
	UI.message "Setting build number for TF to #{next_build}"
	increment_build_number(build_number:next_build)
	UI.success "Build Number set to #{next_build}"
end



platform :ios do
  
  	desc "Run basic verifications on app before submitting a build."
	lane :preflight_checks do
		check_env_var(["APPLE_ID"])
		precheck(
			username: ENV["APPLE_ID"],
			default_rule_level: :warning,
		)
	end
	
	lane :get_app_store_version do
		# https://github.com/fastlane/fastlane/issues/11716
		live = get_live_version_number
	end
	
	desc "Increment to a specified build number provided as an option \"build_number:xx\""
    lane :increment_build do |options|
    	check_required_argument(options[:build_number], "build_number:xx")
	    increment_build_number(options[:build_number])
	end

	desc "Display the currently set build number"
	lane :current_build do
	    check_env_var(["APPLE_ID"])
	    num = latest_testflight_build_number(
				  username: ENV["APPLE_ID"],
				  version: get_version_string,
				  initial_build_number: 0
			   )
	    UI.important "Current build: #{num}"
	end

	private_lane :build_and_archive do |options|
		UI.header "Building the app, and saving an archive"
		check_env_var(["BUILD_SCHEME"])
		gym(
			scheme: ENV['BUILD_SCHEME'], 
			export_method: "app-store", 
			export_xcargs: "-allowProvisioningUpdates"
		) 
	end
	
	private_lane :upload_archive_to_testflight do |options|
		UI.header "Uploading archive to TestFlight"
		check_env_var(["APPLE_ID", "TEAM_ID"])
		pilot(
			username: ENV["APPLE_ID"],
			team_id: ENV["TEAM_ID"],
			skip_waiting_for_build_processing:true
		)
	end
	
	private_lane :upload_archive_to_app_store do |options|
		UI.header "Uploading archive to iOS App Store"
		check_env_var(["APPLE_ID"])

		deliver(
			force: true, 
			username: ENV["APPLE_ID"],
			precheck_default_rule_level: :error
		)
	end

	desc "Run any setup scripts or dependency install routines (such as cocoapods)"
	lane :setup_install_dependencies do |options|
		UI.header "Installing dependencies (cocoapods)"
		cocoapods
	end
	
	lane :build_version_check do
		if version_valid_for_build
			UI.success "Looks good."
		else
			UI.error "Check versions!"
		end
	end
	
	desc "Submit a new beta build to TestFlight"
	lane :beta_old do |options|
		UI.header "Building for TestFlight"
		check_env_var(["APPLE_ID", "TEAM_ID", "BUILD_SCHEME"])
		UI.important("Building and submitting a new beta build to TestFlight")
		pre_beta_build
		setup_install_dependencies
		set_build_number_for_testflight

		build_and_archive
		upload_archive_to_testflight
		post_beta_build
	end
	
	
	desc "Submit a new beta build to TestFlight"
	lane :beta do |options|
		UI.header "Building for TestFlight"
				
		check_env_var(["APPLE_ID", "TEAM_ID", "BUILD_SCHEME"])
		UI.important("Building and submitting a new beta build to TestFlight")
		
		build_version_number = options[:version] || get_version_string
		UI.important "Building as version #{build_version_number}"

		if build_version_number == get_version_string
				UI.important "Supplied version is the same as the existing one"
		end

		if options[:version]
			UI.message "Version #{options[:version]} supplied. Setting version..."
			set_version_string(options[:version])
		else	
			UI.message "Will attempt a build of existing version number. Specify version (version:x.y.z) to override."
		end
		
		if version_valid_for_build
			UI.success "Versions look okay. Proceeding"
			
			pre_beta_build
			setup_install_dependencies
			set_build_number_for_testflight

			build_and_archive
            		changelog_from_git_commits
			upload_archive_to_testflight
			post_beta_build
		else
			UI.error "Check version numbers supplied!"
			exit!
		end
	end
	
    desc "Deploy a new version directly to the App Store"
    lane :applestore do |options|
		UI.header "Building for iOS App Store Release"
		check_env_var(["APPLE_ID", "TEAM_ID", "BUILD_SCHEME"])
		pre_app_store_build
		
		cocoapods
	
		set_build_number_for_testflight
		build_and_archive
		
		upload_archive_to_app_store
		post_app_store_build
    end
end

UI.success "App Store Core import complete."
