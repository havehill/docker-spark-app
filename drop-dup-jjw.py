import pyspark
from pyspark import SparkConf, SparkContext
from pyspark.sql import SparkSession
from pyspark.sql.functions import monotonically_increasing_id
from pyspark.sql.window import Window

## 1. 데이터 불러오기 
# conf 설정
sConf = SparkConf()
sConf.set("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem")
sConf.set("spark.hadoop.fs.s3a.access.key", "YOUR_S3A_ACCESS_KEY")
sConf.set("spark.hadoop.fs.s3a.secret.key", "{YOUR_S3A_SECRET_KEY}")
sConf.set("spark.hadoop.fs.s3a.endpoint", "s3.ap-northeast-2.amazonaws.com")

# create SparkSession
spark = SparkSession.builder.appName("drop-dup-test").getOrCreate() #.config(conf=sConf) 
spark.sparkContext.setSystemProperty("com.amazonaws.services.s3.enableV4", "true")

# s3 data 불러오기 - 기준필요
jp = spark.read.json("{YOUR_S3_PATH}")
wt = spark.read.json("{YOUR_S3_PATH}")
# org_df = spark.read.json("s3a://") # 중복제거 완료됐던 데이터


## 2. wt-jp 중복제거 (mid_df)
uni_df = jp.union(wt)
mid_df = uni_df.dropDuplicates(['title','company_name'])
# row id 추가
mid_df = mid_df.withColumn("row_id", monotonically_increasing_id())


## 3. mid_df-org_df 중복제거 (result_df)
# 우선 생략


## 4. write result_df to S3
num_partitons = mid_df.count()
result_df = mid_df.repartition(num_partitons)
s3_output_path = "{YOUR_S3_PATH}" # 경로 변경 필요
result_df.write.json(s3_output_path, mode="overwrite") # 각 행을 하나의 json파일로 따로 저장



