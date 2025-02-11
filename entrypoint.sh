#!/bin/bash

echo "Hello $1"
time=$(date)
echo "time=$time" >> $GITHUB_OUTPUT
git_version=$(git --version)
echo "git_version=$git_version" >> $GITHUB_OUTPUT

# Initialize function to simplify logic and handle default values
function init() {
    # Handling default values
    CLONE_REPO="https://github.com/${INPUT_REPOSITORY:-$GITHUB_REPOSITORY}"
    CLONE_REF="${INPUT_REF:+-b ${INPUT_REF:-main}}"
    if [[ -z "${INPUT_PATH}" ]];then
        if [[ -z "${INPUT_REPOSITORY}" ]];then
            CLONE_PATH="${GITHUB_REPOSITORY##*/}"
        else
            CLONE_PATH="${CLONE_REPO##*/}"
        fi
    else
        CLONE_PATH="${INPUT_PATH}"
    fi
    CLONE_DEPTH="${INPUT_FETCH_DEPTH:+--depth ${INPUT_FETCH_DEPTH:-1}}"
    if [[ -z "${INPUT_BRANCH_NAME}" ]];then
        BRANCH_NAME=${CLONE_REF}
    fi
    # Repository compression setting
    REPO_COMPRESS=${INPUT_REPO_COMPRESS}

    # Output information to confirm settings
    echo "Cloning repository: $CLONE_REPO"
    echo "Clone ref: $CLONE_REF"
    echo "Branch Name: $BRANCH_NAME"
    echo "Clone path: $CLONE_PATH"
    echo "Clone depth: $CLONE_DEPTH"
    echo "Repo compress: $REPO_COMPRESS"
}

# Check if submodule initialization is needed;
function init_submodule() {
    if [[ "${INPUT_SUBMODULES}" == "true" ]];then
        git submodule update --init
    elif [[ "${INPUT_SUBMODULES}" == "recursive" ]];then
        git submodule update --init --recursive
    else
        echo "No submodule operation"
    fi
}

# Repository cleanup and compression
function clean_and_compress_repo() {
    if [[ "${INPUT_REPO_COMPRESS}" == "true" ]];then
        # Remove unreachable objects and pack loose objects
        echo "Running garbage collection..."
        git gc --prune=now --quiet

        # Repack to optimize pack files
        echo "Repacking objects..."
        git repack -a -d -q
        if git submodule status &>/dev/null; then
            git submodule foreach 'git gc --prune=now'
            git submodule foreach 'git repack -a -d -q'
        fi
    fi
}

# Main function
function main() {
    init
    mkdir -p $CLONE_PATH && cd $CLONE_PATH
    git init
    git remote add origin $CLONE_REPO
    git fetch $CLONE_DEPTH origin $CLONE_REF
    git checkout --force $CLONE_REF
    # Get the current branch name
    branch_name=$(git rev-parse --abbrev-ref HEAD)

    # Check if it's in detached HEAD state
    if [[ "$branch_name" == "HEAD" ]]; then
        echo "You are in 'detached HEAD' state."
        git checkout -b $BRANCH_NAME
    else
        echo "You are not in 'detached HEAD' state."
    fi
    init_submodule || { echo "Submodule initialization failed"; exit 2; }
    clean_and_compress_repo
}

main $@
