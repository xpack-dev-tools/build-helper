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

function prepare_xbb_env() 
{
  if [ -f "${HOME}/opt/homebrew/xbb/xbb-source.sh" ]
  then
    echo
    echo "Sourcing ${HOME}/opt/homebrew/xbb/xbb-source.sh..."
    source "${HOME}/opt/homebrew/xbb/xbb-source.sh"
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
    TARGET="${HOST}"

  elif [ "${TARGET_PLATFORM}" == "darwin" ]
  then

    TARGET_BITS="64" # For now, only 64-bit macOS binaries

    do_config_guess

    HOST="${BUILD}"
    TARGET="${HOST}"

  elif [ "${TARGET_PLATFORM}" == "linux" ]
  then

    do_config_guess

    HOST="${BUILD}"
    TARGET="${HOST}"

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

  # Develop builds use the host folder.
  BUILD_FOLDER_PATH="${WORK_FOLDER_PATH}/${TARGET_FOLDER_NAME}/build"
  if [ -f "/.dockerenv" ]
  then 
    if [ "${IS_DEVELOP}" != "y" ]
    then
      # Docker builds use a temporary folder.
      BUILD_FOLDER_PATH="/tmp/${TARGET_FOLDER_NAME}/build"
    fi
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

  DEPLOY_FOLDER_NAME="${DEPLOY_FOLDER_NAME:-"deploy"}"
  DEPLOY_FOLDER_PATH="${WORK_FOLDER_PATH}/${DEPLOY_FOLDER_NAME}"
  # Do it later, only if needed.
  # mkdir -p "${DEPLOY_FOLDER_PATH}"

  BUILD_GIT_PATH="${WORK_FOLDER_PATH}/build.git"

  IS_DEVELOP=${IS_DEVELOP:-""}
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
  rm -rf "${HOST_WORK_FOLDER_PATH}/build.git"
  mkdir -p "${HOST_WORK_FOLDER_PATH}/build.git"
  cp -r "$(dirname ${script_folder_path})"/* "${HOST_WORK_FOLDER_PATH}/build.git"
  rm -rf "${HOST_WORK_FOLDER_PATH}/build.git/scripts/helper/.git"
  rm -rf "${HOST_WORK_FOLDER_PATH}/build.git/scripts/helper/build-helper.sh"
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
  local folder_path="$(dirname ${file_path})"

  (
    xbb_activate

    if [ "${TARGET_PLATFORM}" == "win32" ]
    then
      echo
      echo "${file_name}"
      set +e
      ${CROSS_COMPILE_PREFIX}-objdump -x "${file_path}" | grep -i 'DLL Name'

      local dll_names=$(${CROSS_COMPILE_PREFIX}-objdump -x "${file_path}" \
        | grep -i 'DLL Name' \
        | sed -e 's/.*DLL Name: \(.*\)/\1/' \
      )

      for n in ${dll_names}
      do
        if [ ! -f "${folder_path}/${n}" ] 
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
      (
        set +e
        cd ${folder_path}
        otool -L "${file_name}"
        set -e
      )

      set +e
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
      echo "${file_name}"
      set +e
      readelf -d "${file_path}" | egrep -i 'library|dynamic'

      local so_names=$(readelf -d "${file_path}" \
        | grep -i 'Shared library' \
        | sed -e 's/.*Shared library: \[\(.*\)\]/\1/' \
      )

      for n in ${so_names}
      do
        if [ ! -f "${folder_path}/${n}" ] 
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

# Strip binary files as in "strip binary" form, for both native
# (linux/mac) and mingw.
function strip_binary() 
{
    set +e
    if [ $# -lt 2 ]
    then
        warning "strip_binary: Missing arguments"
        exit 1
    fi

    local strip="$1"
    local bin="$2"

    if is_elf ${bin}
    then
      echo ${strip} ${bin}
      ${strip} ${bin} 2>/dev/null || true
    else
      echo $(file ${bin})
    fi

    set -e
}

function is_elf()
{
  if [ $# -lt 1 ]
  then
    warning "is_elf: Missing arguments"
    exit 1
  fi
  local bin="$1"

  # Return 0 (true) if found.
  file ${bin} | egrep -q "( ELF )|( PE )|( PE32 )|( PE32\+ )|( Mach-O )"
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
    cp -v ${SJLJ_PATH} "${APP_PREFIX}/bin"
  fi
}

function copy_win_libwinpthread_dll() 
{
  if [ -f "${XBB_FOLDER}/${CROSS_COMPILE_PREFIX}/bin/libwinpthread-1.dll" ]
  then
    cp "${XBB_FOLDER}/${CROSS_COMPILE_PREFIX}/bin/libwinpthread-1.dll" \
      "${APP_PREFIX}/bin"
  else
    echo "No libwinpthread-1.dll"
    exit 1
  fi
}

# -----------------------------------------------------------------------------

function change_dylib()
{
  local dylib_name="$1"
  local file_path="$2"

  local dylib_path=$(otool -L "${file_path}" | grep "${dylib_name}" | sed -e 's/[[:space:]]*\(.*dylib\).*/\1/')

  if [ -z "${dylib_path}" ]
  then
    echo "Dylib ${dylib_name} not used in binary ${file_path}..."
    exit 1
  fi

  chmod +w "${file_path}"
  install_name_tool \
    -change "${dylib_path}" \
    "@executable_path/${dylib_name}" \
    "${file_path}"

  if [ ! -f "$(dirname ${file_path})/$(basename ${dylib_path})" ]
  then
    cp "${dylib_path}" "$(dirname ${file_path})"
    chmod +w "$(dirname ${file_path})/$(basename ${dylib_path})"
  fi
}

