#!/bin/bash
#
# Copyright (c) 2022 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

set -e

java -jar lib/kvstore.jar kvlite -secure-config disable -root /kvroot -host "$HOSTNAME" -port "$KV_PORT" -admin-web-port "$KV_ADMIN_PORT" -harange "${KV_HARANGE/\-/\,}" -servicerange "${KV_SERVICERANGE/\-/\,}" &
java -jar lib/httpproxy.jar -helperHosts "$HOSTNAME:$KV_PORT" -storeName kvstore -httpPort "$KV_PROXY_PORT" -verbose true
