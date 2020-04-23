# code_release_core.rb
#
# Functions and loanes for code release and Github repo manipulation
#
UI.message "Importing Code Release Core."

REPO_NAME_VAR='REPO_NAME'
TAG_VAR_NAME = "GIT_TAG_NAME"
	
def internal_repo_for_ayla_project(repo_name)
	if repo_name.nil? or repo_name.empty?
		#UI.message "Using Repo name from"
		repo_name = ENV[REPO_NAME_VAR]
	end
	if repo_name.nil? or repo_name.empty?
		UI.error "Cannot check environment variables if none are provided."
		exit!
	end
	return "AylaNetworks/#{repo_name}"
end

def public_repo_for_ayla_project(repo_name)
	int_repo = internal_repo_for_ayla_project(repo_name)
	public_repo = "#{int_repo}_Public"
	return public_repo
end

def full_github_repo_url(org_and_repo)
	# Requires Organization be included (see internal_repo_for_ayla_project output)
	url = "https://github.com/#{org_and_repo}"
	return url
end

def verify_release_number(release_number)
	check_required_argument(release_number, "release_number:x.y.z")
	if !is_ci?
		puts "Your release version is: #{release_number}, is this correct? (y/n)"
		answer = $stdin.getch
		exit! unless answer.eql?("y")
	else
		UI.important "Using Release Number: #{release_number}"
	end
end

def verify_tag_name(rel_tag_name)
	check_required_argument(rel_tag_name, "rel_tag_name:<name of final release tag>")
	if !is_ci?
		UI.message "Final Tag:#{rel_tag_name}. Does this look correct? (y/n)"
		answer = $stdin.getch
		exit! unless answer.eql?("y")
	else
		UI.important "Using Tag '#{rel_tag_name}'."
	end
end

def set_git_user(email)
	check_env_var(["RELEASE_USER"])
	git_command(full_command: "git config user.email " + ENV["RELEASE_USER"])
end

def ensure_repo_has_public_remote(repo_name)
	UI.header "Verifying Repo Settings"
	check_required_argument(repo_name, "repo_name:repo_name")

	pub_remote_name = "public"
	UI.important "Ensuring #{repo_name} repo has #{pub_remote_name} remote."

	pub = `git remote -v | grep #{pub_remote_name}`
	if pub.nil? or pub.empty?
		repo_name = ENV[REPO_NAME_VAR]
		UI.message "Using Repo name \"#{repo_name}\" from environment/Appfile"
	else
		UI.message "Using Repo name \"#{repo_name}\"."
	end
	
	origin_url = `git remote get-url origin`
	public_url = `git remote get-url #{pub_remote_name} 2>/dev/null`
	if pub.nil? or pub.empty?
		pub_repo = public_repo_for_ayla_project(repo_name)
		pub_url = full_github_repo_url(pub_repo)
		
		git_command(full_command: "git remote add #{pub_remote_name} #{pub_url}")
		
		verify = `git remote get-url #{pub_remote_name} 2>/dev/null`
		if verify.nil? or verify.empty?
			UI.error "Failed to add '#{pub_remote_name}' repo."
			exit!
		else
			UI.success "Added '#{pub_remote_name}' remote URL \"#{pub_url}\" to local repo."
		end
	else
		UI.success "Repo has a '#{pub_remote_name}' remote configured. URL is \"#{pub_url}\"."
	end
end

def push_branch_to_public(branch_name, force=false)
	check_env_var(["GITHUB_API_TOKEN"])
	check_required_argument(branch_name, "branch_name:branch_name")
	UI.important "Pushing branch '#{branch_name}' to public"
	
    git_command(full_command: "git checkout --track origin/#{branch_name} || git checkout #{branch_name}")
    git_command(full_command: "git branch --set-upstream-to=origin/#{branch_name} #{branch_name} && git pull")
	ensure_git_branch(branch: branch_name)
	ensure_git_status_clean
	if !force
		git_command(full_command: "git push public #{branch_name}")
	else
	    if !is_ci?
			puts "Continue with force push of '#{branch_name}' to public? (y/n)"
			answer = $stdin.getch
			exit! unless answer.eql?("y")
		end
		UI.important "Force push."
		git_command(full_command: "git push -f public #{branch_name}")
	end
end

def default_github_release_name(tag_name)
	return "#{tag_name} Release"
