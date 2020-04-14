# -----------------------------------------------------------------------------
# This file is part of the xPack distribution.
#   (https://xpack.github.io)
# Copyright (c) 2020 Liviu Ionescu.
#
# Permission to use, copy, modify, and/or distribute this software 
# for any purpose is hereby granted, under the terms of the MIT license.
# -----------------------------------------------------------------------------

# Helper script used in the second edition of the xPack build 
# scripts. As the name implies, it should contain only functions and 
# should be included with 'source' by the build scripts (both native
# and container).

# -----------------------------------------------------------------------------

function do_ncurses()
{
  # https://invisible-island.net/ncurses/
  # ftp://ftp.invisible-island.net/pub/ncurses
  # ftp://ftp.invisible-island.net/pub/ncurses/ncurses-6.2.tar.gz

  # depends=(glibc gcc-libs)
  # https://archlinuxarm.org/packages/aarch64/ncurses/files/PKGBUILD
  # http://deb.debian.org/debian/pool/main/n/ncurses/ncurses_6.1+20181013.orig.tar.gz.asc

  # https://github.com/msys2/MINGW-packages/blob/master/mingw-w64-ncurses/PKGBUILD
  # https://github.com/msys2/MINGW-packages/blob/master/mingw-w64-ncurses/001-use-libsystre.patch
  # https://github.com/msys2/MSYS2-packages/blob/master/ncurses/PKGBUILD

  # _4421.c:1364:15: error: expected ‘)’ before ‘int’
  # ../include/curses.h:1906:56: note: in definition of macro ‘mouse_trafo’
  # 1906 | #define mouse_trafo(y,x,to_screen) wmouse_trafo(stdscr,y,x,to_screen)

  # 26 Feb 2011, "5.8" # build fails
  # 27 Jan 2018, "5.9" # build fails
  # 27 Jan 2018, "6.1"
  # 12 Feb 2020, "6.2"

  local ncurses_version="$1"

  # The folder name as resulted after being extracted from the archive.
  local ncurses_src_folder_name="ncurses-${ncurses_version}"
  # The folder name  for build, licenses, etc.
  local ncurses_folder_name="${ncurses_src_folder_name}"

  local ncurses_archive="${ncurses_folder_name}.tar.gz"
  local ncurses_url="ftp://ftp.invisible-island.net//pub/ncurses/${ncurses_archive}"

  local ncurses_version_major="$(echo ${ncurses_version} | sed -e 's|\([0-9][0-9]*\)\.\([0-9][0-9]*\)|\1|')"
  local ncurses_version_minor="$(echo ${ncurses_version} | sed -e 's|\([0-9][0-9]*\)\.\([0-9][0-9]*\)|\2|')"

  local ncurses_stamp_file_path="${INSTALL_FOLDER_PATH}/stamp-ncurses-${ncurses_version}-installed"
  if [ ! -f "${ncurses_stamp_file_path}" ]
  then

    cd "${SOURCES_FOLDER_PATH}"

    download_and_extract "${ncurses_url}" "${ncurses_archive}" \
      "${ncurses_src_folder_name}"

    (
      mkdir -pv "${LIBS_BUILD_FOLDER_PATH}/${ncurses_folder_name}"
      cd "${LIBS_BUILD_FOLDER_PATH}/${ncurses_folder_name}"

      mkdir -pv "${LOGS_FOLDER_PATH}/${ncurses_folder_name}"

      xbb_activate
      xbb_activate_installed_dev

      export CPPFLAGS="${XBB_CPPFLAGS}"
      export CFLAGS="${XBB_CFLAGS}"
      export CXXFLAGS="${XBB_CXXFLAGS}"
      export LDFLAGS="${XBB_LDFLAGS_LIB}"

      if [ ! -f "config.status" ]
      then 
        (
          echo
          echo "Running ncurses configure..."

          bash "${SOURCES_FOLDER_PATH}/${ncurses_src_folder_name}/configure" --help

          config_options=()

          # Not yet functional on windows.
          if [ "${TARGET_PLATFORM}" == "win32" ]
          then

            # The build passes, but generally it is not expected to be
            # used on Windows.

            # export PATH_SEPARATOR=";"

            # --with-libtool \
            # /opt/xbb/bin/libtool: line 10548: gcc-8bs: command not found

            # Without --with-pkg-config-libdir= it'll try to write the .pc files in the
            # xbb folder, probbaly by using the dirname of pkg-config.

            config_options+=("--with-build-cc=${NATIVE_CC}")
            config_options+=("--with-build-cflags=${CFLAGS}")
            config_options+=("--with-build-cppflags=${CPPFLAGS}")
            config_options+=("--with-build-ldflags=${LDFLAGS}")
               
            config_options+=("--without-progs")

            # Only for the MinGW port, it provides a way to substitute
            # the low-level terminfo library with different terminal drivers.
            config_options+=("--enable-term-driver")
            
            config_options+=("--disable-termcap")
            config_options+=("--disable-home-terminfo")
            config_options+=("--disable-db-install")

          else

            # Without --with-pkg-config-libdir= it'll try to write the .pc files in the
            # xbb folder, probbaly by using the dirname of pkg-config.

            config_options+=("--with-terminfo-dirs=/etc/terminfo")
            config_options+=("--with-default-terminfo-dir=/etc/terminfo:/lib/terminfo:/usr/share/terminfo")
            config_options+=("--with-gpm")
            config_options+=("--with-versioned-syms")
            config_options+=("--with-xterm-kbs=del")

            config_options+=("--enable-termcap")
            config_options+=("--enable-const")
            config_options+=("--enable-symlinks")

          fi

          config_options+=("--with-shared")
          config_options+=("--with-normal")
          config_options+=("--with-cxx")
          config_options+=("--with-cxx-binding")
          config_options+=("--with-cxx-shared")
          config_options+=("--with-pkg-config-libdir=${LIBS_INSTALL_FOLDER_PATH}/lib/pkgconfig")
          
          # Fails on Linux, with missing _nc_cur_term, which is there.
          config_options+=("--without-pthread")

          config_options+=("--without-ada")
          config_options+=("--without-debug")
          config_options+=("--without-manpages")
          config_options+=("--without-tack")
          config_options+=("--without-tests")

          config_options+=("--enable-pc-files")
          config_options+=("--enable-sp-funcs")
          config_options+=("--enable-ext-colors")
          config_options+=("--enable-interop")

          config_options+=("--disable-lib-suffixes")
          config_options+=("--disable-overwrite")

          NCURSES_DISABLE_WIDEC=${NCURSES_DISABLE_WIDEC:-""}

          if [ "${NCURSES_DISABLE_WIDEC}" == "y" ]
          then
            config_options+=("--disable-widec")
          fi

          bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${ncurses_src_folder_name}/configure" \
            --prefix="${LIBS_INSTALL_FOLDER_PATH}" \
            \
            --build=${BUILD} \
            --host=${HOST} \
            --target=${TARGET} \
            \
            ${config_options[@]}

          cp "config.log" "${LOGS_FOLDER_PATH}/${ncurses_folder_name}/config-log.txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${ncurses_folder_name}/configure-output.txt"
      fi

      (
        echo
        echo "Running ncurses make..."

        # Build.
        make -j ${JOBS}

        # The test-programs are interactive

        # make install-strip
        make install

        # fool packages looking to link to non-wide-character ncurses libraries
        for lib in ncurses ncurses++ form panel menu; do
          echo "INPUT(-l${lib}w)" > "${LIBS_INSTALL_FOLDER_PATH}/lib/lib${lib}.so"
          rm -f "${LIBS_INSTALL_FOLDER_PATH}/lib/pkgconfig/${lib}.pc"
          ln -s -v ${lib}w.pc "${LIBS_INSTALL_FOLDER_PATH}/lib/pkgconfig/${lib}.pc"
        done

        for lib in tic tinfo; do
          echo "INPUT(libncursesw.so.${ncurses_version_major})" > "${LIBS_INSTALL_FOLDER_PATH}/lib/lib${lib}.so"
          rm -f "${LIBS_INSTALL_FOLDER_PATH}/lib/lib${lib}.so.${ncurses_version_major}"
          ln -s -v libncursesw.so.${ncurses_version_major} "${LIBS_INSTALL_FOLDER_PATH}/lib/lib${lib}.so.${ncurses_version_major}"
          rm -f "${LIBS_INSTALL_FOLDER_PATH}/lib/pkgconfig/${lib}.pc"
          ln -s -v ncursesw.pc "${LIBS_INSTALL_FOLDER_PATH}/lib/pkgconfig/${lib}.pc"
        done

        # some packages look for -lcurses during build
        echo 'INPUT(-lncursesw)' > "${LIBS_INSTALL_FOLDER_PATH}/lib/libcursesw.so"
        rm -f "${LIBS_INSTALL_FOLDER_PATH}/lib/libcurses.so"
        ln -s -v libncurses.so "${LIBS_INSTALL_FOLDER_PATH}/lib/libcurses.so"

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${ncurses_folder_name}/make-output.txt"

      copy_license \
        "${SOURCES_FOLDER_PATH}/${ncurses_src_folder_name}" \
        "${ncurses_folder_name}"

    )

    touch "${ncurses_stamp_file_path}"

  else
    echo "Library ncurses already installed."
  fi
}
