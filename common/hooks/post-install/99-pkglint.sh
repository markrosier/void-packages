# This hook checks for common issues related to void.

hook() {
	local error=0 filename= rev= libname= conflictPkg= conflictFile=
		conflictRev= found= mapshlibs=$XBPS_COMMONDIR/shlibs

	set +E

	for f in bin sbin lib lib32; do
		if [ -d ${PKGDESTDIR}/${f} ]; then
			msg_red "${pkgver}: /${f} directory is not allowed, use /usr/${f}.\n"
			error=1
		fi
	done
	for f in sys dev home root run var/run tmp usr/lib64 usr/local; do
		if [ -d ${PKGDESTDIR}/${f} ]; then
			msg_red "${pkgver}: /${f} directory is not allowed, remove it!\n"
			error=1
		fi
	done
	if [ $error -gt 0 ]; then
		msg_error "${pkgver}: cannot continue with installation!\n"
	fi

	# Check for missing shlibs and SONAME bumps.
	if [ ! -f "${PKGDESTDIR}/shlib-provides" ]; then
		return 0
	fi

	for filename in `cat ${PKGDESTDIR}/shlib-provides`; do
		rev=${filename#*.so.}
		libname=${filename%.so*}
		_libname=$(echo "$libname"|sed -E 's|\+|\\+|g')
		_pkgname=$(echo "$pkgname"|sed -E 's|\+|\\+|g')
		grep -E "^${_libname}\.so[\.0-9.]*[[:blank:]]+${_pkgname}-[^-]+_[0-9]+$" $mapshlibs | { \
			while read conflictFile conflictPkg; do
				found=1
				conflictRev=${conflictFile#*.so.}
				if [ "$rev" = "$conflictRev" ]; then
					continue
				elif [[ "$rev".* =~ "$conflictRev" ]]; then
					continue
				fi
				msg_red "${pkgver}: SONAME bump detected: ${libname}.so.${conflictRev} -> ${libname}.so.${rev}\n"
				msg_red "${pkgver}: please update common/shlibs with this line: \"${libname}.so.${rev} ${pkgver}\"\n"
				msg_red "${pkgver}: all reverse dependencies should also be revbumped to be rebuilt against ${libname}.so.${rev}:\n"
				for x in $($XBPS_QUERY_XCMD -RX ${pkgname}); do
					msg_red "   ${x}\n"
				done
				msg_error "${pkgver}: cannot continue with installation!\n"
			done
			# Try to match provided shlibs in virtual packages.
			for f in ${provides}; do
				_vpkgname="$($XBPS_UHELPER_CMD getpkgname ${f} 2>/dev/null)"
				_spkgname="$(grep "^${filename}" $mapshlibs | awk '{print $2}')"
				_libpkgname="$($XBPS_UHELPER_CMD getpkgname ${_spkgname} 2>/dev/null)"
				if [ -z "${_spkgname}" -o  -z "${_libpkgname}" ]; then
					continue
				fi
				if [ "${_vpkgname}" = "${_libpkgname}" ]; then
					found=1
					break
				fi
			done;
			if [ -z "$found" ]; then
				msg_error "${pkgver}: ${libname}.so.${rev} not found in common/shlibs. Please add it.\n"
			fi;
		}
	done
}