# Workaround to Docker error on 32-bit image:
# stat: Value too large for defined data type
function patch_linux_elf_origin()
{
  local file_path="$1"

  local tmp_path=$(mktemp)
  rm -rf "${tmp_path}"
  cp "${file_path}" "${tmp_path}"
  patchelf --set-rpath '$ORIGIN' "${tmp_path}"
  cp "${tmp_path}" "${file_path}"
  rm -rf "${tmp_path}"
}

function copy_linux_user_so() 
{
  local dll_name="$1"

  ILIB=$(find ${LIBS_INSTALL_FOLDER_PATH}/lib* -type f -name ${dll_name}'.so.*' -print | egrep '.so.[[:digit:]]+.[[:digit:]]+.[[:digit:]]+$')
  if [ ! -z "${ILIB}" ]
  then
    echo "Found user ${ILIB}, 3 digits"

    ihead=$(echo "${ILIB}" | head -n 1)
    # Add "runpath" in library with value $ORIGIN.
    patch_linux_elf_origin "${ihead}"

    /usr/bin/install -v -c -m 644 "${ihead}" "${APP_PREFIX}/bin"

    ILIB_BASE="$(basename ${ihead})"
    # Skip last two digits, keep one.
    ILIB_SHORT="$(echo $ILIB_BASE | sed -e 's/\(.*\)[.][[:digit:]]*[.][[:digit:]]*/\1/')"
    (
      cd "${APP_PREFIX}/bin"
      rm --force "${ILIB_SHORT}"
      ln -sv "${ILIB_BASE}" "${ILIB_SHORT}"
    )
    # Skip all three digits, keep none.
    ILIB_SHORT="$(echo $ILIB_BASE | sed -e 's/\(.*\)[.][[:digit:]]*[.][[:digit:]]*[.][[:digit:]]*/\1/')"
    (
      cd "${APP_PREFIX}/bin"
      rm --force "${ILIB_SHORT}"
      ln -sv "${ILIB_BASE}" "${ILIB_SHORT}"
    )
  else
    ILIB=$(find ${LIBS_INSTALL_FOLDER_PATH}/lib* -type f -name ${dll_name}'.so.*' -print | egrep '.so.[[:digit:]]+.[[:digit:]]+$')
    if [ ! -z "${ILIB}" ]
    then
      echo "Found user ${ILIB}, 2 digits"

      ihead=$(echo "${ILIB}" | head -n 1)
      # Add "runpath" in library with value $ORIGIN.
      patch_linux_elf_origin "${ihead}"

      /usr/bin/install -v -c -m 644 "${ihead}" "${APP_PREFIX}/bin"

      ILIB_BASE="$(basename ${ihead})"
      # Skip last 1 digit, keep one.
      ILIB_SHORT="$(echo $ILIB_BASE | sed -e 's/\(.*\)[.][[:digit:]]*/\1/')"
      (
        cd "${APP_PREFIX}/bin"
        rm --force "${ILIB_SHORT}"
        ln -sv "${ILIB_BASE}" "${ILIB_SHORT}"
      )
      # Skip all two digits, keep none.
      ILIB_SHORT="$(echo $ILIB_BASE | sed -e 's/\(.*\)[.][[:digit:]]*[.][[:digit:]]*/\1/')"
      (
        cd "${APP_PREFIX}/bin"
        rm --force "${ILIB_SHORT}"
        ln -sv "${ILIB_BASE}" "${ILIB_SHORT}"
      )
    else
      ILIB=$(find ${LIBS_INSTALL_FOLDER_PATH}/lib* -type f -name ${dll_name}'.so.*' -print | egrep '.so.[[:digit:]]+$')
      if [ ! -z "${ILIB}" ]
      then
        echo "Found user ${ILIB}, 1 digit"
        ihead=$(echo "${ILIB}" | head -n 1)
        /usr/bin/install -v -c -m 644 "${ihead}" "${APP_PREFIX}/bin"

        ILIB_BASE="$(basename ${ihead})"
        # Skip final digit, keep none.
        ILIB_SHORT="$(echo $ILIB_BASE | sed -e 's/\(.*\)[.][[:digit:]]*/\1/')"
        echo "${ILIB_SHORT}"
        (
          cd "${APP_PREFIX}/bin"
          rm --force "${ILIB_SHORT}"
          ln -sv "${ILIB_BASE}" "${ILIB_SHORT}"
        )
      else
        ILIB=$(find ${LIBS_INSTALL_FOLDER_PATH}/lib* -type f -name ${dll_name}'.so' -print)
        if [ ! -z "${ILIB}" ]
        then
          echo "Found user ${ILIB}, no digits"
          ihead=$(echo "${ILIB}" | head -n 1)
          patch_linux_elf_origin "${ihead}"
          /usr/bin/install -v -c -m 644 "${ihead}" "${APP_PREFIX}/bin"
        else
          echo ${dll_name} not found
          exit 1
        fi
      fi
    fi
  fi
}

