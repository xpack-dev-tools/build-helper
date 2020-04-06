# -----------------------------------------------------------------------------
# This file is part of the xPack distribution.
#   (https://xpack.github.io)
# Copyright (c) 2020 Liviu Ionescu.
#
# Permission to use, copy, modify, and/or distribute this software 
# for any purpose is hereby granted, under the terms of the MIT license.
# -----------------------------------------------------------------------------

# Helper script used in the tests.

# -----------------------------------------------------------------------------

# https://github.com/docker-library/official-images#architectures-other-than-amd64
# - https://hub.docker.com/_/ubuntu
# - https://hub.docker.com/r/i386/ubuntu/
# - https://hub.docker.com/r/arm32v7/ubuntu
# - https://hub.docker.com/_/debian
# - https://hub.docker.com/r/i386/debian
# - https://hub.docker.com/r/arm32v7/debian
# - https://hub.docker.com/_/centos
# - https://hub.docker.com/r/i386/centos
# - https://hub.docker.com/r/opensuse/tumbleweed
# - https://hub.docker.com/_/fedora
# - https://hub.docker.com/_/archlinux
# - https://hub.docker.com/u/manjarolinux
# - https://hub.docker.com/r/gentoo/portage

# "i386/ubuntu:20.04" # Fails to install prerequisites
# "i386/ubuntu:12.04" --skip-gdb-py # Not available
# "i386/centos:8" # not available

# arm32v7/fedora:29 - Error: Failed to synchronize cache for repo 'fedora-modular'
# arm32v7/fedora:27 - Error: Failed to synchronize cache for repo 'fedora-modular'
# arm32v7/fedora:25 - KeyError: 'armv8l'

# Debian versions: 8 jessie, 9 stretch, 10 buster.

