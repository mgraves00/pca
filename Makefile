#

VER!=grep -Eo '^VER=.*' pca | cut -f2 -d=
BASENAME=pca
RELNAME=${BASENAME}-${VER}
RELPATH=dist
obsd_port_path=ports/security/pca
FILES= LICENSE \
	   pca \
	   pca.1

_size_fragment=perl -e '$$s=(stat $$ARGV[0])[7]; print "SIZE ($$ARGV[1]) = $$s\n";'

all:
	@echo "targets:"
	@echo "  version - show current version"
	@echo "  ports"
	@echo "  distfile"
	@echo "  regress"


version:
	@echo ${VER}

ports!
	ck="${.CURDIR}/${RELPATH}/${RELNAME}.newdist"; \
	trap "rm -f $$ck; exit 1" 1 2 3 13 15; \
	cd ${.CURDIR}/${RELPATH}; \
	cksum -b -a SHA256 -- ${RELNAME}.tar.gz >> $$ck; \
	${_size_fragment} ${RELNAME}.tar.gz ${RELNAME}.tar.gz >> $$ck; \
	mv -f $$ck ${.CURDIR}/${obsd_port_path}/distinfo
	sed -i 's~^\(VERSION[[:space:]]*=[[:space:]]*\).*~\1${VER}~' ${.CURDIR}/${obsd_port_path}/Makefile
#	-git commit -m "update checksum" ${.CURDIR}/${obsd_port_path}/distinfo

distfile:
	[ -d ${.CURDIR}/${RELPATH}/${RELNAME} ] || mkdir -p ${.CURDIR}/${RELPATH}/${RELNAME}
	for f in ${FILES}; do cp $$f ${.CURDIR}/${RELPATH}/${RELNAME}/$$f; done 
	tar -C ${.CURDIR}/${RELPATH}/ -czf ${.CURDIR}/${RELPATH}/${RELNAME}.tar.gz ${RELNAME}/

regress:
	./regress.sh

