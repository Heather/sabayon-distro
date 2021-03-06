# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

inherit qmake-utils autotools multilib eutils flag-o-matic toolchain-funcs

MY_PN=${PN/-base}
MY_P=${P/-base}
DESCRIPTION="Collection of simple PIN or passphrase entry dialogs which utilize the Assuan protocol"
HOMEPAGE="http://gnupg.org/aegypten2/index.html"
SRC_URI="mirror://gnupg/${MY_PN}/${MY_P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~arm ~amd64 ~x86"
IUSE="gtk qt4 caps static"

RDEPEND="
	app-eselect/eselect-pinentry
	>=dev-libs/libgpg-error-1.17
	>=dev-libs/libassuan-2
	caps? ( sys-libs/libcap )
	sys-libs/ncurses
	static? ( >=sys-libs/ncurses-5.7-r5[static-libs,-gpm] )
"
DEPEND="${RDEPEND}"

S=${WORKDIR}/${MY_P}

DOCS=( AUTHORS ChangeLog NEWS README THANKS TODO )

src_prepare() {
	epatch "${FILESDIR}/${MY_PN}-0.8.2-ncurses.patch"
	eautoreconf
}

src_configure() {
	use static && append-ldflags -static
	[[ "$(gcc-major-version)" -ge 5 ]] && append-cxxflags -std=gnu++11

	econf \
		--enable-pinentry-tty \
		--disable-pinentry-gtk2 \
		--enable-pinentry-curses \
		--enable-fallback-curses \
		--disable-pinentry-qt4 \
		$(use_with caps libcap) \
		--disable-libsecret \
		--disable-pinentry-gnome3
}

src_install() {
	default
	rm -f "${ED}"/usr/bin/pinentry || die
}

pkg_postinst() {
	if ! has_version 'app-crypt/pinentry-base'; then
		# || has_version '<app-crypt/pinentry-0.7.3'; then
		elog "We no longer install pinentry-curses and pinentry-qt SUID root by default."
		elog "Linux kernels >=2.6.9 support memory locking for unprivileged processes."
		elog "The soft resource limit for memory locking specifies the limit an"
		elog "unprivileged process may lock into memory. You can also use POSIX"
		elog "capabilities to allow pinentry to lock memory. To do so activate the caps"
		elog "USE flag and add the CAP_IPC_LOCK capability to the permitted set of"
		elog "your users."
	fi
	eselect pinentry update ifunset
	use gtk && elog "If you want pinentry for Gtk+, please install app-crypt/pinentry-gtk."
	use qt4 && elog "If you want pinentry for Qt4, please install app-crypt/pinentry-qt4."
}

pkg_postrm() {
	eselect pinentry update ifunset
}