end

def default_github_release_description(tag_name)
	return "See README.md file for details"
end

def get_provisional_tag_name(release_number)
	check_required_argument(release_number, "release_number:x.y.z")
	tag_name = "release-#{release_number}"
	return tag_name
end

def get_final_release_tag_name(release_number)
	check_required_argument(release_number, "release_number:x.y.z")
	tag_name = "v#{release_number}"
	return tag_name
end

def get_release_branch_name(release_number)
	check_required_argument(release_number, "release_number:x.y.z")
	branch_name = "release/#{release_number}"
	return branch_name
end

def version_from_provisional_tag(tag_name)
	version = nil
	trigger_tag = tag_name || ENV[TAG_VAR_NAME] || nil
	if trigger_tag.nil? or trigger_tag.empty?
		UI.important "Provisional tag value not found. ($#{TAG_VAR_NAME} not set?)"
	else
		version = `echo #{trigger_tag} | grep -Eo \"[.0-9]+\"`
		version = version.chomp
	end
	return version
end

def update_git_remote(remote_name)
	UI.message "Refreshing git remote(s)"
	git_command(full_command: "git remote update #{remote_name}")
end

def bump_version_and_commit_to_develop(version)
	branch_name = "develop"
	check_required_argument(version, "version:x.y.z")
	
	UI.header "Bumping version number to #{version} and committing change to '#{branch_name}' branch"

	# Checkout fresh copy of 'develop' or other branch as needed
	UI.message "Preparing repo for version bump."
	update_git_remote("")
	
	git_pull
	git_command(full_command: "git checkout #{branch_name}")
	git_pull
	ensure_git_branch(branch: branch_name)
	ensure_git_status_clean
	
	# Set the version number as required.
	set_version(version: version)
	
	# Display changes made, ask for verification if possible
	sh("git status")
	if is_ci?
		UI.message "Skipping manual verification of changes."
	else
		UI.confirm "Please verify the updated files."
	end
	
	UI.important "Committing updates."
    git_command(full_command: "git add .")
    git_command(full_command: "git commit -m 'Updated version to #{version}'")
    
    UI.important "Pushing commit to #{branch_name}"
    git_command(full_command: "git push origin #{branch_name}")
	ensure_git_status_clean
end

def create_new_release_branch(release_branch_name, tag_name)
	# Cribbed from Android 'create_release_branch_from_tag' lane
	check_required_argument(release_branch_name, "release_branch_name:release/xx.yy.zz")
	check_required_argument(tag_name, "tag_name:vx.y.z")
	git_command(full_command: "git fetch origin") 

	output = `git rev-parse --quiet --verify origin/#{release_branch_name}`
	
	rc = $?
	output = output.chomp
	if rc != 0
		UI.important "Creating release branch"
	   	git_command(full_command: "git checkout -b #{release_branch_name} #{tag_name}") 
    	git_command(full_command: "git push origin #{release_branch_name}")
    else
		UI.important "Release branch #{release_branch_name} already exists."
		git_command(full_command: "git checkout #{release_branch_name}")
		if !is_ci?
			if UI.confirm("Use this branch?")
			  	UI.success "Continuing."
			else
			  	UI.error "Exiting."
			  	exit!
			end
		else
			UI.error "Cannot continue with automated push at this time given the branch exists."
			exit!
		end
    end
end

def git_branches_identical(branch1, branch2)
	# Lifted from Util/Fastfile "are_two_branches_same"
	UI.important "Checking diff of branches '#{branch1}' and '#{branch2}'." 

	branches_same = false

	output = `git diff ${branch1} ${branch2}`
	output = output.chomp 

	if output.nil? or output.empty?
		UI.success "'#{branch1}' and '#{branch2}' are identical." 
		branches_same = true
	else
		UI.important "Branches '#{branch1}' and '#{branch2}' are not identical." 
		UI.message "Output of git diff between them:"
		UI.message "#{output}"
		branches_same = false
	end
	return branches_same
end

