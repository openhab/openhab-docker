#!/bin/bash
set -eo pipefail

. update-functions.sh

file=README.md
dockerfile_url='https://github.com/openhab/openhab-docker/blob/master/${version}/debian/Dockerfile'

generate_version_list() {
	for version in $(build_versions)
	do
		url=$(eval "echo $dockerfile_url")
		case $version in
		2.*.M*|2.*.RC*|3.*.M*|3.*.RC*)
			echo "* \`$version\` Experimental openHAB $version Milestone version ([Dockerfile]($url))"
			;;
		2.*-snapshot|3.*-snapshot)
			echo "* \`$version\` Experimental openHAB $(echo $version | sed 's/-snapshot/ SNAPSHOT/g') version ([Dockerfile]($url))"
			;;
		2.5.*)
			echo "* \`2.5.0\` - \`$version\` Stable openHAB $(echo $version | sed -E 's/^([0-9]+)\.([0-9])+\.([0-9])+$/\1\.\2\.x/g') version ([Dockerfile]($url))"
			;;
		*)
			echo "* \`$version\` Stable openHAB $version version ([Dockerfile]($url))"
			;;
		esac
	done
}

update_version_list() {
	generate="false"
	while IFS= read -r line
	do
		if [[ $line =~ ^.*\(\[Dockerfile\]\(https://github.com/openhab/openhab-docker/blob/master/.+/debian/Dockerfile\)\)$ ]]; then
			generate="true"
		else
			if [ "$generate" == "true" ]; then
				generate="false"
				generate_version_list
			fi
			echo "$line"
		fi
	done < $file > $file.new && mv $file.new $file
}

update_last_stable_version() {
	sed -i "s#openhab/openhab:[0-9]*\.[0-9]*\.[0-9]*#openhab/openhab:$(last_stable_version)#g" $file
}

echo -n "Writing $file... "

update_version_list
update_last_stable_version
validate_readme_constraints

echo "done"
