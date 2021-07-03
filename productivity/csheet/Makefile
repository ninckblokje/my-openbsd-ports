# $OpenBSD: Makefile,v 1.4 2020/09/18 08:26:07 paco Exp $

COMMENT =		Tool written for printing cheat sheets from Markdown

MASTER_SITES = 		https://github.com/ninckblokje/csheet/archive/

GH_ACCOUNT =		ninckblokje
GH_PROJECT =		csheet
VERSION =		1.9
GH_TAGNAME =		${VERSION}
DISTNAME =              csheet-${VERSION}
PKGNAME =               csheet-${VERSION}

CATEGORIES =		productivity

# BSD
PERMIT_PACKAGE =	Yes

MODULES =		lang/go

MODGO_MODNAME =		csheet
MODGO_VERSION =         ${VERSION}
MODGO_MODULES =         github.com/atotto/clipboard v0.1.4
MODGO_MODFILES =        github.com/atotto/clipboard v0.1.4
MODGO_LDFLAGS += \
	-X main.csheetVersion=${VERSION} \
        -X main.csheetRevision=PORTS

WANTLIB +=              c pthread

WRKSRC = 		${WRKDIR}/${PKGNAME}

ALL_TARGET =		github.com/ninckblokje/csheet

do-install:
	${INSTALL_PROGRAM} ${MODGO_WORKSPACE}/bin/csheet ${PREFIX}/bin/csheet
	${INSTALL_MAN} ${WRKSRC}/docs/csheet.1 ${PREFIX}/man/man1/csheet.1

.include <bsd.port.mk>
