#!/bin/sh

setup() {
  # Ask to run as root to prevent us from running sudo in this script.
  if [ "$(id -u)" -ne 0 ]; then
    echo "Please run this script as root! (e.g. use sudo)" >&2
    exit 1
  fi

  current_version="$(awk '/openhab-distro/{print $3}' "${OPENHAB_USERDATA}/etc/version.properties")"
  oh_version="$(echo "${OPENHAB_VERSION}" | sed 's/snapshot/SNAPSHOT/')"
  milestone_version="$(echo "${oh_version}" | awk -F'.' '{print $4}')"

  # Choose bintray for releases, jenkins for snapshots and artifactory for milestones or release candidates.
  if test "${oh_version#*-SNAPSHOT}" != "${oh_version}"; then
    addons_download_location="https://ci.openhab.org/job/openHAB-Distribution/lastSuccessfulBuild/artifact/distributions/openhab-addons/target/openhab-addons-${oh_version}.kar"
    legacy_addons_download_location="https://ci.openhab.org/job/openHAB-Distribution/lastSuccessfulBuild/artifact/distributions/openhab-addons-legacy/target/openhab-addons-legacy-${oh_version}.kar"
  elif [ "${oh_version}" = "$current_version" ]; then
    echo "You are already on openHAB $current_version" >&2
    exit 1
  elif [ -n "$milestone_version" ]; then
    addons_download_location="https://openhab.jfrog.io/openhab/libs-milestone-local/org/openhab/distro/openhab-addons/${oh_version}/openhab-addons-${oh_version}.kar"
    legacy_addons_download_location="https://openhab.jfrog.io/openhab/libs-milestone-local/org/openhab/distro/openhab-addons-legacy/${oh_version}/openhab-addons-legacy-${oh_version}.kar"
  else
    addons_download_location="https://bintray.com/openhab/mvn/download_file?file_path=org%2Fopenhab%2Fdistro%2Fopenhab-addons%2F${oh_version}%2Fopenhab-addons-${oh_version}.kar"
    legacy_addons_download_location="https://bintray.com/openhab/mvn/download_file?file_path=org%2Fopenhab%2Fdistro%2Fopenhab-addons-legacy%2F${oh_version}%2Fopenhab-addons-legacy-${oh_version}.kar"
  fi
}

run_command() {
    string="$1"
    string="$(echo "$string" | sed "s:\$OPENHAB_USERDATA:${OPENHAB_USERDATA:?}:g")"
    string="$(echo "$string" | sed "s:\$OPENHAB_CONF:${OPENHAB_CONF:?}:g")"
    string="$(echo "$string" | sed "s:\$OPENHAB_HOME:${OPENHAB_HOME:?}:g")"

    command="$(echo "$string" | awk -F';' '{print $1}')"
    param1="$(echo "$string" | awk -F';' '{print $2}')"
    param2="$(echo "$string" | awk -F';' '{print $3}')"
    param3="$(echo "$string" | awk -F';' '{print $4}')"

    case $command in
    'DEFAULT')
      if [ -f "$param1" ]; then
        echo "  Adding '.bak' to $param1"
        mv "$param1" "$param1.bak"
      fi
      echo "  Using default file $param1"
      cp "$(echo "$param1" | sed "s:${OPENHAB_HOME}:${OPENHAB_HOME}/dist:g")" "$param1"
    ;;
    'DELETE')
      # We should be strict and specific here, i.e only delete one file.
      if [ -f "$param1" ]; then
        echo "  Deleting File: $param1"
        rm -f "$param1"
      fi
    ;;
    'DELETEDIR')
      # We should be strict and specific here, i.e only delete one directory.
      if [ -d "$param1" ]; then
        echo "  Deleting Directory: $param1"
        rm -rf "$param1"
      fi
    ;;
    'MOVE')
      # Avoid error if file or directory does not exist
      if [ -e "$param1" ]; then
        echo "  Moving:   From $param1 to $param2"
        file_dir=$(dirname "$param2")
        # Create directory with same ownership as file
        if [ ! -d file_dir ]; then
          mkdir -p "$file_dir"
          prev_user_group=$(ls -ld "$param1" | awk '{print $3 ":" $4}')
          chown -R "$prev_user_group" "$file_dir"
        fi
        mv "$param1" "$param2"
      fi
    ;;
    'REPLACE')
      # Avoid error if file does not exist
      if [ -f "$param3" ]; then
        echo "  Replacing: String $param1 to $param2 in file $param3"
        sed -i "s:$param1:$param2:g" "$param3"
      fi
    ;;
    'NOTE')  printf '  \033[32mNote:\033[m     %s\n' "$param1";;
    'ALERT') printf '  \033[31mWarning:\033[m  %s\n' "$param1";;
    esac
}

