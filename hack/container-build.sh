#!/bin/bash

set -e
CI_PROJECT_NAME="fedhcp"
start=`date +%s`
function timing()
{
  end=`date +%s`
  # shellcheck disable=SC2046
  echo Container build time was `expr $end - $start` seconds.
}
trap timing EXIT

cd $GOPATH || exit

LDFLAGS=${LDFLAGS:-""}
LABEL=""
if [[ "$2" =~ ^feature-.*|^bugfix-.*|^v[0-9]+.[0-9]+.[0-9]+-[0-9]+.ci-.* ]]; then
    LABEL='--label quay.expires-after=14d'
    echo "set $LABEL"
fi

cd ${GOPATH}/src/${CI_SERVER_HOST}/${CI_PROJECT_PATH}.git
docker build --build-arg OSC_BUILD_VERSION=$2 --build-arg OSC_BUILD_COMMIT_SHA=${CI_COMMIT_SHA}  $LABEL --build-arg LDFLAGS="${LDFLAGS}" --build-arg CI_SERVER_HOST=${CI_SERVER_HOST} --build-arg CI_PROJECT_PATH=${CI_PROJECT_PATH} --build-arg CI_JOB_TOKEN=${CI_JOB_TOKEN} --tag ${CI_PROJECT_NAME}:$2 -f Dockerfile .
docker tag ${CI_PROJECT_NAME}:$2 ${MTR_GITLAB_HOST}/$1/${CI_PROJECT_NAME}:$2
docker login -u $MTR_GITLAB_LOGIN -p $MTR_GITLAB_PASSWORD $MTR_GITLAB_HOST
docker push ${MTR_GITLAB_HOST}/$1/${CI_PROJECT_NAME}:$2
