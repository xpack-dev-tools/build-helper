# -----------------------------------------------------------------------------

# Helper script used in the second edition of the GNU MCU Eclipse build 
# scripts. As the name implies, it should contain only functions and 
# should be included with 'source' by the build scripts (both native
# and container).

# -----------------------------------------------------------------------------

function do_config_guess() 
{
  if [ -f "${XBB_FOLDER}/share/libtool/build-aux/config.guess" ]
  then
    BUILD="$(${XBB_FOLDER}/share/libtool/build-aux/config.guess)"
  elif [ -f "/usr/share/libtool/build-aux/config.guess" ]
  then
    BUILD="$(/usr/share/libtool/build-aux/config.guess)"
  elif [ -f "/usr/share/misc/config.guess" ]
  then
    BUILD="$(/usr/share/misc/config.guess)"
  else
    echo "Could not find config.guess."
    exit 1
  fi
}

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
    if [ ${TARGET_ARCH} == "x32" ]
    then
      CROSS_COMPILE_PREFIX="i686-w64-mingw32"
    elif [ ${TARGET_ARCH} == "x64" ]
    then
      CROSS_COMPILE_PREFIX="x86_64-w64-mingw32"
    fi

    do_config_guess

    HOST="${CROSS_COMPILE_PREFIX}"
    TARGET=${HOST}

  elif [ "${TARGET_PLATFORM}" == "darwin" ]
  then

    TARGET_BITS="64" # For now, only 64-bit macOS binaries

    do_config_guess

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

    do_config_guess

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
  # Do it later, only if needed.
  # mkdir -p "${DEPLOY_FOLDER_PATH}"
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

function check_binary()
{
  local file_path="$1"

  if [ ! -x "${file_path}" ]
  then
    return 0
  fi

  if file --mime "${file_path}" | grep -q text
  then
    return 0
  fi

  check_library "$1"
}

function check_library()
{
  local file_path="$1"
  local file_name="$(basename ${file_path})"
  local folder_name="$(dirname ${file_path})"

  (
    xbb_activate

    if [ "${TARGET_PLATFORM}" == "win32" ]
    then
      echo
      echo "${file_path}"
      set +e
      ${CROSS_COMPILE_PREFIX}-objdump -x "${file_path}" | grep -i 'DLL Name'

      local dll_names=$(${CROSS_COMPILE_PREFIX}-objdump -x "${file_path}" \
        | grep -i 'DLL Name' \
        | sed -e 's/.*DLL Name: \(.*\)/\1/' \
      )

      for n in ${dll_names}
      do
        if [ ! -f "${folder_name}/${n}" ] 
        then
          if is_win_sys_dll "${n}"
          then
            :
          elif [ "${n}${HAS_WINPTHREAD}" == "libwinpthread-1.dlly" ]
          then
            :
          elif [[ ${n} == python*.dll ]] && [[ ${file_name} == *-gdb-py.exe ]]
          then
            :
          else
            echo "Unexpected |${n}|"
            exit 1
          fi
        fi
      done
      set -e
    elif [ "${TARGET_PLATFORM}" == "darwin" ]
    then
      echo
      set +e
      otool -L "${file_path}"

      local unxp=$(otool -L "${file_path}" | sed '1d' | grep -v "${file_name}" | egrep -e "(macports|homebrew|opt|install)/")
      set -e
      # echo "|${unxp}|"
      if [ ! -z "$unxp" ]
      then
        echo "Unexpected |${unxp}|"
        exit 1
      fi
    elif [ "${TARGET_PLATFORM}" == "linux" ]
    then
      echo
      echo "${file_path}"
      set +e
      readelf -d "${file_path}" | egrep -i 'library|dynamic'

      local so_names=$(readelf -d "${file_path}" \
        | grep -i 'Shared library' \
        | sed -e 's/.*Shared library: \[\(.*\)\]/\1/' \
      )

      for n in ${so_names}
      do
        if [ ! -f "${folder_name}/${n}" ] 
        then
          if is_linux_sys_so "${n}"
          then
            :
          elif [[ ${n} == libpython* ]] && [[ ${file_name} == *-gdb-py ]]
          then
            :
          else
            echo "Unexpected |${n}|"
            exit 1
          fi
        fi
      done
      set -e
    fi
  )
}

