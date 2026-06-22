#include <QtTest>

#include "packet.h"

class PacketTest : public QObject
{
    Q_OBJECT

private slots:
    void crc16MatchesKnownVector();
    void sendPacketFramesShortPayload();
    void processDataReassemblesFragmentedPacket();
    void processDataDecodesBackToBackFrames();
    void processDataSkipsNoiseAndBadCrc();
    void processDataRecoversAfterBadCrcAcrossCalls();
    void processDataRecoversAfterInvalidLengthHeaders();
};

void PacketTest::crc16MatchesKnownVector()
{
    const QByteArray data("123456789");

    QCOMPARE(Packet::crc16(reinterpret_cast<const unsigned char *>(data.constData()),
                           static_cast<unsigned int>(data.size())),
             static_cast<unsigned short>(0x31C3));
}

void PacketTest::sendPacketFramesShortPayload()
{
    Packet packet;
    QByteArray framed;

    connect(&packet, &Packet::dataToSend, this, [&framed](QByteArray &data) {
        framed = data;
    });

    const QByteArray payload("abc");
    packet.sendPacket(payload);

    const unsigned short crc = Packet::crc16(
                reinterpret_cast<const unsigned char *>(payload.constData()),
                static_cast<unsigned int>(payload.size()));

    QByteArray expected;
    expected.append(char(2));
    expected.append(char(payload.size()));
    expected.append(payload);
    expected.append(char(crc >> 8));
    expected.append(char(crc & 0xFF));
    expected.append(char(3));

    QCOMPARE(framed, expected);
}

void PacketTest::processDataReassemblesFragmentedPacket()
{
    Packet encoder;
    Packet decoder;
    QByteArray framed;
    QList<QByteArray> received;

    connect(&encoder, &Packet::dataToSend, this, [&framed](QByteArray &data) {
        framed = data;
    });
    connect(&decoder, &Packet::packetReceived, this, [&received](QByteArray &packet) {
        received.append(packet);
    });

    const QByteArray payload("microev-payload");
    encoder.sendPacket(payload);

    decoder.processData(framed.left(3));
    QVERIFY(received.isEmpty());

    decoder.processData(framed.mid(3, 5));
    QVERIFY(received.isEmpty());

    decoder.processData(framed.mid(8));
    QCOMPARE(received.size(), 1);
    QCOMPARE(received.first(), payload);
}

void PacketTest::processDataDecodesBackToBackFrames()
{
    Packet encoder;
    Packet decoder;
    QByteArray framed;
    QList<QByteArray> received;
    QList<QByteArray> payloads;
    payloads.append(QByteArray("first"));
    payloads.append(QByteArray(300, 'x'));
    payloads.append(QByteArray::fromHex("02030400ff"));

    connect(&encoder, &Packet::dataToSend, this, [&framed](QByteArray &data) {
        framed.append(data);
    });
    connect(&decoder, &Packet::packetReceived, this, [&received](QByteArray &packet) {
        received.append(packet);
    });

    for (const QByteArray &payload : payloads) {
        encoder.sendPacket(payload);
    }

    const QList<int> chunkSizes = {1, 2, 7, 31, 128};
    int offset = 0;
    int chunkIndex = 0;
    while (offset < framed.size()) {
        const int chunkSize = qMin(chunkSizes.at(chunkIndex % chunkSizes.size()),
                                   framed.size() - offset);
        decoder.processData(framed.mid(offset, chunkSize));
        offset += chunkSize;
        chunkIndex++;
    }

    QCOMPARE(received, payloads);
}

void PacketTest::processDataSkipsNoiseAndBadCrc()
{
    Packet encoder;
    Packet decoder;
    QByteArray framed;
    QList<QByteArray> received;

    connect(&encoder, &Packet::dataToSend, this, [&framed](QByteArray &data) {
        framed = data;
    });
    connect(&decoder, &Packet::packetReceived, this, [&received](QByteArray &packet) {
        received.append(packet);
    });

    const QByteArray payload("valid-payload");
    encoder.sendPacket(payload);

    QByteArray broken = framed;
    broken[broken.size() - 3] = char(broken.at(broken.size() - 3) ^ 0x01);

    QByteArray stream;
    stream.append(char(0x55));
    stream.append(char(0x66));
    stream.append(broken);
    stream.append(char(0x77));
    stream.append(framed);

    decoder.processData(stream);

    QCOMPARE(received.size(), 1);
    QCOMPARE(received.first(), payload);
}

void PacketTest::processDataRecoversAfterBadCrcAcrossCalls()
{
    Packet encoder;
    Packet decoder;
    QByteArray framed;
    QList<QByteArray> received;

    connect(&encoder, &Packet::dataToSend, this, [&framed](QByteArray &data) {
        framed = data;
    });
    connect(&decoder, &Packet::packetReceived, this, [&received](QByteArray &packet) {
        received.append(packet);
    });

    const QByteArray payload("valid-after-bad-crc");
    encoder.sendPacket(payload);

    QByteArray broken = framed;
    broken[broken.size() - 3] = char(broken.at(broken.size() - 3) ^ 0x01);

    decoder.processData(broken);
    QVERIFY(received.isEmpty());

    decoder.processData(framed);
    QCOMPARE(received.size(), 1);
    QCOMPARE(received.first(), payload);
}

void PacketTest::processDataRecoversAfterInvalidLengthHeaders()
{
    Packet encoder;
    Packet decoder;
    QByteArray framed;
    QList<QByteArray> received;

    connect(&encoder, &Packet::dataToSend, this, [&framed](QByteArray &data) {
        framed = data;
    });
    connect(&decoder, &Packet::packetReceived, this, [&received](QByteArray &packet) {
        received.append(packet);
    });

    const QByteArray payload("valid-after-invalid-length");
    encoder.sendPacket(payload);

    QByteArray invalidHeaders;
    invalidHeaders.append(char(2));
    invalidHeaders.append(char(0));       // Zero-length frame.
    invalidHeaders.append(char(3));
    invalidHeaders.append(char(0));
    invalidHeaders.append(char(1));       // Non-canonical 16-bit length.
    invalidHeaders.append(char(3));
    invalidHeaders.append(char(0x27));
    invalidHeaders.append(char(0x11));    // 10001, above mMaxPacketLen.

    decoder.processData(invalidHeaders);
    QVERIFY(received.isEmpty());

    decoder.processData(framed);
    QCOMPARE(received.size(), 1);
    QCOMPARE(received.first(), payload);
}

QTEST_MAIN(PacketTest)

#include "tst_packet.moc"
