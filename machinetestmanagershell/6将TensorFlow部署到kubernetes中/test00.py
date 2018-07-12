# -*- coding=utf-8 -*-

import tensorflow as tf
import numpy as np

train_X = np.random.rand(100).astype(np.float32)
train_Y = train_X * 0.1 + 0.3

# 选择变量存储位置和op执行位置，这里全部放在worker的第一个task上
print "1111111"
with tf.device("/job:worker/task:0"):
    print "222222"
    X = tf.placeholder(tf.float32)
    Y = tf.placeholder(tf.float32)
    w = tf.Variable(0.0, name="weight")
    b = tf.Variable(0.0, name="reminder")
    y = w * X + b
    loss = tf.reduce_mean(tf.square(y - Y))

    init_op = tf.global_variables_initializer()
    train_op = tf.train.GradientDescentOptimizer(0.01).minimize(loss)

# 选择创建session使用的master
print "111119999911"
with tf.Session("grpc://192.168.61.3:2222") as sess:
    print "14441"
    sess.run(init_op)
    print "111115555"
    for i in range(50):
        print "15555"
        sess.run(train_op, feed_dict={X: train_Y, Y: train_Y})
        print "166665555"
        if i % 5 == 0:
            print i, sess.run(w), sess.run(b)

    print sess.run(w)
    print sess.run(b)