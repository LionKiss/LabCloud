#coding=utf-8

#input_data.py\u7684\u8be6\u89e3
#\u5b66\u4e60\u8bfb\u53d6\u6570\u636e\u6587\u4ef6\u7684\u65b9\u6cd5\uff0c\u4ee5\u4fbf\u8bfb\u53d6\u81ea\u5df1\u9700\u8981\u7684\u6570\u636e\u5e93\u6587\u4ef6\uff08\u4e8c\u8fdb\u5236\u6587\u4ef6\uff09
"""Functions for downloading and reading MNIST data."""
from __future__ import print_function
import gzip
import os
import urllib
import numpy
SOURCE_URL = 'http://yann.lecun.com/exdb/mnist/'
def maybe_download(filename, work_directory):
    """Download the data from Yann's website, unless it's already here."""
    #\u5224\u65ad\u76ee\u5f55\u6587\u4ef6\u662f\u5426\u5b58\u5728\uff0c\u4e0d\u5b58\u5728\u5219\u521b\u5efa\u8be5\u76ee\u5f55
    if not os.path.exists(work_directory):
    os.mkdir(work_directory)
    #\u9700\u8981\u8bfb\u53d6\u7684\u6587\u4ef6\u8def\u5f84
    filepath = os.path.join(work_directory, filename)
    if not os.path.exists(filepath):
        filepath, _ = urllib.urlretrieve(SOURCE_URL + filename, filepath)
        statinfo = os.stat(filepath)
        print('Succesfully downloaded', filename, statinfo.st_size, 'bytes.')
    return filepath

def _read32(bytestream):
    dt = numpy.dtype(numpy.uint32).newbyteorder('>')
    return numpy.frombuffer(bytestream.read(4), dtype=dt)

def extract_images(filename):
    """Extract the images into a 4D uint8 numpy array [index, y, x, depth]."""
    print('Extracting', filename)
    with gzip.open(filename) as bytestream:
    magic = _read32(bytestream)
    if magic != 2051:
        raise ValueError(
            'Invalid magic number %d in MNIST image file: %s' %
            (magic, filename))
    num_images = _read32(bytestream)
    rows = _read32(bytestream)
    cols = _read32(bytestream)
    buf = bytestream.read(rows * cols * num_images)
    data = numpy.frombuffer(buf, dtype=numpy.uint8)
    data = data.reshape(num_images, rows, cols, 1)
    return data
#\u5c06\u7a20\u5bc6\u6807\u7b7e\u5411\u91cf\u53d8\u6210\u7a00\u758f\u7684\u6807\u7b7e\u77e9\u9635
#eg\uff1a\u82e5\u539f\u5411\u91cf\u7684\u7b2ci\u884c\u4e3a3\uff0c\u5219\u5bf9\u5e94\u7a00\u758f\u77e9\u9635\u7684\u7b2ci\u884c\u4e0b\u6807\u4e3a3\u7684\u503c\u4e3a1\uff0c\u5176\u4f59\u4e3a0
def dense_to_one_hot(labels_dense, num_classes=10):
    """Convert class labels from scalars to one-hot vectors."""
    num_labels = labels_dense.shape[0]
    index_offset = numpy.arange(num_labels) * num_classes
    labels_one_hot = numpy.zeros((num_labels, num_classes))
    #labels_dense.ravel()\u5c06\u6574\u4e2a\u6570\u7ec4\u5c55\u6210\u4e00\u4e2a\u4e00\u7ef4\u6570\u7ec4
    #labels_dense.flat[i]\u5373\u5c06labels_dense\u770b\u6210\u4e00\u4e2a\u4e00\u7ef4\u6570\u7ec4\uff0c\u53d6\u5176\u7b2ci\u4e2a\u53d8\u91cf
    labels_one_hot.flat[index_offset + labels_dense.ravel()] = 1#\u62a5\u9519\uff1f
    return labels_one_hot

def extract_labels(filename, one_hot=False):
  """Extract the labels into a 1D uint8 numpy array [index]."""
    print('Extracting', filename)
    with gzip.open(filename) as bytestream:
        magic = _read32(bytestream)
        if magic != 2049:
            raise ValueError(
                'Invalid magic number %d in MNIST label file: %s' %
                (magic, filename))
    num_items = _read32(bytestream)
    buf = bytestream.read(num_items)
    labels = numpy.frombuffer(buf, dtype=numpy.uint8)
    if one_hot:
        return dense_to_one_hot(labels)
    return labels
