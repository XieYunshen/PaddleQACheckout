#!/bin/bash

echo "Hello $1"
time=$(date)
echo "time=$time" >> $GITHUB_OUTPUT
git_version=$(git --version)
echo "git_version=$git_version" >> $GITHUB_OUTPUT

# 初始化函数，简化逻辑，增加默认值处理
function init() {
    # 默认值设置
    CLONE_REPO="https://github.com/${INPUT_REPOSITORY:-$GITHUB_REPOSITORY}"
    CLONE_BRANCH="${INPUT_REF:+-b ${INPUT_REF:-main}}"
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

    # 输出信息，确认设置
    echo "Cloning repository: $CLONE_REPO"
    echo "Clone branch: $CLONE_BRANCH"
    echo "Clone path: $CLONE_PATH"
    echo "Clone depth: $CLONE_DEPTH"
}

# 判断是否需要初始化子模块，逻辑保持不变
function init_submodule() {
    if [[ "${INPUT_SUBMODULES}" == "true" ]];then
        git submodule update --init
    elif [[ "${INPUT_SUBMODULES}" == "recursive" ]];then
        git submodule update --init --recursive
    else
        echo "No submodule operation"
    fi
}

# 主函数，改进错误处理和命令执行
function main() {
    init
    echo "git clone $CLONE_REPO $CLONE_BRANCH $CLONE_DEPTH $CLONE_PATH"
    mkdir -p $CLONE_PATH && cd $CLONE_PATH
    git clone $CLONE_REPO $CLONE_BRANCH $CLONE_DEPTH . || { echo "Git clone failed"; exit 1; }
    init_submodule || { echo "Submodule initialization failed"; exit 2; }
}

main $@
