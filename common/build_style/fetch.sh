# fetch build_style: fetches and copies files to ${wrksrc}.

do_extract() {
	mkdir -p ${wrksrc}
	for f in ${distfiles}; do
		curfile=$(basename "${f#*>}")
		cp ${XBPS_SRCDISTDIR}/${pkgname}-${version}/${curfile} ${wrksrc}/${curfile}
	done
}
