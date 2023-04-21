# 过滤器

## StartRow 和 EndROw

```bash
scan 'car_data_en_rt', {STARTROW => '2280001J02S1PHWML_9223370466217975807', ENDROW => '2280001J02S1PHWML_9223370466304375807'}
```

## row key 过滤

```bash
scan 'latest_na_test', FILTER => "RowFilter(=,'binary:2320001H02S1JAGML')"
```

## substring 过滤器

```bash
scan 'can_signal_test', {FILTER => RowFilter.new(CompareFilter::CompareOp.valueOf('EQUAL'), SubstringComparator.new('_20170810101300'))}
```

## 正则表达式过滤器

```bash
import org.apache.hadoop.hbase.filter.RegexStringComparator
import org.apache.hadoop.hbase.filter.CompareFilter
import org.apache.hadoop.hbase.filter.SubstringComparator
import org.apache.hadoop.hbase.filter.RowFilter

scan 'can_signal_test', {FILTER => RowFilter.new(CompareFilter::CompareOp.valueOf('GREATER_OR_EQUAL'),RegexStringComparator.new('^\w+_201708101100072\d+$'))}
```

## ROWPREFIXFILTER

```bash
scan 'car_data_na_rt_test',ROWPREFIXFILTER=>'0000101JX2S1JAGML_9223370479030240807'
get 'car_data_na_rt_test',  '0000101JX2S1JAGML_9223370479030240807'
```

ROWPREFIXFILTER 性能比 PREFILTER 性能好一些。

## FuzzyRowFilter

过滤 Row Key 的需求：根据 Row Key 非开头的部分字符串来匹配

- [how-filter-scan-of-hbase-by-part-of-row-key](https://stackoverflow.com/questions/38896467/how-filter-scan-of-hbase-by-part-of-row-key)
- [FuzzyRowFilter](https://hbase.apache.org/apidocs/org/apache/hadoop/hbase/filter/FuzzyRowFilter.html)
- [fuzzyrowfilter 查询不到数据](https://blog.csdn.net/weixin_39353573/article/details/77894874)

```bash
scan 'trip_signal',  FILTER => org.apache.hadoop.hbase.filter.FuzzyRowFilter.new(Arrays.asList(Pair.new(Bytes.toBytes("???????????????LL_???????????????????"), Bytes.toBytes("\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x00\x00\x00\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01"))))
```

## filterList

```bash
scan 'daytime',  {FILTER => "(PrefixFilter ('840001WJ4804722LL_201808') OR PrefixFilter ('840001WJ4804722LL_201806')"}
scan 'daytime',  {FILTER => "(RowFilter (=,'substring:_201808') OR RowFilter (=, 'substring:_201806')"}
```


## 在代码里面使用过滤器

```scala
import org.apache.hadoop.hbase.client._
import org.apache.hadoop.hbase.io.ImmutableBytesWritable
import org.apache.hadoop.hbase.mapreduce.TableInputFormat
import org.apache.hadoop.hbase.HBaseConfiguration
import org.apache.hadoop.hbase.filter._
import org.apache.hadoop.hbase.protobuf.ProtobufUtil
import org.apache.hadoop.hbase.util.{Base64, Bytes}
import scala.collection.mutable.ArrayBuffer

val scan = new Scan()

// 单个过滤器
val filter=new RowFilter(CompareFilter.CompareOp.GREATER_OR_EQUAL, new RegexStringComparator("^[a-zA-Z0-9]+_20180903[0-9]{6}$"))
scan.setFilter(filter)

// 多个过滤器
for (d <- arrayWeek) {
    filterList.addFilter(new RowFilter(CompareFilter.CompareOp.EQUAL, new SubstringComparator( "_" + d)))
}

scan.setFilter(filterList)
```

## only scan a qualiter column

```bash
scan 'car_data_en_rt', 
     { COLUMNS => 'd:vcu', 
       LIMIT => 10000, 
       STARTROW => '2280001J02S1PHWML_9223370466217975807', 
       ENDROW => '2280001J02S1PHWML_9223370466304375807'
     }
```

```bash
create 'drive_trip_test',{NAME =>'i', COMPRESSION => 'LZ4'},SPLITS => ['0','1', '2', '3', '4','5', '6', '7', '8', '9']
scan "drive_trip_test", {COLUMNS => ['i:second_min_temp_time','i:min_temp_time','i:max_temp_time'], LIMIT  => 20}
scan "charge_trip_test", {COLUMNS => ['i:soc_power','i:start_soc','i:end_soc', 'i:charge_curr_start', 'i:charge_volt_start'], LIMIT  => 20}
```

You can scan multiple columns at a same time using,

```bash
scan 'tablename' , {COLUMNS => ['cf1:cq1' , 'cf2:cq2']}
scan 'driving_trip', {COLUMNS => ['cf:trip_start_time', 'cf:avg_temp'], LIMIT => 1 } 
```

```bash
## 这个命令会扫描以 1_120201020163752884 开头的全部数据， 而不是根据 STARTROW 和 ENDROW 来扫描
scan "pile_data_test", { ROWPREFIXFILTER => "1_120201020163752884",  STARTROW =>"1_120201020163752884_000820", ENDROW => "1_120201020163752884_001000"}
```

## scan and output

```bash
echo "scan 'foo'" | hbase shell > myText
hbase shell < file.sh(which contains hbase commands) > output.lo
# chmod 775 export_hbase.sh
# hbase shell < export_hbase.sh > export_hbase_out.txt
```

## get row key

```bash
get 'car_day_part_engine_torque', '4790001H58S1JAGML_20180826'
```

```bash
scan 'can_signal', {FILTER => RowFilter.new(CompareFilter::CompareOp.valueOf('EQUAL'), SubstringComparator.new('410011WJ3904722LL')), LIMIT => 1}
scan 'latest_pile_data', {FILTER => RowFilter.new(CompareFilter::CompareOp.valueOf('EQUAL'), SubstringComparator.new('_2022070409'))}
```

## 参考链接

- https://stackoverflow.com/questions/10942638/should-i-use-prefixfilter-or-rowkey-range-scan-in-hbase
- https://stackoverflow.com/questions/17558547/hbase-easy-how-to-perform-range-prefix-scan-in-hbase-shell/38632100#38632100
- https://stackoverflow.com/questions/47316393/how-to-get-multiple-columns-using-hbase-shell
- https://stackoverflow.com/questions/17558547/hbase-easy-how-to-perform-range-prefix-scan-in-hbase-shell
- http://hbase.apache.org/0.94/book/thrift.html
- https://stackoverflow.com/questions/33346705/how-to-combine-filters-in-hbase-shell
