import pika
from subprocess import Popen, PIPE
import os

def callback(ch, method, properties, body):
    print " [x] Received %r" % (body,)
    #os.remove('/tmp/hello.txt')
    input_file = open("/tmp/hello.txt", 'w')
    input_file.write(body)
    input_file.close()
    put = Popen(["hadoop", "dfs", "-put", "-", "/user/yarn/hello.txt"],stdin=PIPE, stdout=PIPE)
    #put.wait()
    while True:
        out = proc.stderr.readline()
        if not out:
            break
        print(out)

    # put = Popen(["hadoop", "dfs", "-ls", "/user/yarn/"],stdin=PIPE)

def hdfs_writer(hdfs_ip, hdfs_port, mq_ip):
    connection = pika.BlockingConnection(pika.ConnectionParameters(mq_ip))
    channel = connection.channel()
    channel.queue_declare(queue='test')
    channel.basic_consume(callback, queue='test', no_ack=True)
    print ' [*] Waiting for messages. To exit press CTRL+C'
    channel.start_consuming()


if __name__ == '__main__':
    hdfs_writer('localhost',9000,'localhost')
