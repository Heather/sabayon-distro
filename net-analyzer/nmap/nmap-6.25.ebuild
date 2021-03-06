# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="4"
PYTHON_DEPEND="2"

inherit eutils flag-o-matic python

MY_P=${P/_beta/BETA}

DESCRIPTION="A utility for network exploration or security auditing"
HOMEPAGE="http://nmap.org/"
SRC_URI="
	http://nmap.org/dist/${MY_P}.tar.bz2
"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm ~x86"

IUSE="gtk ipv6 +lua ncat ndiff nls nmap-update nping ssl"

# not used in split nmap ebuild, but retained for compatibility with Portage
NMAP_LINGUAS="de es fr hr hu id it ja pl pt_BR pt_PT ro ru sk zh"
for lingua in ${NMAP_LINGUAS}; do
	IUSE+=" linguas_${lingua}"
done

NMAP_PYTHON_DEPEND="
|| (
	dev-lang/python:2.7[sqlite]
	dev-lang/python:2.6[sqlite]
	dev-lang/python:2.5[sqlite]
	dev-python/pysqlite:2
)
"
RDEPEND="
	dev-libs/apr
	dev-libs/libpcre
	net-libs/libpcap[ipv6?]
	lua? ( >=dev-lang/lua-5.1.4-r1[deprecated] )
	ndiff? ( ${NMAP_PYTHON_DEPEND} )
	nmap-update? ( dev-libs/apr dev-vcs/subversion )
	ssl? ( dev-libs/openssl )
"
DEPEND="
	${RDEPEND}
"
PDEPEND="gtk? ( ~net-analyzer/zenmap-${PV} )"

S="${WORKDIR}/${MY_P}"

pkg_setup() {
	python_set_active_version 2
}

src_unpack() {
	unpack ${MY_P}.tar.bz2
}

src_prepare() {
	epatch \
		"${FILESDIR}"/${PN}-4.75-include.patch \
		"${FILESDIR}"/${PN}-4.75-nolua.patch \
		"${FILESDIR}"/${PN}-5.10_beta1-string.patch \
		"${FILESDIR}"/${PN}-5.21-python.patch \
		"${FILESDIR}"/${PN}-6.01-make.patch \
		"${FILESDIR}"/${PN}-6.25-lua.patch
	sed -i \
		-e 's/-m 755 -s ncat/-m 755 ncat/' \
		ncat/Makefile.in || die

	mv docs/man-xlate/${PN}-j{p,a}.1 || die
	if false && use nls; then # skipped in split nmap ebuild
		local lingua=''
		for lingua in ${NMAP_LINGUAS}; do
			if ! use linguas_${lingua}; then
				rm -rf zenmap/share/zenmap/locale/${lingua}
				rm -f zenmap/share/zenmap/locale/${lingua}.po
			fi
		done
	else
		# configure/make ignores --disable-nls
		for lingua in ${NMAP_LINGUAS}; do
			rm -rf zenmap/share/zenmap/locale/${lingua}
			rm -f zenmap/share/zenmap/locale/${lingua}.po
		done
	fi

	sed -i \
		-e '/^ALL_LINGUAS =/{s|$| id|g;s|jp|ja|g}' \
		Makefile.in || die

	# Fix desktop files wrt bug #432714
	# not needed in Sabayon's split nmap ebuild
	#sed -i \
	#	-e '/^Encoding/d' \
	#	-e 's|^Categories=.*|Categories=Network;System;Security;|g' \
	#	zenmap/install_scripts/unix/zenmap-root.desktop \
	#	zenmap/install_scripts/unix/zenmap.desktop || die
}

src_configure() {
	# The bundled libdnet is incompatible with the version available in the
	# tree, so we cannot use the system library here.
	econf \
		--without-zenmap \
		$(use_with lua liblua) \
		$(use_with ncat) \
		$(use_with ndiff) \
		$(use_enable nls) \
		$(use_with nmap-update) \
		$(use_with nping) \
		$(use_with ssl openssl) \
		--with-libdnet=included
}

src_install() {
	LC_ALL=C emake -j1 \
		DESTDIR="${D}" \
		STRIP=: \
		nmapdatadir="${EPREFIX}"/usr/share/nmap \
		install
	if use nmap-update;then
		LC_ALL=C emake -j1 \
			-C nmap-update \
			DESTDIR="${D}" \
			STRIP=: \
			nmapdatadir="${EPREFIX}"/usr/share/nmap \
			install
	fi

	dodoc CHANGELOG HACKING docs/README docs/*.txt

	#use gtk && doicon "${DISTDIR}/nmap-logo-64.png"
}