def force_merge_release_branch_to_master(release_branch_name)
	master = "master"
	check_required_argument(release_branch_name, "release_branch_name:release/xx.yy.zz")
    update_git_remote("")
    
	# Original lifted from Util/Fastfile
    # follow the instructions here 
    # https://stackoverflow.com/questions/16862933/
    #how-to-resolve-gits-not-something-we-can-merge-error  
	UI.important "Prepping for force merge..."
    git_command(full_command: "git fetch origin")
    git_command(full_command: "git checkout #{release_branch_name}")
	ensure_git_branch(branch: "#{release_branch_name}")
	ensure_git_status_clean
    git_command(full_command: "git fetch origin #{master}")

    git_command(full_command: "git checkout --track origin/#{master} || git checkout #{master}")
    git_command(full_command: "git pull")
        
    success = false
	UI.header "Merging"
	if !is_ci?
		puts "Are you sure you want to proceed with a this merge?(y/n)"
		answer = $stdin.getch
		return false unless answer.eql?("y")
	end
	if shell_cmd_succeeds("git merge -m \"Merge #{release_branch_name} to #{master}\" --no-edit #{release_branch_name}")
		UI.success "Branch '#{release_branch_name}' successfully merged to master"
		success = true
	else
		UI.error "Force Merge has Failed!"
		UI.error "Manual intervention may be required!"
		success = false
		exit!
	end
	if success
		UI.important "Pushing master to origin"
		# Force overwrite with release branch contents
		# Dangerous
		#
		git_command(full_command: "git push origin master")
    end
    return success

end

def merge_release_branch_to_master(release_branch_name)
	master = "master"
	check_required_argument(release_branch_name, "release_branch_name:release/xx.yy.zz")
    update_git_remote("")
    
	# Original lifted from Util/Fastfile
    # follow the instructions here 
    # https://stackoverflow.com/questions/16862933/
    #how-to-resolve-gits-not-something-we-can-merge-error  

    git_command(full_command: "git fetch origin")
    git_command(full_command: "git checkout #{release_branch_name}")
	ensure_git_branch(branch: "#{release_branch_name}")
	ensure_git_status_clean
    git_command(full_command: "git fetch origin #{master}")

    git_command(full_command: "git checkout --track origin/#{master} || git checkout #{master}")
    git_command(full_command: "git pull")

    success = false
    
    x = `git merge-base --is-ancestor #{master} #{release_branch_name}`
    if $? == 0
    	UI.important "FF Merge is possible from #{release_branch_name} onto #{master}"
		if shell_cmd_succeeds("git merge --ff-only #{release_branch_name}")
			UI.success "Branch '#{release_branch_name}' successfully FF merged to master"
			success = true
		else
			UI.error "FF Merge Failed. Will not proceed with automated merge/push."
			success = false
			exit!
		end
    end

	if success
		UI.important "Pushing master to origin"
		# Force overwrite with release branch contents
		# Dangerous
		#
		git_command(full_command: "git push origin master")
    end
    return success
end 

def delete_tag_and_sync(tag_name)
	UI.important "Removing any tag named '#{tag_name}' and syncing."
	check_required_argument(tag_name, "tag_name:tag_name")
	
	git_pull
	
	if git_tag_exists(tag: "#{tag_name}")
		UI.important "Deleting tag '#{tag_name}' from local copy"
		git_command(full_command: "git tag -d #{tag_name}")
	else
		UI.important "Tag '#{tag_name}' not found on local copy of repo."
	end
	
	remote_name = "origin"
	if git_tag_exists(tag: "#{tag_name}", remote: true, remote_name: remote_name)
		UI.message "Pushing tag deletion to #{remote_name} repo"
		git_command(full_command: "git push #{remote_name} :refs/tags/#{tag_name}")
	else
		UI.important "Tag '#{tag_name}' does not exist on '#{remote_name}' local copy of repo."
	end
	
	remote_name = "public"
	if git_tag_exists(tag: "#{tag_name}", remote: true, remote_name: remote_name)
		UI.message "Pushing tag deletion to #{remote_name} repo"
		git_command(full_command: "git push #{remote_name} :refs/tags/#{tag_name}")
	else
		UI.important "Tag '#{tag_name}' does not exist on '#{remote_name}' local copy of repo."
	end

end

desc "Make sure the repo has the \"public\" remote url set correctly. Set it, if not."
lane :ensure_repo_has_public_remote do |options|
	check_env_var(["REPO_NAME"])
	repo_name = ENV['REPO_NAME']
	ensure_repo_has_public_remote(repo_name)
end

