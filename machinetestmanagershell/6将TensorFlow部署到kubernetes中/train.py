# -*- coding=utf-8 -*-

import tensorflow as tf
import numpy as np

# Configuration of cluster 
ps_hosts = [ "192.168.61.5:2222", "192.168.88.4:2222" ]
worker_hosts = [ "192.168.61.6:2222", "192.168.88.5:2222"]
cluster = tf.train.ClusterSpec({"ps": ps_hosts, "worker": worker_hosts})

tf.app.flags.DEFINE_integer("task_index", 0, "Index of task within the job")
FLAGS = tf.app.flags.FLAGS

def main(_):
    with tf.device(tf.train.replica_device_setter(
        worker_device="/job:worker/task:%d" % FLAGS.task_index,
        cluster=cluster)):
        print "1111"
        x_data = tf.placeholder(tf.float32, [100])
        y_data = tf.placeholder(tf.float32, [100])

        W = tf.Variable(tf.random_uniform([1], -1.0, 1.0))
        b = tf.Variable(tf.zeros([1]))
        y = W * x_data + b
        loss = tf.reduce_mean(tf.square(y - y_data))
        
        global_step = tf.Variable(0, name="global_step", trainable=False)
        optimizer = tf.train.GradientDescentOptimizer(0.1)
        train_op = optimizer.minimize(loss, global_step=global_step)
        
        tf.summary.scalar('cost', loss)
        summary_op = tf.summary.merge_all()
        init_op = tf.global_variables_initializer()
        print "2222"
    # The StopAtStepHook handles stopping after running given steps.
    print "3333"
    hooks = [ tf.train.StopAtStepHook(last_step=1000000)]
    print "44444"
    # The MonitoredTrainingSession takes care of session initialization,
    # restoring from a checkpoint, saving to a checkpoint, and closing when done
    # or an error occurs.
    with tf.train.MonitoredTrainingSession(master="grpc://" + worker_hosts[FLAGS.task_index],
                                           is_chief=(FLAGS.task_index==0), # 我们制定task_index为0的任务为主任务，用于负责变量初始化、做checkpoint、保存summary和复原
                                           checkpoint_dir="/tmp/tf_train_logs",
                                           save_checkpoint_secs=None,
                                           hooks=hooks) as mon_sess:
        print "55555"
        while not mon_sess.should_stop():
            print "66666"
            # Run a training step asynchronously.
            # See `tf.train.SyncReplicasOptimizer` for additional details on how to
            # perform *synchronous* training.
            # mon_sess.run handles AbortedError in case of preempted PS.
            train_x = np.random.rand(100).astype(np.float32)
            train_y = train_x * 0.1 + 0.3
            _, step, loss_v, weight, biase = mon_sess.run([train_op, global_step, loss, W, b], feed_dict={x_data: train_x, y_data: train_y})
            if step % 10 == 0:
                print "step: %d, weight: %f, biase: %f, loss: %f" %(step, weight, biase, loss_v)
        print "Optimization finished."

if __name__ == "__main__":
    tf.app.run()