function copy_linux_system_so()
{
  local dll_name="$1"

  set +e
  local ILIB=$(find ${XBB_FOLDER}/lib* /lib* -type f -name ${dll_name}'.so.*' -print | egrep '.so.[[:digit:]]+.[[:digit:]]+.[[:digit:]]+$')
  if [ ! -z "${ILIB}" ]
  then
    echo "Found system ${ILIB}, 3 digits"
    ihead=$(echo "${ILIB}" | head -n 1)
    /usr/bin/install -v -c -m 644 "${ihead}" "${APP_PREFIX}/bin"

    ILIB_BASE="$(basename ${ihead})"
    # Skip last two digits, keep one.
    ILIB_SHORT="$(echo $ILIB_BASE | sed -e 's/\(.*\)[.][[:digit:]]*[.][[:digit:]]*/\1/')"
    (
      cd "${APP_PREFIX}/bin"
      rm --force "${ILIB_SHORT}"
      ln -sv "${ILIB_BASE}" "${ILIB_SHORT}"
    )
    # Skip all three digits, keep none.
    ILIB_SHORT="$(echo $ILIB_BASE | sed -e 's/\(.*\)[.][[:digit:]]*[.][[:digit:]]*[.][[:digit:]]*/\1/')"
    (
      cd "${APP_PREFIX}/bin"
      rm --force "${ILIB_SHORT}"
      ln -sv "${ILIB_BASE}" "${ILIB_SHORT}"
    )
  else
    ILIB=$(find ${XBB_FOLDER}/lib* /lib* -type f -name ${dll_name}'.so.*' -print | egrep '.so.[[:digit:]]+.[[:digit:]]+$')
    if [ ! -z "${ILIB}" ]
    then
      echo "Found system ${ILIB}, 2 digits"
      ihead=$(echo "${ILIB}" | head -n 1)
      /usr/bin/install -v -c -m 644 "${ihead}" "${APP_PREFIX}/bin"

      ILIB_BASE="$(basename ${ihead})"
      # Skip last 1 digit, keep one.
      ILIB_SHORT="$(echo $ILIB_BASE | sed -e 's/\(.*\)[.][[:digit:]]*/\1/')"
      (
        cd "${APP_PREFIX}/bin"
        rm --force "${ILIB_SHORT}"
        ln -sv "${ILIB_BASE}" "${ILIB_SHORT}"
      )
      # Skip all two digits, keep none.
      ILIB_SHORT="$(echo $ILIB_BASE | sed -e 's/\(.*\)[.][[:digit:]]*[.][[:digit:]]*/\1/')"
      (
        cd "${APP_PREFIX}/bin"
        rm --force "${ILIB_SHORT}"
        ln -sv "${ILIB_BASE}" "${ILIB_SHORT}"
      )
    else
      ILIB=$(find ${XBB_FOLDER}/lib* /lib* -type f -name ${dll_name}'.so.*' -print | egrep '.so.[[:digit:]]+$')
      if [ ! -z "${ILIB}" ]
      then
        echo "Found system ${ILIB}, 1 digit"
        ihead=$(echo "${ILIB}" | head -n 1)
        /usr/bin/install -v -c -m 644 "${ihead}" "${APP_PREFIX}/bin"

        ILIB_BASE="$(basename ${ihead})"
        # Skip final digit, keep none.
        ILIB_SHORT="$(echo $ILIB_BASE | sed -e 's/\(.*\)[.][[:digit:]]*/\1/')"
        echo "${ILIB_SHORT}"
        (
          cd "${APP_PREFIX}/bin"
          rm --force "${ILIB_SHORT}"
          ln -sv "${ILIB_BASE}" "${ILIB_SHORT}"
        )
      else
        ILIB=$(find ${XBB_FOLDER}/lib* /lib* -type f -name ${dll_name}'.so' -print)
        if [ ! -z "${ILIB}" ]
        then
          echo "Found system ${ILIB}, no digits"
          ihead=$(echo "${ILIB}" | head -n 1)
          /usr/bin/install -v -c -m 644 "${ihead}" "${APP_PREFIX}/bin"
        else
          echo ${dll_name} not found
          exit 1
        fi
      fi
    fi
  fi
  set -e
}