get_version_number() {
  first_part="$(echo "$1" | awk -F'.' '{print $1}')"
  second_part="$(echo "$1" | awk -F'.' '{print $2}')"
  third_part="$(echo "$1" | awk -F'.' '{print $3}')"
  third_part="${third_part%%-*}"
  echo $((first_part*10000+second_part*100+third_part))
}

scan_versioning_list() {
  section="$1"
  version_message="$2"
  in_section=false
  in_new_version=false

  # Read the file line by line.
  while IFS= read -r line
  do
    case $line in
    '')
      continue
    ;;
    # Flag to run the relevant [[section]] only.
    "[[$section]]")
      in_section=true
    ;;
    # Stop reading the file if another [[section]] starts.
    "[["*"]]")
      if $in_section; then
        break
      fi
    ;;
    # Detect the [version] and execute the line if relevant.
    '['*'.'*'.'*']')
      if $in_section; then
        line_version="$(echo "$line" | awk -F'[][]' '{print $2}')"
        line_version_number=$(get_version_number "$line_version")
        if [ "$current_version_number" -lt "$line_version_number" ]; then
          in_new_version=true
          echo ""
          echo "$version_message $line_version:"
        else
          in_new_version=false
        fi
      fi
    ;;
    *)
      if $in_section && $in_new_version; then
        run_command "$line"
      fi
    ;;
    esac
  done < "${OPENHAB_HOME}/runtime/bin/update.lst"
}

echo ""
echo "################################################"
echo "          openHAB Docker update script          "
echo "################################################"
echo ""

# Run the initialisation functions defined above
setup

current_version_number=$(get_version_number "$current_version")
case $current_version in
  *"-"* | *"."*"."*"."*) current_version_number=$((current_version_number-1));;
esac

# Notify the user of important changes first
echo "The script will attempt to update openHAB to version ${oh_version}"
printf 'Please read the following \033[32mnotes\033[m and \033[31mwarnings\033[m:\n'
scan_versioning_list "MSG" "Important notes for version"
echo ""

# Perform version specific pre-update commands
scan_versioning_list "PRE" "Performing pre-update tasks for version"

echo "Replacing userdata system files with newer versions..."
while IFS= read -r file_name
do
  full_path="${OPENHAB_HOME}/dist/userdata/etc/${file_name}"
  if [ -f "$full_path" ]; then
    cp "$full_path" "${OPENHAB_USERDATA}/etc/"
  fi
done < "${OPENHAB_HOME}/runtime/bin/userdata_sysfiles.lst"

# Clearing the cache and tmp folders is necessary for upgrade.
echo "Clearing cache..."
rm -rf "${OPENHAB_USERDATA:?}/cache"
rm -rf "${OPENHAB_USERDATA:?}/tmp"

# Perform version specific post-update commands
scan_versioning_list "POST" "Performing post-update tasks for version"

# If there's an existing addons file, we need to replace it with the correct version.
addons_file="${OPENHAB_HOME}/addons/openhab-addons-${current_version}.kar"
if [ -f "$addons_file" ]; then
  echo "Found an openHAB addons file, replacing with new version..."
  rm -f "${addons_file:?}"
  curl -Lf# "$addons_download_location" -o "${OPENHAB_HOME}/addons/openhab-addons-${oh_version}.kar" || {
      echo "Download of addons file failed, please find it on the openHAB website (www.openhab.org)" >&2
  }
fi

# Do the same for the legacy addons file.
legacy_addons_file="${OPENHAB_HOME}/addons/openhab-addons-legacy-${current_version}.kar"
if [ -f "$legacy_addons_file" ]; then
  echo "Found an openHAB legacy addons file, replacing with new version..."
  rm -f "${legacy_addons_file:?}"
  curl -Lf# "$legacy_addons_download_location" -o "${OPENHAB_HOME}/addons/openhab-addons-legacy-${oh_version}.kar" || {
      echo "Download of legacy addons file failed, please find it on the openHAB website (www.openhab.org)" >&2
  }
fi
echo ""

echo ""
echo "SUCCESS: openHAB updated from ${current_version} to ${oh_version}"
echo ""
