---
layout: post
title: What does it mean to be ANSI SQL Compliance
categories:
- post,sql,spark,trino
---

Recently we run into a situation that needs to find a way to create hive view that works both in Spark and [Trino](https://trino.io/docs/current/connector/hive.html#hive-views)
where we need to filter on a partition field which is a date field in string format.

## Date format in Spark & Trino

[Spark SQL date and timestamp functions](https://spark.apache.org/docs/latest/sql-ref-functions-builtin.html#date-and-timestamp-functions)

- `date_format(timestamp, fmt)`
- `to_date(date_str[, fmt])`
- `to_timestamp(timestamp_str[, fmt])`

[Trino Date and time functions and operators](https://trino.io/docs/current/functions/datetime.html)

- `format_datetime(timestamp, format) → varchar`
- `parse_datetime(string, format) → timestamp with time zone`
- `date_format(timestamp, format) → varchar`
- `date_parse(string, format)`

the most annoying fact is both have `date_format`, but the representation of the format are different which simply result in silent error.

## ANSI SQL compliance

- Spark is ANSI SQL compliant, see [Evolution of the Sql Language at Databricks: Ansi Standard by Default and Easier Migrations from Data Warehouses](https://databricks.com/blog/2021/11/16/evolution-of-the-sql-language-at-databricks-a[…]rd-by-default-and-easier-migrations-from-data-warehouses.html)
- Trino is also ANSI SQL compliant, see [Trino is an ANSI SQL compliant query engine](https://trino.io/docs/current/language.html)

so what does it mean to be sql compliant?

> The ANSI SQL standards specify qualifiers and formats for character
> representations of DATETIME and INTERVAL values. The standard qualifier for a
> DATETIME value is YEAR TO SECOND, and the standard format is as follows:
> YYYY-MM-DD HH:MM:SS
>
> The standards for an INTERVAL value specify the following two classes of
> intervals: The YEAR TO MONTH class has the format: YYYY-MM A subset of this
> format is also valid: for example, just a month interval.
>
> The DAY TO FRACTION class has the format: DD HH:MM:SS.F Any subset of
> contiguous fields is also valid: for example, MINUTE TO FRACTION.

https://www.ibm.com/docs/en/informix-servers/12.10?topic=types-ansi-sql-standards-datetime-interval-values


the standard is actually about the conversion between the types, see [Chapter 8 – Temporal values](https://crate.io/docs/sql-99/en/latest//chapters/08.html).

so the most portable way to convert between string and TIMESTAMP is actually CAST. for example, below query works in both Spark and Trino.

```
-- date to string

SELECT cast(CURRENT_DATE AS varchar(10));

-- string to date

SELECT cast('2022-10-17' AS date);
```

## Reference

- https://docs.databricks.com/spark/latest/spark-sql/language-manual/sql-ref-ansi-compliance.html#cast
- http://joda-time.sourceforge.net/apidocs/org/joda/time/format/DateTimeFormat.html
- https://spark.apache.org/docs/latest/sql-ref-datetime-pattern.html
- https://dev.mysql.com/doc/refman/8.0/en/date-and-time-functions.html#function_date-format
- https://dev.mysql.com/doc/refman/8.0/en/date-and-time-functions.html#function_str-to-date
