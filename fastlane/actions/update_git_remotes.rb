module Fastlane
  module Actions
    class UpdateGitRemotesAction < Action
      def self.run(params)
      	remote_name = params[:remote] || ""
      	UI.message "Refreshing git remote(s)"
        Actions.sh("git remote update #{remote_name}")
      end

      def self.description
        "Refreshes git remote(s) by calling 'git remote update <remote_name>'. 'remote_name' is optional."
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :remote,
                                       description: "Optional. A specific remote name to refresh",
                                       is_string: true,
                                       optional: true,
                                       ),
        ]
      end

      def self.authors
        ["AylaMobileRelease"]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
