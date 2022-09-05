  desc "make a pre-release release candidate push. This lane requires: 1) \"public\" and \"origin\" remote have been configured; 2) developers should have already added release notes in README.md"
  desc "and modified version number strings in various files; 3) there is already a release/x.y.z branch existing."
  desc "than run command like"
  desc " fastlane pre_release "

  lane :pre_release do |options|
    check_env_var(["GITHUB_API_TOKEN", "RELEASE_USER"])
    internal_repo="AylaNetworks/common_sepia"
    public_repo="#{internal_repo}_Public"
    release_number = get_version_string
    check_required_argument(release_number, "release_number:x.y.z")

    # make sure it is a pre_release version with rc string in it
    unless release_number =~ /.*?rc.*/
      puts "Your release number has no release candidate (rc) string in it"
      exit!
    end

    # confirm right version to pre_release
    puts "Your release version is: " + release_number + ", is this correct(y/n)?"
    answer = $stdin.getch
    exit! unless answer.eql?("y")
    v="v"+release_number

    git_command(full_command: "git config user.email " + ENV["RELEASE_USER"])

    # push a pre-release branch
    git_command(full_command: "git checkout release/#{release_number}")
    # origin must have this pre-release branch already
    git_command(full_command: "git pull")
    ensure_git_branch(branch: "release/#{release_number}")
    ensure_git_status_clean
    git_command(full_command: "git push public release/#{release_number}")

    # create and push tags here.
    git_command(full_command: "git tag -a #{v} -m \"#{v} tag\"");
    git_command(full_command: "git push origin #{v}");
    git_command(full_command: "git push public #{v}");

    puts "Congratulations! Pre-release Code push completed successfully."
  end
