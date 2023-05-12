#!/bin/bash
#  Copyright (c) 2023 AUTHORS
#
#  SPDX-License-Identifier: BSL-1.0
#  Distributed under the Boost Software License, Version 1.0. (See accompanying
#  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)

sudo podman build --tag docker.io/diehlpk/monte-carlo-codes:latest -f ./Dockerfile
sudo podman login docker.io
id=$(sudo podman inspect --format="{{.Id}}" docker.io/diehlpk/monte-carlo-codes:latest)
echo $id
sudo podman push "$id" docker://diehlpk/monte-carlo-codes:latest
