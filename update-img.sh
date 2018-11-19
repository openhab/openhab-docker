#!/bin/bash

# Export the sha256sum for verification.
export IMG_SHA256="6b7b660fa0a4c4ab10aa2c2d7d586afdbc70cb33644995b0ee0e7f77ddcc2565"

# Download and check the sha256sum.
sudo curl -fSL "https://github.com/genuinetools/img/releases/download/v0.5.4/img-linux-amd64" -o "/usr/local/bin/img" \
	&& echo "${IMG_SHA256}  /usr/local/bin/img" | sha256sum -c - \
	&& sudo chmod a+x "/usr/local/bin/img"

echo "img installed!"

# Run it!
img -h