#!/bin/bash
#
# Copyright 2017-2020 NXP
#
# SPDX-License-Identifier: BSD-3-Clause

# to support two different versions (branch/tag/commit) of repo for specific machine

. $FBDIR/configs/$CONFIGLIST

# $1: repo name
# $2: machine name or 'second'

if [ -n "$2" ] && [ "$2" = "$MACHINE" -o "$2" = "${MACHINE:0:5}" -o "$2" = "${MACHINE:0:7}" -o "$2" = second ]; then
    repo_tag=$(eval echo '$'second_"$1"_repo_tag)
    repo_branch=$(eval echo '$'second_"$1"_repo_branch)
    repo_commit=$(eval echo '$'second_"$1"_repo_commit)
else
    repo_tag=$(eval echo '$'"$1"_repo_tag)
    repo_branch=$(eval echo '$'"$1"_repo_branch)
    repo_commit=$(eval echo '$'"$1"_repo_commit)
fi

if [ "$UPDATE_REPO_PER_TAG" = y -a -n "$repo_tag" ] && [ "`cat .git/HEAD | cut -d/ -f3`" != "$repo_tag" ]; then
    echo swithing to $repo_tag ...
    if git show-ref --verify --quiet refs/heads/$repo_tag; then
        git checkout $repo_tag
    else
        git checkout $repo_tag -b $repo_tag
    fi
elif [ "$UPDATE_REPO_PER_COMMIT" = "y" -a -n "$repo_commit" ] && \
     [ "`cat .git/HEAD | cut -d/ -f3`" != "$repo_commit" ]; then
    echo swithing to commit $repo_commit ...
    if git show-ref --verify --quiet refs/heads/$repo_commit; then
        git checkout $repo_commit
    else
        git checkout $repo_commit -b $repo_commit
    fi
elif [ "$UPDATE_REPO_PER_BRANCH" = y -a -n "$repo_branch" ] && [ "`cat .git/HEAD | cut -d/ -f3`" != "$repo_branch" ]; then
    echo swithing to $repo_branch ...
    if git show-ref --verify --quiet refs/heads/$repo_branch; then
        git checkout $repo_branch
    else
        git checkout remotes/origin/$repo_branch -b $repo_branch
    fi
fi
