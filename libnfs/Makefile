CFLAGS     = -O2
INCLUDE    = -I/usr/include
LIBS       = -L/usr/lib -lnfs
PYVER = 2.7

all: _libnfs.so

libnfs_wrap.c: libnfs.i
	swig -python -shadow libnfs.i

libnfs_wrap.o: libnfs_wrap.c
	${CC} -c ${CFLAGS} -fPIC ${INCLUDE} $$(python${PYVER}-config --cflags) libnfs_wrap.c

_libnfs.so: libnfs_wrap.o
	${CC} libnfs_wrap.o -shared $$(python${PYVER}-config --ldflags) -o _libnfs.so ${LIBS}

clean:
	rm -f *.o *.so *.pyc libnfs_wrap.c libnfs.py