function is_win_sys_dll() 
{
  local dll_name="$1"

  # DLLs that are expected to be present on any Windows.
  local sys_dlls=(ADVAPI32.dll \
    KERNEL32.dll \
    msvcrt.dll \
    SHELL32.dll \
    USER32.dll \
    WINMM.dll \
    WINMM.DLL \
    WS2_32.dll \
    ole32.dll \
    DNSAPI.dll \
    IPHLPAPI.dll \
    GDI32.dll \
    IMM32.dll \
    IMM32.DLL \
    OLEAUT32.dll \
    IPHLPAPI.DLL \
    VERSION.dll \
    SETUPAPI.dll \
  )

  for dll in "${sys_dlls[@]}"
  do
    if [ "${dll}" == "${dll_name}" ]
    then
        return 0 # True
    fi
  done
  return 1 # False
}

function is_linux_sys_so() 
{
  local lib_name="$1"

  # Shared libraries that are expected to be present on any Linux.
  local sys_libs=(\
    librt.so.1 \
    libm.so.6 \
    libc.so.6 \
    libutil.so.1 \
    libpthread.so.0 \
    libdl.so.2 \
    ld-linux-x86-64.so.2 \
    ld-linux.so.2 \
    libX11.so.6 \
  )

  for lib in "${sys_libs[@]}"
  do
    if [ "${lib}" == "${lib_name}" ]
    then
        return 0 # True
    fi
  done
  return 1 # False
}

# -----------------------------------------------------------------------------

function copy_win_gcc_dll() 
{
  local dll_name="$1"

  # Identify the current cross gcc version, to locate the specific dll folder.
  local cross_gcc_version=$(${CROSS_COMPILE_PREFIX}-gcc --version | grep 'gcc' | sed -e 's/.*\s\([0-9]*\)[.]\([0-9]*\)[.]\([0-9]*\).*/\1.\2.\3/')
  local cross_gcc_version_short=$(echo ${cross_gcc_version} | sed -e 's/\([0-9]*\)[.]\([0-9]*\)[.]\([0-9]*\).*/\1.\2/')
  local SUBLOCATION="-win32"

  # First try Ubuntu specific locations,
  # then do a long full search.

  if [ -f "${XBB_FOLDER}/${CROSS_COMPILE_PREFIX}/lib/${dll_name}" ]
  then
    cp -v "${XBB_FOLDER}/${CROSS_COMPILE_PREFIX}/lib/${dll_name}" \
      "${APP_PREFIX}"/bin
  elif [ -f "/usr/lib/gcc/${CROSS_COMPILE_PREFIX}/${cross_gcc_version}/${dll_name}" ]
  then
    cp -v "/usr/lib/gcc/${CROSS_COMPILE_PREFIX}/${cross_gcc_version}/${dll_name}" \
      "${APP_PREFIX}"/bin
  elif [ -f "/usr/lib/gcc/${CROSS_COMPILE_PREFIX}/${cross_gcc_version_short}/${dll_name}" ]
  then
    cp -v "/usr/lib/gcc/${CROSS_COMPILE_PREFIX}/${cross_gcc_version_short}/${dll_name}" \
      "${APP_PREFIX}"/bin
  elif [ -f "/usr/lib/gcc/${CROSS_COMPILE_PREFIX}/${cross_gcc_version_short}${SUBLOCATION}/${dll_name}" ]
  then
    cp -v "/usr/lib/gcc/${CROSS_COMPILE_PREFIX}/${cross_gcc_version_short}${SUBLOCATION}/${dll_name}" \
      "${APP_PREFIX}"/bin
  else
    echo "Searching /usr for ${dll_name}..."
    SJLJ_PATH=$(find "${XBB_FOLDER}/${CROSS_COMPILE_PREFIX}" /usr \! -readable -prune -o -name ${dll_name} -print | grep ${CROSS_COMPILE_PREFIX})
    cp -v ${SJLJ_PATH} "${APP_PREFIX}"/bin
  fi
}

function copy_win_libwinpthread_dll() 
{
  if [ -f "${XBB_FOLDER}/${CROSS_COMPILE_PREFIX}"/bin/libwinpthread-1.dll ]
  then
    cp "${XBB_FOLDER}/${CROSS_COMPILE_PREFIX}"/bin/libwinpthread-1.dll \
      "${APP_PREFIX}/bin"
  else
    echo "No libwinpthread-1.dll"
    exit 1
  fi
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

function xbb_activate_this()
{
  export EXTRA_CPPFLAGS+=" -I${LIBS_INSTALL_FOLDER_PATH}/include"
  export EXTRA_LDFLAGS+=" -L${LIBS_INSTALL_FOLDER_PATH}/lib"
  export EXTRA_LDFLAGS_APP+=" -L${LIBS_INSTALL_FOLDER_PATH}/lib"

  export PKG_CONFIG_PATH="${LIBS_INSTALL_FOLDER_PATH}/lib/pkgconfig:${PKG_CONFIG_PATH}"
}

# -----------------------------------------------------------------------------