# -----------------------------------------------------------------------------

# $1 - absolute path to input folder
# $2 - name of output folder below INSTALL_FOLDER
function copy_license() 
{
  # Iterate all files in a folder and install some of them in the
  # destination folder
  echo
  echo "$2"
  (
    cd "$1"
    for f in *
    do
      if [ -f "$f" ]
      then
        if [[ "$f" =~ AUTHORS.*|NEWS.*|COPYING.*|README.*|LICENSE.*|FAQ.*|DEPENDENCIES.*|THANKS.* ]]
        then
          /usr/bin/install -d -m 0755 \
            "${APP_PREFIX}/${DISTRO_LC_NAME}/licenses/$2"
          /usr/bin/install -v -c -m 644 "$f" \
            "${APP_PREFIX}/${DISTRO_LC_NAME}/licenses/$2"
        fi
      fi
    done
  )
  (
    xbb_activate

    if [ "${TARGET_PLATFORM}" == "win32" ]
    then
      find "${APP_PREFIX}/${DISTRO_LC_NAME}/licenses" \
        -type f \
        -exec unix2dos '{}' ';'
    fi
  )
}

function copy_build_files()
{
  echo
  echo "Copying build files..."

  (
    cd "${WORK_FOLDER_PATH}"/build.git

    mkdir -p patches

    find scripts patches -type d \
      -exec /usr/bin/install -d -m 0755 \
        "${APP_PREFIX}/${DISTRO_LC_NAME}/"'{}' ';'

    find scripts patches -type f \
      -exec /usr/bin/install -v -c -m 644 \
        '{}' "${APP_PREFIX}/${DISTRO_LC_NAME}/"'{}' ';'

    if [ -f CHANGELOG.txt ]
    then
      /usr/bin/install -v -c -m 644 \
          CHANGELOG.txt "${APP_PREFIX}/${DISTRO_LC_NAME}"
    fi
    if [ -f CHANGELOG.md ]
    then
      /usr/bin/install -v -c -m 644 \
          CHANGELOG.md "${APP_PREFIX}/${DISTRO_LC_NAME}"
    fi
  )
}

# -----------------------------------------------------------------------------

# Copy one folder to another
function copy_dir() 
{
  local from_path="$1"
  local to_path="$2"

  set +u
  mkdir -p "${to_path}"

  (cd "${from_path}" && tar cf - .) | (cd "${to_path}" && tar xf -)
  set -u
}

# -----------------------------------------------------------------------------

