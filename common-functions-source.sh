# -----------------------------------------------------------------------------

# Helper script used in the second edition of the GNU MCU Eclipse build 
# scripts. As the name implies, it should contain only functions and 
# should be included with 'source' by the build scripts (both native
# and container).

# -----------------------------------------------------------------------------

function extract()
{
  local archive_name="$1"
  local folder_name="$2"
  # local patch_file_name="$3"
  local pwd="$(pwd)"

  if [ ! -d "${folder_name}" ]
  then
    (
      xbb_activate

      echo
      echo "Extracting \"${archive_name}\"..."
      if [[ "${archive_name}" == *zip ]]
      then
        unzip "${archive_name}" 
      else
        tar xf "${archive_name}"
      fi

      if [ $# -gt 2 ]
      then
        if [ ! -z "$3" ]
        then
          local patch_file_name="$3"
          local patch_path="${WORK_FOLDER_PATH}/build.git/patches/${patch_file_name}"
          if [ -f "${patch_path}" ]
          then
            echo "Patching..."
            patch -p0 < "${patch_path}"
          fi
        fi
      fi
    )
  else
    echo "Folder \"$(pwd)/${folder_name}\" already present."
  fi
}

function download()
{
  local url="$1"
  local archive_name="$2"

  if [ ! -f "${DOWNLOAD_FOLDER_PATH}/${archive_name}" ]
  then
    (
      xbb_activate

      echo
      echo "Downloading \"${archive_name}\" from \"${url}\"..."
      rm -f "${DOWNLOAD_FOLDER_PATH}/${archive_name}.download"
      mkdir -p "${DOWNLOAD_FOLDER_PATH}"
      curl --fail -L -o "${DOWNLOAD_FOLDER_PATH}/${archive_name}.download" "${url}"
      mv "${DOWNLOAD_FOLDER_PATH}/${archive_name}.download" "${DOWNLOAD_FOLDER_PATH}/${archive_name}"
    )
  else
    echo "File \"${DOWNLOAD_FOLDER_PATH}/${archive_name}\" already downloaded."
  fi
}

function download_and_extract()
{
  local url="$1"
  local archive_name="$2"
  local folder_name="$3"

  download "${url}" "${archive_name}" 
  extract "${DOWNLOAD_FOLDER_PATH}/${archive_name}" "${folder_name}"
}

function git_clone()
{
  local url="$1"
  local branch="$2"
  local commit="$3"
  local folder_name="$4"

  (
    echo
    echo "Cloning \"${folder_name}\" from \"${url}\"..."
    git clone --branch="${branch}" "${url}" "${folder_name}"
    if [ -n "${commit}" ]
    then
      cd "${folder_name}"
      git checkout -qf "${commit}"
    fi
  )
}

