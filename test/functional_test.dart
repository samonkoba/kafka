library kafka.test.functional;

import 'package:test/test.dart';
import 'package:kafka/kafka.dart';
import 'setup.dart';

void main() {
  group('Functional', () {
    KafkaClient _client;
    String _topicName = 'dartKafkaTest';
    ConsumerGroup _group;

    setUp(() async {
      var host = await getDefaultHost();
      _client = new KafkaClient([new KafkaHost(host, 9092)]);
      _group = new ConsumerGroup(_client, 'functionalTestGroup');
    });

    tearDown(() async {
      await _client.close();
    });

    test('it can produce 6000 messages', () async {
      var result;
      for (var i = 0; i < 2000; i++) {
        var producer = new Producer(_client, 1, 100);
        producer.addMessages(_topicName, 0, [new Message('msg1'.codeUnits)]);
        producer.addMessages(_topicName, 1, [new Message('msg2'.codeUnits)]);
        producer.addMessages(_topicName, 2, [new Message('msg3'.codeUnits)]);
        result = await producer.send();
        expect(result.hasErrors, isFalse);
      }

      Map<int, int> offsets = result.offsets[_topicName];
      var commitOffsets = new List();
      for (var p in offsets.keys) {
        commitOffsets.add(new ConsumerOffset(p, offsets[p] - 2002, 'metadata'));
      }
      _group.commitOffsets({_topicName: commitOffsets}, 0, '');
    }, timeout: new Timeout(new Duration(minutes: 1)));

    test('it can consume 6000 messages', () async {
      var topics = {
        _topicName: [0, 1, 2]
      };
      var consumer = new Consumer(_client, _group, topics, 100, 1);
      var i = 0;
      await for (MessageEnvelope envelope in consumer.consume(limit: 6000)) {
        i++;
        envelope.ack('');
      }
      expect(i, 6000);
    }, timeout: new Timeout(new Duration(minutes: 1)));
  });
}