function create_archive()
{
  (
    xbb_activate

    local distribution_file_version="${RELEASE_VERSION}-${DISTRIBUTION_FILE_DATE}"

    local target_folder_name=${TARGET_FOLDER_NAME}

    if [ "${HAS_NAME_ARCH}" != "y" ]
    then
      # Temporarily use the old file name convention.
      if [ "${TARGET_PLATFORM}" == "win32" ]
      then
        target_folder_name="win${TARGET_BITS}"
      elif [ "${TARGET_PLATFORM}" == "darwin" ]
      then
        target_folder_name="macos"
      elif [ "${TARGET_PLATFORM}" == "linux" ]
      then
        target_folder_name="${CONTAINER_DISTRO_LC_NAME}${TARGET_BITS}"
      fi
    fi

    local distribution_file="${DEPLOY_FOLDER_PATH}/${DISTRO_LC_NAME}-${APP_LC_NAME}-${distribution_file_version}-${target_folder_name}"

    cd "${APP_PREFIX}"
    find . -name '.DS_Store' -exec rm '{}' ';'

    echo
    echo "Creating distribution..."

    mkdir -p "${DEPLOY_FOLDER_PATH}"

    # The folder is temprarily moved into a a more elaborate hierarchy like
    # gnu-mcu-eclipse/app-name/version.
    # After the archive is created, the folders are moved back.
    # The atempt to transform the tar path failes, since symlinks were
    # also transformed, which is bad.
    if [ "${TARGET_PLATFORM}" == "win32" ]
    then

      local distribution_file="${distribution_file}.zip"
      local archive_version_path="${INSTALL_FOLDER_PATH}/archive/${DISTRO_UC_NAME}/${APP_UC_NAME}/${distribution_file_version}"

      echo
      echo "ZIP file: \"${distribution_file}\"."

      rm -rf "${INSTALL_FOLDER_PATH}"/archive
      mkdir -p "${archive_version_path}"
      mv "${APP_PREFIX}"/* "${archive_version_path}"

      cd "${INSTALL_FOLDER_PATH}"/archive
      zip -r9 -q "${distribution_file}" *

      # Put folders back.
      mv "${archive_version_path}"/* "${APP_PREFIX}"

    else

      # Unfortunately on node.js, xz & bz2 require native modules, which
      # proved unsafe, some xz versions failed to compile on node.js v9.x,
      # so use the good old .tgz.
      local distribution_file="${distribution_file}.tgz"
      local archive_version_path="${INSTALL_FOLDER_PATH}/archive/${DISTRO_LC_NAME}/${APP_LC_NAME}/${distribution_file_version}"

      echo "Compressed tarball: \"${distribution_file}\"."

      rm -rf "${INSTALL_FOLDER_PATH}"/archive
      mkdir -p "${archive_version_path}"
      mv -v "${APP_PREFIX}"/* "${archive_version_path}"

      # Without --hard-dereference the hard links may be turned into
      # broken soft links on macOS.
      cd "${INSTALL_FOLDER_PATH}"/archive
      # -J uses xz for compression; best compression ratio.
      # -j uses bz2 for compression; good compression ratio.
      # -z uses gzip for compression; fair compression ratio.
      tar -c -z -f "${distribution_file}" \
        --owner=0 \
        --group=0 \
        --format=posix \
        --hard-dereference \
        *

      # Put folders back.
      mv -v "${archive_version_path}"/* "${APP_PREFIX}"

    fi

    cd "${DEPLOY_FOLDER_PATH}"
    compute_sha shasum -a 256 -p "$(basename ${distribution_file})"
  )
}

# -----------------------------------------------------------------------------

function compute_sha() 
{
  # $1 shasum program
  # $2.. options
  # ${!#} file

  file=${!#}
  sha_file="${file}.sha"
  "$@" >"${sha_file}"
  echo "SHA: $(cat ${sha_file})"
}


# -----------------------------------------------------------------------------

# Default empty definition, if XBB is available, it should
# redefine it.
function xbb_activate()
{
  :
}

# Example, to fix the missing definitions on ARCH.
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

# Make the build use the currently compiled libraries.
# The pkg-config path will no longer include the system paths.
function xbb_activate_this()
{
  export EXTRA_CPPFLAGS+=" -I${LIBS_INSTALL_FOLDER_PATH}/include"
  export EXTRA_LDFLAGS+=" -L${LIBS_INSTALL_FOLDER_PATH}/lib"
  export EXTRA_LDFLAGS_APP+=" -L${LIBS_INSTALL_FOLDER_PATH}/lib"

  if [ "${TARGET_PLATFORM}" == "linux" -a "${TARGET_ARCH}" == "x64" ]
  then
    export PKG_CONFIG_PATH="${LIBS_INSTALL_FOLDER_PATH}/lib64/pkgconfig:${LIBS_INSTALL_FOLDER_PATH}/lib/pkgconfig"
  else
    export PKG_CONFIG_PATH="${LIBS_INSTALL_FOLDER_PATH}/lib/pkgconfig"
  fi
}

# -----------------------------------------------------------------------------
