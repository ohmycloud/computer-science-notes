= 使用 Python 发送 protobuf 数据到 Kafka

```bash
pip install protobuf==3.1.0
pip install protobuf==3.20.0

# Windows
protoc iot-proto\src\main\resources\mqtt.proto --python_out=iot-proto\src\main\python

# Linux
protoc iot-proto/src/main/resources/mqtt.proto --python_out=iot-proto/src/main/python
```

脚本如下:

```python
import re
import mqtt_pb2
from mqtt_pb2 import Mqtt

path = r'data.log'
with open(path) as f:
    for line in f.readlines():
        if "inclusion" in line:
            array = line.split(':[', 1)
            topic = re.split("\s+", array[0])[2]
            value = array[1]
            print(f"[{value}")
```

如果报出下面的错误, 则说明安装的 protobuf 版本和 protoc 的版本不兼容。要降 protobuf 的版本:

```
If this call came from a _pb2.py file, your generated code is out of date and must be regenerated with protoc >= 3.19.0.
If you cannot immediately regenerate your protos, some other possible workarounds are:
 1. Downgrade the protobuf package to 3.20.x or lower.
 2. Set PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=python (but this will use pure-Python parsing and will be much slower).
```

从 .gz 文件中读取文本, 解析为 protobuf Message, 转发到 Kafka。 

```python
from kafka import KafkaProducer
from kafka import KafkaConsumer
from mqtt_pb2 import Mqtt
from datetime import datetime
from kafka.errors import KafkaError
import mqtt_pb2
import click
import gzip
import time
import json

class CustomKafkaProducer():
    def __init__(self, bootstrap_servers, topic):
        self.topic = topic
        self.producer = KafkaProducer(bootstrap_servers = bootstrap_servers)

    def send_data(self, value):
        try:
            producer = self.producer
            producer.send(self.topic, value=value)
            producer.flush()
        except KafkaError as e:
            print (e)

def parse_json_str(json_str) -> dict:
    dict = {}
    server_time, json_data = json_str.split('  ')
    topic, payload = json_data.split(':[{')
    dict['server_time'] = int(time.mktime(datetime.strptime(server_time, "%Y-%m-%d %H:%M:%S.%f").timetuple())) * 1000
    dict['topic'] = topic
    dict['payload'] = "[{" + payload
    dict['client_id'] = 'client_test'

    return dict

@click.command()
@click.option('--input-path', default='test.gz', help='input file name')
@click.option('--topic', default='test', help='topic name')
@click.option('--group-id', default='group_test', help='consumer group id')
@click.option('--bootstrap-servers', type=list, default=['127.0.0.1'], help='bootstrap_servers')
def test(input_path, topic, group_id, bootstrap_servers):
  sender = CustomKafkaProducer(bootstrap_servers=bootstrap_servers, topic=topic)
  consumer = KafkaConsumer(topic, group_id=group_id, bootstrap_servers=bootstrap_servers)

  with gzip.open(input_path) as f:
    for line in f:
        line = line.decode('utf-8').strip()
        if not 'inclusion' in line:
            continue        
        dict = parse_json_str(line)
        cm = mqtt_pb2.Mqtt()
        cm.client_id = dict['client_id']
        cm.topic = dict['topic']
        cm.payload = json.dumps( {'topic': dict['topic'], 'value': dict['payload']})
        cm.server_time = dict['server_time']
        print(cm)
        sender.send_data(cm.SerializeToString())

  for msg in consumer:
    cmm = mqtt_pb2.Mqtt()
    cmm.ParseFromString(msg.value)
    print(cmm)
    print('------------------------------------------------')

if __name__ == '__main__':
  test()
```