desc "Draft, tag, and publish an existing release branch."
desc "This lane requires that:"
desc " - The \"public\" and \"origin\" remotes be configured for the local copy"
desc " - Release notes have already been added to the README.md"
desc " - Version number strings have been bumped (use the 'set_version' lane."
desc " - A 'release/x.y.z' branch already exists on the remote repo. (Developers should  create and merge a PR from release branch to master.) The release engineer will merge that request, then run the `fastlane release` command"
lane :release do |options|
	UI.header "CLASSIC Code Release"
	check_env_var(["GITHUB_API_TOKEN", "RELEASE_USER", "REPO_NAME"])
	
	repo_name = ENV['REPO_NAME']
	
	internal_repo = internal_repo_for_ayla_project(repo_name)
	public_repo = public_repo_for_ayla_project(repo_name)
	
	release_number = options[:version] || get_version_string
	
	verify_release_number(release_number)
	
	release_branch_name = "release/#{release_number}"
	UI.important "Release branch name: '#{release_branch_name}'"

	# This value is the new release's git tag
	rel_tag_name = get_final_release_tag_name(release_number)

	verify_tag_name(rel_tag_name)

	# Set local Git credentials
	set_git_user(ENV["RELEASE_USER"])

	# Check remote
	ensure_repo_has_public_remote(repo_name)


	# Now push the updated 'master' branch from the internal repo to 'public'.
	push_master_branch_to_public
	
	
	# Automatic publishing may need to be disabled for some time as it immediately triggers release emails.
	# Publish a release (this will create the corresponding tag on the public repo.
	tag_and_release(tag_name: rel_tag_name,
					public_repo: public_repo)
	
	# When the above auto-publish is not used, create and push tags here.
	#    Should be disabled when auto-publishing
	#tag_only(tag_name:rel_tag_name)

	
	# Remove the release trigger tag 'release-x.x.x'
	remove_provisional_release_tag(release_number: release_number)

	# Push the release branch
	push_release_branch_to_public(release_branch_name: release_branch_name)

	# Push updates to the 'incoming' branch
	update_incoming_branch

	# Finally create a PR to merge 'master' back to 'develop' and notify the tech lead
	create_mergeback_pr(tag_name: rel_tag_name,
						internal_repo: internal_repo)

	# If the auto-publish step above fails, log into Github's web interface with the release user, and 'draft' the release manually once/if everything appears correct.
	# send release notification email
	UI.success "Congratulations! Code push completed successfully."
	UI.important "Make sure to verify the release on Github, and publish manually if necessary."
end

lane :get_version_from_tag do |options|
	version_from_provisional_tag(options[:tag_name])
end

