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

          # Not yet functional on windows.
          if [ "${TARGET_PLATFORM}" == "win32" ]
          then

            # export PATH_SEPARATOR=";"

            # Without --with-pkg-config-libdir= it'll try to write the .pc files in the
            # xbb folder, probbaly by using the dirname of pkg-config.
            bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${ncurses_src_folder_name}/configure" \
              --prefix="${LIBS_INSTALL_FOLDER_PATH}" \
              \
              --build=${BUILD} \
              --host=${HOST} \
              --target=${TARGET} \
              --with-build-cc=${CC} \
              --with-build-cflags=${CFLAGS} \
              --with-build-cppflags=${CPPFLAGS} \
              --with-build-ldflags=${LDFLAGS} \
              \
              --with-shared \
              --with-normal \
              --with-cxx \
              --with-cxx-binding \
              --with-cxx-shared \
              --with-pkg-config-libdir="${LIBS_INSTALL_FOLDER_PATH}/lib/pkgconfig" \
              --without-ada \
              --without-debug \
              --without-manpage \
              --without-prog \
              \
              --enable-assertions \
              --enable-sp-funcs \
              --enable-term-driver \
              --enable-interop \
              --enable-pc-files \
              --disable-termcap \
              --disable-home-terminfo \

          else

            # Without --with-pkg-config-libdir= it'll try to write the .pc files in the
            # xbb folder, probbaly by using the dirname of pkg-config.
            bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${ncurses_src_folder_name}/configure" \
              --prefix="${LIBS_INSTALL_FOLDER_PATH}" \
              \
              --build=${BUILD} \
              --host=${HOST} \
              --target=${TARGET} \
              \
              --with-shared \
              --with-normal \
              --with-cxx \
              --with-cxx-binding \
              --with-cxx-shared \
              --with-pkg-config-libdir="${LIBS_INSTALL_FOLDER_PATH}/lib/pkgconfig" \
              --with-terminfo-dirs=/etc/terminfo \
              --with-default-terminfo-dir="/etc/terminfo:/lib/terminfo:/usr/share/terminfo" \
              --with-gpm \
              --with-versioned-syms \
              --with-xterm-kbs=del \
              --without-debug \
              --without-ada \
              --without-manpage \
              --without-prog \
              \
              --enable-widec \
              --enable-pc-files \
              --enable-termcap \
              --enable-ext-colors \
              --enable-const \
              --enable-symlinks \
              --enable-overwrite \

          fi

          cp "config.log" "${LOGS_FOLDER_PATH}/config-ncurses-log.txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/configure-ncurses-output.txt"
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

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/make-ncurses-output.txt"

      copy_license \
        "${SOURCES_FOLDER_PATH}/${ncurses_src_folder_name}" \
        "${ncurses_folder_name}"

    )

    touch "${ncurses_stamp_file_path}"

  else
    echo "Library ncurses already installed."
  fi
}
