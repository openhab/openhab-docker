#!/bin/bash
set -eo pipefail

# Export the sha256sum for verification.
export MT_SHA256="80906341c3306e3838437eeb08fff5da2c38bd89149019aa301c7745e07ea8f9"

# Download and check the sha256sum.
sudo curl -fSL "https://github.com/estesp/manifest-tool/releases/download/v0.9.0/manifest-tool-linux-amd64" -o "/usr/local/bin/manifest-tool"
echo "${MT_SHA256}  /usr/local/bin/manifest-tool" | sha256sum -c -
sudo chmod a+x "/usr/local/bin/manifest-tool"

echo "manifest-tool installed!"
