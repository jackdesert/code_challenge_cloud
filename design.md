PROBLEM STATEMENT
-----------------

Assume that you’ve been given access to the logs for one of the Top 5 websites in the world (e.g. Google), and that user IDs have been embedded in the logs by the web servers. Thus, the log format is as follows:

[2013-05-04 01:03:31] WEB WORKER GET /hello-world (75.23.54.234) (User ID: 6)

The Problem

Design a system that does the following things:

Updates a data store (of your choosing) with the number of unique visitors per hour.

Updates a data store (of your choosing) with unique user IDs who returned more than once in a day.

Delivers a daily report on the above.

The system that you design should be able to efficiently ingest a day’s worth of log entries (e.g. billions of records daily)

GETTING STARTED
---------------

First some estimates on how much data we are dealing with:

  ## How many visitors

    10 billion / day

  ## Approximately how many will be unique

    20% of the hits will be unique hits

  ## How big (in bytes) is a single hit in the log file

    87 bytes / hit (based on the example format, with 9 extra bytes to account for userids to range from 0 to 2 billion)

  ## How fast can a single processor process a single line

    10,000 hits / second (Based roughly on how fast the algorithm for creating the spending report churned through those CSV files)

  ## How many processors required to process one days worth in one day (realtime)

    11.5 or more processors
    (based on  (10 billion hits/day) / ((10,000 hits/sec) * (3600 sec/hr) * 24 hrs/day))


SYSTEM PIECES
-------------

## Controller

A ruby process that tells a parser to process a single log file, checks when that process has completed, and starts another parser on the next file. This controller starts 14 processes at a time.

## Parsers

The parsers, each working independently on different log files (assuming there are many log files from a single day, not just one huge one). 

The parsers have three key-value stores that they access. 

1. BY_HOUR
The data structure could look like:

BY_HOUR = {
  'hour_0' => { 'id_6', 
          'id_21', 
          'id_13'}
  'hour_1' => { 'id_16', 
          'id_2', 
          'id_1'}
  'hour_2' => { 'id_32', 
          'id_42', 
          'id_1'}
  ...
}

For each hit, the id gets shoved into the appropriate hour.

2. BY_DAY

Rather than have to read the data from BY_HOUR later to process it into BY_DAY, we will store the information while we have the hit in memory. 

BY_DAY = {
  'id_6' => 1,
  'id_21' => 1, 
  'id_13' => 1,
  'id_16' => 1,
  'id_2' => 1,
  'id_32' => 1,
  'id_1' => 2}

3. DAILY_REPEATS

If key is already present in BY_DAY, it constitutes a repeat customer, so it will also be added to the DAILY_REPEATS key-value store. 

DAILY_REPEATS = {
  'id_1' => true}


Choosing a Key-Value Store
--------------------------

How much data will be in the three stores? That depends on what percentage of hits are unique per hour and unique per day. Assuming that 20% are unique by day and 15% are unique by hour, our 10 billion hits will require the following number of keys per data store:

BY_HOUR: 1.5 billion keys
BY_DAY: 2.0 billion keys
DAILY_REPEATS: 2.0 billion keys

How much data is stored per key?

Approximately 12 bytes for the key string (up to 'id_10000000000'). And an average of one byte for the value. 

How much data total in the key-value stores?

71.5 billion bytes (approx 70 GB)
(13 bytes/key) * (1.5 + 2.0 + 2.0) billion 

So between the three stores, there could easily be 70 GB of data. This data is not normalized, but by not normalizing it we save read time later. And it is possible there may be more data than that, depending on what percentage of visitors are unique. Therefore I have chosen a drive-based (as opposed to an in-memory) key value store. 

Cassandra
---------

Cassandra was chosen to be the key-value store because it writes fast. A cluster of three is recommended to maintain high-availability. And it will run on two SSDs--a small one (128GB is fine) for the  CommitLogDirectory (unwritten data) and a larger one (512 GB) for the DataFileDirectories (written data). 

With a three-node cassandra cluster using 3 of the server cores, that leaves 13 to run parsers.


Final Reporting (Done after all log files are processed and loaded into the key-value stores)
---------------------------------------------------------------------------------------------

To find how many unique users per hour, you just need a count of how many keys there are in BY_HOUR['hour_0'], how many in BY_HOUR['hour_1'], etc.

To find which users visited twice or more in one day, you just need to print all the keys of DAILY_REPEATS.


Server Hardware
---------------

This is meant to be run on a single 16-core server with a 128GB SSD, a 512GB SSD, and a 2TB HDD for storage. Since all the data can be processed on a single machine, this has meant there was no need to figure in network latency when talking to the database servers. With three cassandra nodes, the controller is meant to fire up 13 parsers at a time to make use of all the processors.