desc "Draft, tag, and publish an release branch and Github release."
lane :release_new do |options|
	UI.header "Automated Code Release"
	check_env_var(["GITHUB_API_TOKEN", "RELEASE_USER", "REPO_NAME"])
	
	repo_name = ENV['REPO_NAME']
	
	internal_repo = internal_repo_for_ayla_project(repo_name)
	public_repo = public_repo_for_ayla_project(repo_name)
	
	update_git_remote("")
	
	release_number = options[:version] || version_from_provisional_tag
		
	# Set local Git credentials
	set_git_user(ENV["RELEASE_USER"])
	
	if is_ci?
		UI.important "CI Automated release requires manually specified version number for safety"
	end
	check_required_argument(release_number, "version:x.y.z")
	
	verify_release_number(release_number) # Will fail without version in options or ENV

	# Handle version numbers
	UI.message "Verifying version numbers."
	current_version = get_version_string # Pulled from Info.plist or Header
	UI.message "Current version number from project: #{current_version}."
	UI.message "Target version number for release: #{release_number}."

	if current_version != release_number
		UI.important "Versions don't match."
		exit!
		UI.important "Updating version to match."
		bump_version_and_commit_to_develop(version)
	else
		UI.important "Version numbers match (#{current_version})"	
	end

	# Check remotes
	ensure_repo_has_public_remote(repo_name)

	# This value is the new release's git tag
	rel_tag_name = get_final_release_tag_name(release_number)
	verify_tag_name(rel_tag_name)

	# Create release tag (and sync)
	tag_only(tag_name: rel_tag_name)

	# Remove the release trigger tag 'release-x.x.x'
	remove_provisional_release_tag(release_number: release_number)


	#Create new release branch `git checkout -b $REL_BRANCHNAME $REL_TAG`
	UI.important "Crafting new release branch"
	release_branch_name = get_release_branch_name(release_number)
	UI.important "Release branch name: '#{release_branch_name}'"
	create_new_release_branch(release_branch_name, rel_tag_name)

	# Merges if ff-only. FAILS if anything more complex required
	
	if merge_release_branch_to_master("#{release_branch_name}")
		UI.success "FF-Only Merge Successful!"
		if git_branches_identical("#{release_branch_name}", "master")
			UI.message "Branches '#{release_branch_name}' and 'master' are now the same."
		else
			UI.important "Branches '#{release_branch_name}' and 'master' are not apparently the same. They should be post-merge"
		end
	else
		UI.error "FF-only Merge failed."
		if options[:force_merge] or !is_ci?
			if !is_ci? 
				if UI.confirm("Attempt a force merge?")
					UI.header "Retrying with a Force Merge"
					if force_merge_release_branch_to_master("#{release_branch_name}")
						UI.success "Merge successful"
						if git_branches_identical("#{release_branch_name}", "master")
							UI.message "Branches '#{release_branch_name}' and 'master' are now the same."
						end
					else
						UI.error "Failure!"
						exit!
					end
				else
					UI.error "Exiting."
					exit!
				end
			else
				UI.header "Retrying with a recursive merge"
				if force_merge_release_branch_to_master("#{release_branch_name}")
					UI.success "Merge successful"
					if git_branches_identical("#{release_branch_name}", "master")
						UI.message "Branches '#{release_branch_name}' and 'master' are now the same."
					end
				else
					UI.error "Failure!"
					exit!
				end
			end
		else
			UI.important "Not attempting a force merge. Exiting."
			exit!
		end
	end
	
	# Will only reach this point after a successful FF-Only merge.
	
	# Now push the updated 'master' branch from the internal repo to 'public'.
	push_master_branch_to_public
	
	
	# Automatic publishing may need to be disabled for some time as it immediately triggers release emails.
	# Publish a release (this will create the corresponding tag on the public repo.
	tag_and_release(tag_name: rel_tag_name,
					public_repo: public_repo)


	# Push the release branch
	push_release_branch_to_public(release_branch_name: "#{release_branch_name}")

	# Push updates to the 'incoming' branch
	# update_incoming_branch

	# Finally create a PR to merge 'master' back to 'develop'
	#   Should pass through if no PR is required
	create_mergeback_pr(tag_name: rel_tag_name,
						internal_repo: internal_repo)

	# If the auto-publish step above fails, log into Github's web interface with the release user, and 'draft' the release manually once/if everything appears correct.
	# send release notification email
	UI.success "Congratulations! Code push completed successfully."
	UI.important "Make sure to verify the release on Github, and publish manually if necessary."
end

lane :push_master_branch_to_public do |options|
	UI.important "Push master branch on Github to public"
	force = options[:force] || false
	push_branch_to_public("master")
end

lane :push_release_branch_to_public do |options|
	# 	NOTE: This branch must already exist at the origin repo. This will not create it.
	UI.important "Push release branch on Github to public"
	release_branch_name = options[:release_branch_name]
	check_required_argument(release_branch_name, "release_branch_name:release_branch_name")
	push_branch_to_public("#{release_branch_name}")
end

desc "Crafts a Github release on public, with the correct release tag, and syncs it back to internal repos"
lane :tag_and_release do |options|
	UI.important "Publish, tag (if required), and push a release to Github"
	
	UI.message "Checking required arguments and options."
	check_env_var(["GITHUB_API_TOKEN"])
	tag_name = options[:tag_name]
	check_required_argument(tag_name, "tag_name:tag_name")
	
	origin_remote_name = "origin"
	if git_tag_exists(tag: tag_name, remote: true, remote_name: origin_remote_name)
		UI.message "Found release tag '#{tag_name}' already present"
	else
		UI.important "Tag '#{tag_name}' does not yet exist on '#{remote_name}' repo. Release will create it."
	end
	
	public_repo = options[:public_repo]
	check_required_argument(public_repo, "public_repo:Organization/Project")
	
	name = options[:name] || default_github_release_name(tag_name)
	description = options[:description] || default_github_release_description(tag_name)
	
	UI.message "Crafting new github release on Public."
	set_github_release(
		api_token: ENV["GITHUB_API_TOKEN"], 
		repository_name: public_repo, 
		tag_name: tag_name, 
		name: name,
		description: description
	)
	
	UI.message "Pulling the release tag to the local branch"
	git_command(full_command: "git pull public master --tags")
	
	UI.message "Now pushing the tag to internal repo"
	git_command(full_command: "git push origin #{tag_name}")
