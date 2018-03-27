# S3::Client

It is a simple AWS S3 library for Ruby

## Installation

```
$ gem install s3-client
```

## Usage

### Generate Client

Set access key ID and secret access key, and generate client.

```
S3::Client.new(<access_key_id>, <secret_access_key>, <Option>)
```

### About Parameters

In addition to the access key ID and secret access key, the options shown in the table below can be set.

|Name|Required|Type|Default|Overview|
|:---|:---|:---|:---|:---|
|access_key_id|yes|String||AccessKeyId|
|secret_access_key|yes|String||SecretAccessKey|
|endpoint|no|String|https://s3.ap-northeast-1.amazonaws.com|[Amazon S3 Resion](https://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region)|
|location|no|String|ap-northeast-1|[Amazon S3 Region](https://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region)|
|force_path_style|no|String|false|"true" generates and accesses URL in path format. "false" creates and accesses a virtual host type URL.|
|debug|no|Boolean|false|show verbose|

### Sample

```
require 's3/client'

access_key_id = ENV['AWS_ACCESS_KEY_ID']
secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
options = {
  debug: true
}

client = S3::Client.new(access_key_id, secret_access_key, options)
```

### Error Response

In case of errors caused by API, an exception (S3::Client::APIFailure) occurs.
The following information is stored in S3::Client::APIFailure.

|Name|Overview|
|:---|:---|
|message|API runtime information|
|api_code|Error code|
|api_message|Error message|
|api_status|Error status|
|api_request_id|Request ID on error|
|api_resource|Path information on error|


In addition, other error responses are as follows.

|Name|Overview|
|:---|:---|
|ParameterInvalid|Invalid parameter was set|
|APIOptionInvalid|Invalid API option set|


### Detail of Function

#### Get bucket list

```
client.buckets.each do |bucket|
  puts bucket.name
  #=> bucket1
  #=> bucket2
end
```

### Get bucket

Gets the specified bucket.

```
# Select bucket
bucket = client.buckets['bucket']

puts bucket.name
#=> bucket
```

### Create bucket

```
bucket = client.buckets.create('bucket')

puts bucket.name
#=> bucket
```

It can also be created by the following method.

```
bucket = client.create_bucket('bucket')

puts bucket.name
#=> bucket
```

### Delete bucket

```
bucket = client.buckets['bucket']

bucket.delete

```

It can also be deleted by the following method.


```
client.delete_bucket('bucket')

```

### Get object list


```
bucket = client.buckets['bucket']

bucket.objects.each do |object|
  puts object.name
  #=> object1/
  #=> object1/test1
  #=> object2/
end

# It is possible to search by specifying a prefix
bucket.objects.where(prefix: 'object1').each do |object|
  puts object.name
  #=> object1/
  #=> object1/test1
end
```

Example when delimiter is specified

```
# Data existing on S3
# /foo/photo/2009/index.html
# /foo/photo/2009/12/index.html
# /foo/photo/2010/index.html
# /foo/photo/2010/xmas.jpg
# /foo/photo/2010/01/index.html
# /foo/photo/2010/01/xmas.jpg
# /foo/photo/2010/02/index.html

bucket = client.buckets['bucket']

bucket.objects.where(prefix: '/foo/photo/2010/', delimiter: '/').each do |object|
  puts object.name
  #=> /foo/photo/2010/index.html
  #=> /foo/photo/2010/xmas.jpg
end
```

You can narrow down the objects by setting the following parameters of the where method.


|Parameter|Required|Type|Default|Overview|
|:---|:---|:---|:---|:---|
|prefix|no|String||String for filtering with forward match|
|delimiter|no|String||Object hierarchy delimiter|

### Get object

```
bucket = client.buckets['bucket']

object = bucket.objects['object1/test.gz']

puts object.name
#=> object1/test.gz

puts object.read
#=> "abcdefg"

# Read 3 bytes of data from object
puts object.read(0..2)
#=> "abc"
```

### Create object

```
bucket = client.buckets['bucket']

object = bucket.objects['object1/test.json']

# String
object.write('testobject')

# Path
object.write(Pathname.new('./object_1.json'))
```

Multi-part upload is supported by passing options.

```
bucket = client.buckets['bucket']

object = bucket.objects['object1/test.json']

object.write(Pathname.new('./object_1.json'), multipart: true, jobs: 10, splitsz: 10_000_000)
```

When using multipart upload, you can specify the following options:


|Parameter|Required|Type|Default|Overview|
|:---|:---|:---|:---|:---|
|multipart|no|Boolean|false|Enable multipart upload|
|jobs|no|String|1|Number of parallel uploads|
|splitsz|no|Integer|104857600|Split size of the object. Please specify 5 MB or more.|

### Delete object

```
bucket = client.buckets['bucket']

object = bucket.objects['object1/test.json']

object.delete
```

It can also be deleted by the following method.


```
client.delete_object('bucket', 'object_1/test.json')
```