function create_stable_data_file()
{
  local message="$1"
  local branch="$2"
  local base_url="$3"
  local data_file_path="$4"

# Note: __EOF__ is NOT quoted to allow substitutions.
cat <<__EOF__ > "${data_file_path}"
{
  "request": {
    "message": "${message}",
    "branch": "${branch}",
    "config": {
      "merge_mode": "replace",
      "jobs": [
        {
          "name": "Ubuntu Intel 64-bit",
          "os": "linux",
          "arch": "amd64",
          "dist": "bionic",
          "services": [ "docker" ],
          "language": "minimal",
          "script": [
            "env | sort",
            "pwd",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh ubuntu:20.04 ${base_url} ",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh ubuntu:18.04 ${base_url} ",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh ubuntu:16.04 ${base_url} ",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh ubuntu:14.04 ${base_url} ",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh ubuntu:12.04 ${base_url} "
          ]
        },
        {
          "name": "Ubuntu Intel 32-bit",
          "os": "linux",
          "arch": "amd64",
          "dist": "bionic",
          "services": [ "docker" ],
          "language": "minimal",
          "script": [
            "env | sort",
            "pwd",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh --32 i386/ubuntu:18.04 ${base_url} ",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh --32 i386/ubuntu:16.04 ${base_url} ",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh --32 i386/ubuntu:14.04 ${base_url} "
          ]
        },
        {
          "name": "Ubuntu Arm 64-bit",
          "os": "linux",
          "arch": "arm64",
          "dist": "bionic",
          "services": [ "docker" ],
          "language": "minimal",
          "script": [
            "env | sort",
            "pwd",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh ubuntu:20.04 ${base_url} ",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh ubuntu:18.04 ${base_url} ",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh ubuntu:16.04 ${base_url} "
          ]
        },
        {
          "name": "Ubuntu Arm 32-bit",
          "os": "linux",
          "arch": "arm64",
          "dist": "bionic",
          "services": [ "docker" ],
          "language": "minimal",
          "script": [
            "env | sort",
            "pwd",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh --32 arm32v7/ubuntu:18.04 ${base_url} ",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh --32 arm32v7/ubuntu:16.04 ${base_url} "
          ]
        },
        {
          "name": "Debian Intel 64-bit",
          "os": "linux",
          "arch": "amd64",
          "dist": "bionic",
          "services": [ "docker" ],
          "language": "minimal",
          "script": [
            "env | sort",
            "pwd",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh debian:buster ${base_url} ",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh debian:stretch ${base_url} ",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh debian:jessie ${base_url} "
          ]
        },
        {
          "name": "Debian Intel 32-bit",
          "os": "linux",
          "arch": "amd64",
          "dist": "bionic",
          "services": [ "docker" ],
          "language": "minimal",
          "script": [
            "env | sort",
            "pwd",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh --32 i386/debian:buster ${base_url} ",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh --32 i386/debian:stretch ${base_url} ",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh --32 i386/debian:jessie ${base_url} "
          ]
        },
        {
          "name": "Debian Arm 64-bit",
          "os": "linux",
          "arch": "arm64",
          "dist": "bionic",
          "services": [ "docker" ],
          "language": "minimal",
          "script": [
            "env | sort",
            "pwd",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh debian:buster ${base_url} ",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh debian:stretch ${base_url} "
          ]
        },
        {
          "name": "Debian Arm 32-bit",
          "os": "linux",
          "arch": "arm64",
          "dist": "bionic",
          "services": [ "docker" ],
          "language": "minimal",
          "script": [
            "env | sort",
            "pwd",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh --32 arm32v7/debian:buster ${base_url} ",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh --32 arm32v7/debian:stretch ${base_url} "
          ]
        },
        {
          "name": "CentOS Intel 64-bit",
          "os": "linux",
          "arch": "amd64",
          "dist": "bionic",
          "services": [ "docker" ],
          "language": "minimal",
          "script": [
            "env | sort",
            "pwd",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh centos:8 ${base_url} ",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh centos:7 ${base_url} "
          ]
        },
        {
          "name": "CentOS Intel 32-bit",
          "os": "linux",
          "arch": "amd64",
          "dist": "bionic",
          "services": [ "docker" ],
          "language": "minimal",
          "script": [
            "env | sort",
            "pwd",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh --32 i386/centos:7 ${base_url} "
          ]
        },
        {
          "name": "CentOS Arm 64-bit",
          "os": "linux",
          "arch": "arm64",
          "dist": "bionic",
          "services": [ "docker" ],
          "language": "minimal",
          "script": [
            "env | sort",
            "pwd",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh centos:8 ${base_url} ",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh centos:7 ${base_url} "
          ]
        },
        {
          "name": "OpenSUSE Intel 64-bit",
          "os": "linux",
          "arch": "amd64",
          "dist": "bionic",
          "services": [ "docker" ],
          "language": "minimal",
          "script": [
            "env | sort",
            "pwd",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh opensuse/leap:15 ${base_url} ",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh opensuse/amd64:13.2 ${base_url} "
          ]
        },
        {
          "name": "OpenSUSE Arm 64-bit",
          "os": "linux",
          "arch": "arm64",
          "dist": "bionic",
          "services": [ "docker" ],
          "language": "minimal",
          "script": [
            "env | sort",
            "pwd",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh opensuse/leap:15 ${base_url} "
          ]
        },
        {
          "name": "Fedora Intel 64-bit",
          "os": "linux",
          "arch": "amd64",
          "dist": "bionic",
          "services": [ "docker" ],
          "language": "minimal",
          "script": [
            "env | sort",
            "pwd",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh fedora:31 ${base_url} ",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh fedora:29 ${base_url} ",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh fedora:27 ${base_url} ",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh fedora:25 ${base_url} ",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh fedora:20 ${base_url} "
          ]
        },
        {
          "name": "Fedora Arm 64-bit",
          "os": "linux",
          "arch": "arm64",
          "dist": "bionic",
          "services": [ "docker" ],
          "language": "minimal",
          "script": [
            "env | sort",
            "pwd",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh fedora:31 ${base_url} ",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh fedora:29 ${base_url} ",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh fedora:27 ${base_url} "
          ]
        },
        {
          "name": "Raspbian Arm 32-bit",
          "os": "linux",
          "arch": "arm64",
          "dist": "bionic",
          "services": [ "docker" ],
          "language": "minimal",
          "script": [
            "env | sort",
            "pwd",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh --32 raspbian/stretch ${base_url} ",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh --32 raspbian/jessie ${base_url} "
          ]
        },
        {
          "name": "macOS 10.14 Intel",
          "os": "osx",
          "arch": "amd64",
          "osx_image": "xcode11.3",
          "language": "minimal",
          "script": [
            "env | sort",
            "pwd",
            "DEBUG=${DEBUG} bash tests/scripts/native-test.sh ${base_url}" 
          ]
        },
        {
          "name": "macOS 10.13 Intel",
          "os": "osx",
          "arch": "amd64",
          "osx_image": "xcode10.1",
          "language": "minimal",
          "script": [
            "env | sort",
            "pwd",
            "DEBUG=${DEBUG} bash tests/scripts/native-test.sh ${base_url}" 
          ]
        },
        {
          "name": "macOS 10.12 Intel",
          "os": "osx",
          "arch": "amd64",
          "osx_image": "xcode9.2",
          "language": "minimal",
          "script": [
            "env | sort",
            "pwd",
            "DEBUG=${DEBUG} bash tests/scripts/native-test.sh ${base_url}" 
          ]
        },
        {
          "name": "macOS 10.11 Intel",
          "os": "osx",
          "arch": "amd64",
          "osx_image": "xcode8",
          "language": "minimal",
          "script": [
            "env | sort",
            "pwd",
            "DEBUG=${DEBUG} bash tests/scripts/native-test.sh ${base_url}" 
          ]
        },
        {
          "name": "macOS 10.10 Intel",
          "os": "osx",
          "arch": "amd64",
          "osx_image": "xcode6.4",
          "language": "minimal",
          "script": [
            "env | sort",
            "pwd",
            "DEBUG=${DEBUG} bash tests/scripts/native-test.sh ${base_url}" 
          ]
        },
        {
          "name": "Windows 10 Intel 64-bit",
          "os": "windows",
          "arch": "amd64",
          "language": "minimal",
          "script": [
            "env | sort",
            "pwd",
            "DEBUG=${DEBUG} bash tests/scripts/native-test.sh ${base_url} " 
          ]
        },
        {
          "name": "Windows 10 Intel 32-bit",
          "os": "windows",
          "arch": "amd64",
          "language": "minimal",
          "script": [
            "env | sort",
            "pwd",
            "DEBUG=${DEBUG} bash tests/scripts/native-test.sh --32 ${base_url} " 
          ]
        }
      ],
      "notifications": {
        "email": {
          "on_success": "always",
          "on_failure": "always"
        }
      }
    }
  }
}
__EOF__

}

