QT += core testlib
QT -= gui

CONFIG += testcase c++11
TEMPLATE = app
TARGET = tst_packet

INCLUDEPATH += ../..

SOURCES += \
    tst_packet.cpp \
    ../../packet.cpp

HEADERS += \
    ../../packet.h
