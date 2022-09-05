#!/bin/sh
# Note: this script needs to run under release/ folder.
# then go back to parent folder of release/ to do release commands

START_DIR="$PWD"

realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
if [[ "$SCRIPT_DIR" == "." ]]; then
	SCRIPT_DIR="$START_DIR"
else 
	SCRIPT_DIR="$(realpath $SCRIPT_DIR)"
fi
PROJECT_DIR=$(dirname "$SCRIPT_DIR")

DEST_DIR="$PROJECT_DIR/fastlane"
SOURCE_DIR="$SCRIPT_DIR/fastlane"


echo "SCRIPT_DIR=$SCRIPT_DIR"
echo "PROJECT_DIR=$PROJECT_DIR"
echo "DEST_DIR=$DEST_DIR"
echo "SOURCE_DIR=$SOURCE_DIR"

check_fastlane_install(){
	if command -v fastlane; then
		echo "You have fastlane installed".
	else
		echo "Please install fastlane first, or check your PATH and GEM_PATH variables." 1>&2
		gem env
		echo "PATH=$PATH"
		return 1;
	fi
}

verify_workspace(){
	if [[ "$WORKSPACE" == "$PROJECT_DIR" ]]; then
		echo "CI system, and/or  abnormal directory structure detected. Be careful with relative paths." 1>&2
	fi
}


copy_files(){
	local SRC_DIR="$1"
	local DEST_DIR="$2"
	
	echo "Copying required files into place..."
	sources=( $(find "$SRC_DIR" -print0 | xargs -0) )
	f_count=${#sources[@]}
	err=0
	if [[ $f_count -gt 0 ]];then
		for src_file in "${sources[@]}"; do
			if [[ "$src_file" == "$SRC_DIR" ]];then
				echo "Skipping dir."
			elif ! cp -R "$src_file" "$DEST_DIR"; then
				echo "error: Failed to copy file \"$src_file\"."
				err=1
			fi
		done
	else
		echo "error: No files found in \"$MRS_SUB_DIR\"."
		err=1
	fi
	return $err
}


get_mobile_release_scripts(){
	cd "$DEST_DIR"
	MRS_DIR="$DEST_DIR/mobile_release_scripts"
	MRS_SUBDIR="$MRS_DIR/iOS"
	rel_repo="https://github.com/AylaNetworks/mobile_release_scripts"
	#rel_repo="/Users/leaf/git/mobile_release_scripts"
	
	echo "Grabbing up-to-date release scripts from \"$rel_repo\"."
	if [[ -d "$MRS_DIR" ]]; then
		if [[ -d "$MRS_DIR/.git" ]];then
			echo "Pulling changes to existing repo"
			cd "$MRS_DIR"
			git pull	
			cd "$DEST_DIR"	
		else
			echo "Removing existing folder"
			rm -rf "$MRS_DIR"
		fi
	fi
	if [[ ! -d "$MRS_DIR" ]]; then
		echo "Cloning script repo"
		cd "$DEST_DIR"
		if ! git clone "$rel_repo"; then
			echo "error: Failed to clone mobile_release_scripts repo"
			return 1
		fi
	fi
	
	if copy_files "$MRS_SUBDIR" "$DEST_DIR";then
		cd "$START_DIR"
		echo "Complete."
	else
		cd "$START_DIR"
		echo "error: Something went wrong copying release script files."
		return 1
	fi
}

install_local_fastfiles(){
	if [ -d "$DEST_DIR" ]; then
		echo "Your release environment ($DEST_DIR) is set up."
	else
		echo "Creating \"$DEST_DIR\" directory to enable fastlane"
		mkdir -p "$DEST_DIR"
	fi
	if copy_files "$SOURCE_DIR" "$DEST_DIR";then
		echo "Local files copied successfully"
	else
		echo "error: Failed to copy local fastlane files."
		return 2
	fi
	
}

full_setup(){
	if ! check_fastlane_install; then
		return 1
	fi
	if verify_workspace; then
		install_local_fastfiles
		if get_mobile_release_scripts;then
			cd "$START_DIR"
		else
			echo "error: Setup failed."
			cd "$START_DIR"
			return 4
		fi
	fi
}

full_setup