class DataSet(object):
    def __init__(self, images, labels, fake_data=False):
        if fake_data:
            self._num_examples = 10000
        else:
            assert images.shape[0] == labels.shape[0], (
            "images.shape: %s labels.shape: %s" % (images.shape,
                                                 labels.shape))
            self._num_examples = images.shape[0]
            # Convert shape from [num examples, rows, columns, depth]
            # to [num examples, rows*columns] (assuming depth == 1)

            assert images.shape[3] == 1
            images = images.reshape(images.shape[0],
                              images.shape[1] * images.shape[2])
            # Convert from [0, 255] -> [0.0, 1.0].
            images = images.astype(numpy.float32)
            images = numpy.multiply(images, 1.0 / 255.0)
        self._images = images
        self._labels = labels
        self._epochs_completed = 0
        self._index_in_epoch = 0
    @property
    def images(self):
        return self._images
    @property
    def labels(self):
        return self._labels
    @property
    def num_examples(self):
        return self._num_examples
    @property
    def epochs_completed(self):
        return self._epochs_completed
def next_batch(self, batch_size, fake_data=False):
    """Return the next `batch_size` examples from this data set."""
    if fake_data:
        fake_image = [1.0 for _ in xrange(784)]
        fake_label = 0
        return [fake_image for _ in xrange(batch_size)], [fake_label for _ in xrange(batch_size)]
    start = self._index_in_epoch
    self._index_in_epoch += batch_size
    #\u82e5\u5f53\u524d\u8bad\u7ec3\u8bfb\u53d6\u7684index>\u603b\u4f53\u7684images\u6570\u65f6\uff0c\u5219\u8bfb\u53d6\u8bfb\u53d6\u5f00\u59cb\u7684batch_size\u5927\u5c0f\u7684\u6570\u636e
    if self._index_in_epoch > self._num_examples:
        # Finished epoch
        self._epochs_completed += 1
        # Shuffle the data
        perm = numpy.arange(self._num_examples)
        numpy.random.shuffle(perm)
        self._images = self._images[perm]
        self._labels = self._labels[perm]
        # Start next epoch
        start = 0
        self._index_in_epoch = batch_size
        assert batch_size <= self._num_examples
    end = self._index_in_epoch
    return self._images[start:end], self._labels[start:end]
def read_data_sets(train_dir, fake_data=False, one_hot=False):
    class DataSets(object):
        pass
    data_sets = DataSets()
    if fake_data:
        data_sets.train = DataSet([], [], fake_data=True)
        data_sets.validation = DataSet([], [], fake_data=True)
        data_sets.test = DataSet([], [], fake_data=True)
        return data_sets
    TRAIN_IMAGES = 'train-images-idx3-ubyte.gz'
    TRAIN_LABELS = 'train-labels-idx1-ubyte.gz'
    TEST_IMAGES = 't10k-images-idx3-ubyte.gz'
    TEST_LABELS = 't10k-labels-idx1-ubyte.gz'
    VALIDATION_SIZE = 5000
    local_file = maybe_download(TRAIN_IMAGES, train_dir)
    train_images = extract_images(local_file)
    local_file = maybe_download(TRAIN_LABELS, train_dir)
    train_labels = extract_labels(local_file, one_hot=one_hot)
    local_file = maybe_download(TEST_IMAGES, train_dir)
    test_images = extract_images(local_file)
    local_file = maybe_download(TEST_LABELS, train_dir)
    test_labels = extract_labels(local_file, one_hot=one_hot)
    validation_images = train_images[:VALIDATION_SIZE]
    validation_labels = train_labels[:VALIDATION_SIZE]
    train_images = train_images[VALIDATION_SIZE:]
    train_labels = train_labels[VALIDATION_SIZE:]
    data_sets.train = DataSet(train_images, train_labels)
    data_sets.validation = DataSet(validation_images, validation_labels)
    data_sets.test = DataSet(test_images, test_labels)
    return data_sets