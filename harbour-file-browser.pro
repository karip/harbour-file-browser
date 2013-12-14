TEMPLATE = subdirs
SUBDIRS = src

# ordered makes sure projects are built in the order specified in SUBDIRS.
# Usually it makes sense to build tests only if main component can be built
CONFIG += ordered
