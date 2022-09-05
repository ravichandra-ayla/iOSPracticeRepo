#!/bin/bash

# This script increments the patch version only.  Team needs to update the major or minor version manually. 

Android_Sepia_Repo_URL="https://github.com/AylaNetworks/Android_Sepia"
Android_Sepia_Repo_Name="Android_Sepia"
SDK_Repo_URL="https://github.com/AylaNetworks/Android_AylaSDK"
SDK_Repo_Name="Android_AylaSDK"

PREFIX1="v"
PREFIX2="updated-"
MASTER_DEVELOP_SAME="no"

Is_Minor_Version_Incrementation="no"

strip() {
    local STRING=${1#$"$2"}
    echo ${STRING%$"$2"}
}

check_if_need_to_increment_minor_version(){
    git clone $1
    cd $2 
    git checkout develop     
    TAG=`git describe --abbrev=0 --tags`
    echo "The latest tag from git describe is $TAG"

    VERSION=$(strip "$TAG" "$PREFIX2")
    VERSION=$(strip "$VERSION" "$PREFIX1")
    echo "The latest tag without the prefix is $VERSION"

    #replace . with space so can split into an array
    VERSION_BITS=(${VERSION//./ })

    VNUM1=${VERSION_BITS[0]}
    VNUM2=${VERSION_BITS[1]}
    VNUM3=${VERSION_BITS[2]}


    if [ $VNUM3 -eq 00 ]; then
        Is_Minor_Version_Incrementation="yes"
    elif [ $VNUM3 -eq 0 ]; then
        Is_Minor_Version_Incrementation="yes"
    else
        Is_Minor_Version_Incrementation="no"
    fi    
    cd ..
    rm -rf $2
} 

create_new_tag_for_repo_patch_version() {
    git clone $1
    cd $2
    git checkout develop
    TAG=`git describe --abbrev=0 --tags`
    echo "The latest tag from git describe is $TAG"

    VERSION=$(strip "$TAG" "$PREFIX2")
    VERSION=$(strip "$VERSION" "$PREFIX1")
    echo "The latest tag without the prefix is $VERSION"
    
    #replace . with space so can split into an array
    VERSION_BITS=(${VERSION//./ })

    #get number parts and increase last one by 1
    VNUM1=${VERSION_BITS[0]}
    VNUM2=${VERSION_BITS[1]}
    VNUM3=${VERSION_BITS[2]}
    # handle 08 and 09 with #0
    VNUM3=$((10#$VNUM3 + 1))

    # If the patch version contains only one digit, append it with a zero. 
    VNUM3_digit_count=${#VNUM3}

    if [ $VNUM3_digit_count -eq 1 ]; then
      # add leading zero
      VNUM3=0${VNUM3}
    fi 
    
    #create new tag with the prefix v.
    NEW_TAG="v$VNUM1.$VNUM2.$VNUM3"
    echo "Updating $VERSION to $NEW_TAG"
    echo "Creating a new tag $NEW_TAG."
    git tag $NEW_TAG
    echo "Pushing the new tag to remote."
    git push --tags
    cd ..
    rm -rf $2
} 

create_new_tag_for_repo_minor_version() {
    git clone $1
    cd $2
    git checkout develop
    TAG=`git describe --abbrev=0 --tags`
    echo "The latest tag from git describe is $TAG"

    VERSION=$(strip "$TAG" "$PREFIX2")
    VERSION=$(strip "$VERSION" "$PREFIX1")
    echo "The latest tag without the prefix is $VERSION"
    
    #replace . with space so can split into an array
    VERSION_BITS=(${VERSION//./ })

    #get number parts and increase the middle one by 1
    #last version becomes 00
    VNUM1=${VERSION_BITS[0]}
    VNUM2=${VERSION_BITS[1]}
    VNUM3=${VERSION_BITS[2]}
    VNUM2=$((VNUM2+1))
    VNUM3=00

    #create new tag with the prefix v.
    NEW_TAG="v$VNUM1.$VNUM2.$VNUM3"
    echo "Updating $VERSION to $NEW_TAG"
    echo "Creating a new tag $NEW_TAG."
    git tag $NEW_TAG
    echo "Pushing the new tag to remote."
    git push --tags
    cd ..
    rm -rf $2
} 

echo "Check if the next release is minor version incrementation by checking the SDK repo. Releases start from the SDK repo."

check_if_need_to_increment_minor_version "$SDK_Repo_URL" "$SDK_Repo_Name"
echo "Is_Minor_Version_Incrementation is ${Is_Minor_Version_Incrementation}."


echo "********** ANDROID SEPIA ***********"

if [[ "$Is_Minor_Version_Incrementation" == *"yes"* ]]; then
    echo "Updating the minor version in ANDROID SEPIA"
    create_new_tag_for_repo_minor_version "$Android_Sepia_Repo_URL" "$Android_Sepia_Repo_Name"
elif [[ "$Is_Minor_Version_Incrementation" == *"no"* ]]; then
    echo "Updating the patch version in ANDROID SEPIA"
    create_new_tag_for_repo_patch_version "$Android_Sepia_Repo_URL" "$Android_Sepia_Repo_Name"
else
    echo "Is_Minor_Version_Incrementation is not yes or no.  Something is wrong in this bash script. "
    exit 1    
fi


