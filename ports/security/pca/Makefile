# $OpenBSD$
#
COMMENT 	= personal certificate authority
VERSION  	= 1.4
DISTNAME	= pca-${VERSION}
CATEGORIES	= security
HOMEPAGE	= https://github.com/mgraves00/pca
MAINTAINER	= Michael Graves <mg@brainfat.net>

# BSD 2 Clause
PERMIT_PACKAGE = Yes

GH_ACCOUNT 	= mgraves00
GH_PROJECT 	= pca
GH_TAGNAME 	= v${VERSION}

NO_BUILD	= Yes
NO_TEST		= Yes

do-install:
	${INSTALL_SCRIPT} ${WRKSRC}/pca ${PREFIX}/bin/
	${INSTALL_MAN} ${WRKSRC}/pca.1 ${PREFIX}/man/man1/

.include <bsd.port.mk>

