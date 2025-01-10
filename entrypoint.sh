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
    COMMIT_SHA=${INPUT_COMMIT_SHA}

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

# 检出到指定commit_sha
function checkout_commit_sha() {
    if [[ "${COMMIT_SHA}" == "" ]];then
        echo "commit_sha not provided."
    else
        # 检查 commit 是否存在
        if git rev-parse "$COMMIT_SHA" &>/dev/null; then
            echo "Commit exists"
        else
            echo "Commit does not exist. Attempting to fetch and pull updates..."
            # 执行 git pull 和 git fetch --unshallow
            git pull origin $(git rev-parse --abbrev-ref HEAD)  # 拉取当前分支的最新更新

            # 如果仓库是浅克隆，拉取完整历史
            if git rev-parse --is-shallow-repository &>/dev/null; then
                echo "Repository is shallow, fetching full history..."
                git fetch --unshallow
            fi
        fi
        # 再次检查 commit 是否存在
        if git rev-parse "$COMMIT_SHA" &>/dev/null; then
            echo "Commit exists after fetching updates"
        else
            echo "Commit still does not exist after fetching updates"
            exit 1  # 如果仍然不存在，退出并报错
        fi
        # 切换到指定的commit_sha
        git reset --hard ${COMMIT_SHA}
    fi
}

# 主函数，改进错误处理和命令执行
function main() {
    init
    echo "git clone $CLONE_REPO $CLONE_BRANCH $CLONE_DEPTH $CLONE_PATH"
    mkdir -p $CLONE_PATH && cd $CLONE_PATH
    git clone $CLONE_REPO $CLONE_BRANCH $CLONE_DEPTH . || { echo "Git clone failed"; exit 1; }
    checkout_commit_sha || { echo "Checkout commit sha failed"; exit 2; }
    init_submodule || { echo "Submodule initialization failed"; exit 2; }
}

main $@