function create_latest_data_file()
{
  local message="$1"
  local branch="$2"
  local base_url="$3"
  local data_file_path="$4"

# Note: __EOF__ is NOT quoted to allow substitutions.
cat <<__EOF__ > "${data_file_path}"
{
  "request": {
    "message": "${message}",
    "branch": "${branch}",
    "config": {
      "merge_mode": "replace",
      "jobs": [
        {
          "name": "Ubuntu Intel 64-bit",
          "os": "linux",
          "arch": "amd64",
          "dist": "bionic",
          "services": [ "docker" ],
          "language": "minimal",
          "script": [
            "env | sort",
            "pwd",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh ubuntu:latest ${base_url} ",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh ubuntu:rolling ${base_url} "
          ]
        },
        {
          "name": "Ubuntu Intel 32-bit",
          "os": "linux",
          "arch": "amd64",
          "dist": "bionic",
          "services": [ "docker" ],
          "language": "minimal",
          "script": [
            "env | sort",
            "pwd",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh --32 i386/ubuntu:latest ${base_url} ",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh --32 i386/ubuntu:rolling ${base_url} "
          ]
        },
        {
          "name": "Ubuntu Arm 64-bit",
          "os": "linux",
          "arch": "arm64",
          "dist": "bionic",
          "services": [ "docker" ],
          "language": "minimal",
          "script": [
            "env | sort",
            "pwd",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh ubuntu:latest ${base_url} ",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh ubuntu:rolling ${base_url} "
          ]
        },
        {
          "name": "Ubuntu Arm 32-bit",
          "os": "linux",
          "arch": "arm64",
          "dist": "bionic",
          "services": [ "docker" ],
          "language": "minimal",
          "script": [
            "env | sort",
            "pwd",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh --32 arm32v7/ubuntu:latest ${base_url} ",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh --32 arm32v7/ubuntu:rolling ${base_url} "
          ]
        },
        {
          "name": "Debian Intel 64-bit",
          "os": "linux",
          "arch": "amd64",
          "dist": "bionic",
          "services": [ "docker" ],
          "language": "minimal",
          "script": [
            "env | sort",
            "pwd",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh debian:testing ${base_url} ",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh debian:latest ${base_url} "
          ]
        },
        {
          "name": "Debian Intel 32-bit",
          "os": "linux",
          "arch": "amd64",
          "dist": "bionic",
          "services": [ "docker" ],
          "language": "minimal",
          "script": [
            "env | sort",
            "pwd",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh --32 i386/debian:testing ${base_url} "
          ]
        },
        {
          "name": "Debian Arm 64-bit",
          "os": "linux",
          "arch": "arm64",
          "dist": "bionic",
          "services": [ "docker" ],
          "language": "minimal",
          "script": [
            "env | sort",
            "pwd",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh debian:testing ${base_url} ",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh debian:latest ${base_url} "
          ]
        },
        {
          "name": "Debian Arm 32-bit",
          "os": "linux",
          "arch": "arm64",
          "dist": "bionic",
          "services": [ "docker" ],
          "language": "minimal",
          "script": [
            "env | sort",
            "pwd",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh --32 arm32v7/debian:testing ${base_url} "
          ]
        },
        {
          "name": "CentOS Intel 64-bit",
          "os": "linux",
          "arch": "amd64",
          "dist": "bionic",
          "services": [ "docker" ],
          "language": "minimal",
          "script": [
            "env | sort",
            "pwd",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh centos:latest ${base_url} "
          ]
        },
        {
          "name": "CentOS Intel 32-bit",
          "os": "linux",
          "arch": "amd64",
          "dist": "bionic",
          "services": [ "docker" ],
          "language": "minimal",
          "script": [
            "env | sort",
            "pwd",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh --32 i386/centos:latest ${base_url} "
          ]
        },
        {
          "name": "CentOS Arm 64-bit",
          "os": "linux",
          "arch": "arm64",
          "dist": "bionic",
          "services": [ "docker" ],
          "language": "minimal",
          "script": [
            "env | sort",
            "pwd",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh centos:latest ${base_url} "
          ]
        },
        {
          "name": "OpenSUSE Intel 64-bit",
          "os": "linux",
          "arch": "amd64",
          "dist": "bionic",
          "services": [ "docker" ],
          "language": "minimal",
          "script": [
            "env | sort",
            "pwd",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh opensuse/tumbleweed ${base_url} "
          ]
        },
        {
          "name": "OpenSUSE Arm 64-bit",
          "os": "linux",
          "arch": "arm64",
          "dist": "bionic",
          "services": [ "docker" ],
          "language": "minimal",
          "script": [
            "env | sort",
            "pwd",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh opensuse/tumbleweed ${base_url} "
          ]
        },
        {
          "name": "Fedora Intel 64-bit",
          "os": "linux",
          "arch": "amd64",
          "dist": "bionic",
          "services": [ "docker" ],
          "language": "minimal",
          "script": [
            "env | sort",
            "pwd",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh fedora:rawhide ${base_url} ",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh fedora:latest ${base_url} "
          ]
        },
        {
          "name": "Fedora Arm 64-bit",
          "os": "linux",
          "arch": "arm64",
          "dist": "bionic",
          "services": [ "docker" ],
          "language": "minimal",
          "script": [
            "env | sort",
            "pwd",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh fedora:rawhide ${base_url} ",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh fedora:latest ${base_url} "
          ]
        },
        {
          "name": "Arch Intel 64-bit",
          "os": "linux",
          "arch": "amd64",
          "dist": "bionic",
          "services": [ "docker" ],
          "language": "minimal",
          "script": [
            "env | sort",
            "pwd",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh archlinux ${base_url} "
          ]
        },
        {
          "name": "Manjaro Intel 64-bit",
          "os": "linux",
          "arch": "amd64",
          "dist": "bionic",
          "services": [ "docker" ],
          "language": "minimal",
          "script": [
            "env | sort",
            "pwd",
            "DEBUG=${DEBUG} bash tests/scripts/docker-test.sh manjarolinux/base ${base_url} "
          ]
        },
        {}
      ],
      "notifications": {
        "email": {
          "on_success": "always",
          "on_failure": "always"
        }
      }
    }
  }
}
__EOF__

}

# data_file_path
# github_org
# github_repo
function trigger_travis()
{
  local github_org="$1"
  local github_repo="$2"
  local data_file_path="$3"

  curl -v -X POST \
   -H "Content-Type: application/json" \
   -H "Accept: application/json" \
   -H "Travis-API-Version: 3" \
   -H "Authorization: token ${TRAVIS_ORG_TOKEN}" \
   --data-binary @"${data_file_path}" \
   https://api.travis-ci.org/repo/${github_org}%2F${github_repo}/requests
}

# -----------------------------------------------------------------------------
