# Maintainer: Jose Riha <jose 1711 gmail com>
# Contributor: Dominika Solarz <dominikasolarz@gmail.com>
# Contributor: J!PRA

pkgname=openlierox
pkgver=0.60
pkgrel=5
pkgdesc="An extremely addictive realtime worms shoot-em-up backed by an active gamers community"
arch=(i686 x86_64)
license=("GPL")
url="http://openlierox.sourceforge.net/"
depends=("sdl2" "sdl2_mixer" "sdl2_image" "gd" "zlib" "libxml2" "libzip" "freealut")
makedepends=("gendesk" "cmake" "git")
source=("git+https://github.com/LaPingvino/openlierox.git#tag=${pkgver}"
        "options.cfg"
        "OpenLieroX.png")
md5sums=('SKIP'
         '04d00deb6521b3fbcdba6e9546ae67cf'
         'f2aec85a3ad86a6cf7d1362f31b38e51')

pkgver() {
  cd "$srcdir/$pkgname"
  git describe --tags --always | sed 's/^v//;s/-/./g'
}

prepare() {
  cd "$srcdir/$pkgname"
  gendesk -f -n --pkgname OpenLieroX --pkgdesc "${pkgdesc}" --exec "openlierox" --categories "Game;Shooter;ActionGame"
}

build() {
  cd "$srcdir/$pkgname"
  if [ -d bd ]
  then
    rm -rf bd
  fi

  mkdir bd && cd bd
  cmake -DSYSTEM_DATA_DIR=/usr/share \
        -DDEBUG=ON  \
        ..
  make
}

package() {
  cd "$srcdir/$pkgname"
  install -Dm755 bd/bin/openlierox "$pkgdir/usr/bin/openlierox"
  install -dm755 "$pkgdir/usr/share/OpenLieroX"
  cp -r share/gamedir/* "$pkgdir/usr/share/OpenLieroX/"
  find "${pkgdir}/usr/share/OpenLieroX" -type d -print0 | xargs -0 -- chmod 755
  find "${pkgdir}/usr/share/OpenLieroX" -type f -print0 | xargs -0 -- chmod 644
  install -Dm644 OpenLieroX.desktop "${pkgdir}/usr/share/applications/OpenLieroX.desktop"
  install -Dm644 "${srcdir}/OpenLieroX.png" "${pkgdir}/usr/share/pixmaps/OpenLieroX.png"
  install -Dm644 "${srcdir}/options.cfg" "${pkgdir}/usr/share/OpenLieroX/cfg/options.cfg"
}
