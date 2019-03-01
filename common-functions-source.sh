# -----------------------------------------------------------------------------

# Helper script used in the second edition of the GNU MCU Eclipse build 
# scripts. As the name implies, it should contain only functions and 
# should be included with 'source' by the build scripts (both native
# and container).

# -----------------------------------------------------------------------------

function prepare_prerequisites() 
{
  if [ -f "${HOME}"/opt/homebrew/xbb/xbb-source.sh ]
  then
    echo
    echo "Sourcing ${HOME}/opt/homebrew/xbb/xbb-source.sh..."
    source "${HOME}"/opt/homebrew/xbb/xbb-source.sh
  elif [ -f "/opt/xbb/xbb-source.sh" ]
  then
    echo
    echo "Sourcing /opt/xbb/xbb-source.sh..."
    source "/opt/xbb/xbb-source.sh"
  fi

  TARGET_FOLDER_NAME="${TARGET_PLATFORM}-${TARGET_ARCH}"

  # Compute the BUILD/HOST/TARGET for configure.
  CROSS_COMPILE_PREFIX=""
  if [ "${TARGET_PLATFORM}" == "win32" ]
  then

    # For Windows targets, decide which cross toolchain to use.
    if [ ${TARGET_BITS} == "32" ]
    then
      CROSS_COMPILE_PREFIX="i686-w64-mingw32"
    elif [ ${TARGET_BITS} == "64" ]
    then
      CROSS_COMPILE_PREFIX="x86_64-w64-mingw32"
    fi

    BUILD="$(${XBB_FOLDER}/share/libtool/build-aux/config.guess)"
    HOST="${CROSS_COMPILE_PREFIX}"
    TARGET=${HOST}

  elif [ "${TARGET_PLATFORM}" == "darwin" ]
  then

    TARGET_BITS="64" # For now, only 64-bit macOS binaries

    BUILD="$(${XBB_FOLDER}/share/libtool/build-aux/config.guess)"
    HOST=${BUILD}
    TARGET=${HOST}

  elif [ "${TARGET_PLATFORM}" == "linux" ]
  then

if false
then

    if [ "${TARGET_BITS}" == "-" ]
    then
      TARGET_BITS="${CONTAINER_BITS}"
    else
      if [ "${TARGET_BITS}" != "${CONTAINER_BITS}" ]
      then
        echo "Cannot build ${TARGET_BITS} target on the ${CONTAINER_BITS} container."
        exit 1
      fi
    fi
fi

    if [ -f "${XBB_FOLDER}/share/libtool/build-aux/config.guess" ]
    then
      BUILD="$(${XBB_FOLDER}/share/libtool/build-aux/config.guess)"
    elif [ -f "/usr/share/libtool/build-aux/config.guess" ]
    then
      BUILD="$(/usr/share/libtool/build-aux/config.guess)"
    elif [ -f "/usr/share/misc/config.guess" ]
    then
      BUILD="$(/usr/share/misc/config.guess)"
    fi

    HOST=${BUILD}
    TARGET=${HOST}

  else
    echo "Unsupported target platform ${TARGET_PLATFORM}"
    exit 1
  fi

  if [ -f "/.dockerenv" ]
  then
    WORK_FOLDER_PATH="${CONTAINER_WORK_FOLDER_PATH}"
    DOWNLOAD_FOLDER_PATH="${CONTAINER_CACHE_FOLDER_PATH}"
  else
    WORK_FOLDER_PATH="${HOST_WORK_FOLDER_PATH}"
    DOWNLOAD_FOLDER_PATH="${HOST_CACHE_FOLDER_PATH}"
  fi

  if [ \( "${IS_DEVELOP}" != "y" \) -a \( -f "/.dockerenv" \) ]
  then
    BUILD_FOLDER_PATH="/tmp/${TARGET_FOLDER_NAME}/build"
  else
    BUILD_FOLDER_PATH="${WORK_FOLDER_PATH}/${TARGET_FOLDER_NAME}/build"
  fi

  LIBS_BUILD_FOLDER_PATH="${BUILD_FOLDER_PATH}/libs"
  APP_BUILD_FOLDER_PATH="${BUILD_FOLDER_PATH}/${APP_LC_NAME}"

  mkdir -p "${LIBS_BUILD_FOLDER_PATH}"
  mkdir -p "${APP_BUILD_FOLDER_PATH}"

  INSTALL_FOLDER_PATH="${WORK_FOLDER_PATH}/${TARGET_FOLDER_NAME}/install"
  LIBS_INSTALL_FOLDER_PATH="${INSTALL_FOLDER_PATH}/libs"
  APP_INSTALL_FOLDER_PATH="${INSTALL_FOLDER_PATH}/${APP_LC_NAME}"

  mkdir -p "${LIBS_INSTALL_FOLDER_PATH}"
  mkdir -p "${APP_INSTALL_FOLDER_PATH}"

  APP_PREFIX="${APP_INSTALL_FOLDER_PATH}"
  APP_PREFIX_DOC="${APP_PREFIX}"/doc

  DEPLOY_FOLDER_NAME=${DEPLOY_FOLDER_NAME:-"deploy"}

  DEPLOY_FOLDER_PATH="${WORK_FOLDER_PATH}/${DEPLOY_FOLDER_NAME}"
  mkdir -p "${DEPLOY_FOLDER_PATH}"
}

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

# Copy the build files to the Work area, to make them easily available. 
function copy_build_git()
{
  rm -rf "${HOST_WORK_FOLDER_PATH}"/build.git
  mkdir -p "${HOST_WORK_FOLDER_PATH}"/build.git
  cp -r "$(dirname ${script_folder_path})"/* "${HOST_WORK_FOLDER_PATH}"/build.git
  rm -rf "${HOST_WORK_FOLDER_PATH}"/build.git/scripts/helper/.git
  rm -rf "${HOST_WORK_FOLDER_PATH}"/build.git/scripts/helper/build-helper.sh
}

# -----------------------------------------------------------------------------

# Default empty definition, if XBB is available, it should
# redefine it.
function xbb_activate()
{
  :
}

function xbb_activate_pkgconfig()
{
  if [ "${TARGET_PLATFORM}" == "linux" ]
  then
    if [ ! -z "${PKG_CONFIG_PATH}" ]
    then
      if [ -d "/usr/lib/pkgconfig" ]
      then
        PKG_CONFIG_PATH="/usr/lib/pkgconfig"
      fi
    fi
    export PKG_CONFIG_PATH
  fi
}

function xbb_activate_includes()
{
  :
}

# Default, to fix the missing definition on ARCH.
function xbb_activate_dev()
{
  xbb_activate_pkgconfig
  xbb_activate_includes
}

# -----------------------------------------------------------------------------