end

desc "Used only when not crafting a Github release.  Creates release tag and syncs it to remotes."
lane :tag_only do |options|
	tag_name = options[:tag_name]
	check_required_argument(tag_name, "tag_name:tag_name")
	UI.important "Adding git tag '#{tag_name}' and pushing to origin and public. No release."

	tag_msg = options[:message] || "#{tag_name} Release"
	add_git_tag(
		tag: tag_name,
		message: tag_msg
	)
	push_git_tags(
		tag: tag_name,
		remote: "origin",
	)
	push_git_tags(
		tag: tag_name,
		remote: "public",
	)
	#git_command(full_command: "git tag -a #{tag_name} -m \"#{tag_name} tag\"")
	#git_command(full_command: "git push origin #{tag_name}")
	#git_command(full_command: "git push public #{tag_name}")
end

private_lane :update_incoming_branch do |options|
	repo = options[:repo] || "public"

	UI.important "Pushing updates to the 'incoming' branch"
	git_command(full_command: "git checkout incoming")
	git_command(full_command: "git pull")
	ensure_git_branch(branch: "incoming")
	ensure_git_status_clean
	git_command(full_command: "git push #{repo} incoming")
end

lane :create_mergeback_pr do |options|
	UI.header "Mergeback..."
	tag_name = options[:tag_name]
	internal_repo = options[:internal_repo]
	check_required_argument(tag_name, "tag_name:tag_name")
	check_required_argument(internal_repo, "internal_repo:Organization/Project")
	
	target_branch = 'develop'
	source_branch = 'master'
	
	if git_branches_identical("origin/#{target_branch}","origin/#{source_branch}")
		UI.important "Branches 'origin/#{target_branch}' and 'origin/#{source_branch}' are the same"
		UI.success "No Mergeback Required"
	else
		pr_title = options[:pr_title] || "Merge back to '#{target_branch}' for #{tag_name} related changes"
		UI.header "Creating mergeback PR to #{target_branch}"
	
		check_env_var(["GITHUB_API_TOKEN"])
		git_command(full_command: "git checkout #{source_branch}")
		ensure_git_status_clean
		create_pull_request(
			api_token: ENV["GITHUB_API_TOKEN"],
			title: pr_title, 
			repo: internal_repo, 
			base: target_branch
		 )
	end
end

lane :check_provisional_release_tag do |options|
	release_number = options[:release_number] || get_version_string
	check_required_argument(release_number, "release_number:x.y.z")

	tag_name = get_provisional_tag_name(release_number)
	UI.header "Checking for provisional release tag '#{tag_name}'."

	remote_name = "origin"
	if git_tag_exists(tag: tag_name, remote: true, remote_name: remote_name)
		UI.message "Found provisional tag. #{tag_name}"
	else
		UI.important "Tag '#{tag_name}' does not exist on '#{remote_name}' local copy of repo."
	end
end

lane :update_branch_specifiers do
	update_branch_specifier
end

desc "If present, removes the provisional git tag used to trigger an automated release."
lane :remove_provisional_release_tag do |options|
	release_number = options[:release_number]
	check_required_argument(release_number, "release_number:x.y.z")

	tag_name = get_provisional_tag_name(release_number)
	UI.header "Removing provisional release tag '#{tag_name}'."
	delete_tag_and_sync(tag_name)
end


desc "Remove a git tag from a release."
desc "Used to add new commits to a release after it has already been tagged."
desc "Run the \"release\" lane again after new changes are added to push them."
lane :untag do |options|
	release_number = get_version_string
	check_required_argument(release_number, "release_number:x.y.z")
	
	if !is_ci?
		UI.important "You want to untag version: #{release_number}, is this correct(y/n)?"
		answer = $stdin.getch
		exit! unless answer.eql?("y")
	else
		UI.important "Untagging version #{release_number}."
	end
	
	tag_name = get_final_release_tag_name(release_number)
	UI.important "Removing \"#{tag_name}\""
	delete_tag_and_sync(tag_name)
end


UI.success "Code Release Core import complete."

