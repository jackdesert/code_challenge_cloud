PROBLEM STATEMENT
-----------------

Assume that you’ve been given access to the logs for one of the Top 5 websites in the world (e.g. Google), and that user IDs have been embedded in the logs by the web servers. Thus, the log format is as follows:

[2013-05-04 01:03:31] WEB WORKER GET /hello-world (75.23.54.234) (User ID: 6)

The Problem
-----------

Design a system that does the following things:

  * Updates a data store (of your choosing) with the number of unique visitors per hour.
  * Updates a data store (of your choosing) with unique user IDs who returned more than once in a day.
  * Delivers a daily report on the above.
  * The system that you design should be able to efficiently ingest a day’s worth of log entries (e.g. billions of records daily)


GETTING STARTED
---------------

First some estimates on how much data we are dealing with:

  ## How many visitors are we expecting?

    10 billion / day

  ## Approximately how many will be unique

    20% of the hits will be unique hits (clearly an assumption)

  ## How big (in bytes) is a single hit in the log file

    87 bytes / hit (based on the example format, with 9 extra bytes to account for userids to range from 0 to 2 billion)

  ## How fast can a single processor process a single line

    10,000 hits / second (An estimate, based roughly on how fast the LineItem algorithm from programming_exercise/ processed a line of CSV text)

  ## How many processors required to process one days worth in one day (realtime)

    11.5 or more processors
    (based on  (10 billion hits/day) / ((10,000 hits/sec) * (3600 sec/hr) * 24 hrs/day))


SYSTEM DIAGRAM
--------------

There is system diagram located in this repository at design_exercise/system_diagram.jpg



SYSTEM PIECES
-------------

## Controller

A ruby process that tells a parser to process a single log file, checks when that process has completed, and starts another parser on the next file. This controller starts 14 parsers at a time.

## Parsers

The parsers are also Ruby scripts, being assigned a log file to parse by the controller. Each parser works independently on its own assigned log file (assuming there are many log files from a single day, not just one huge one). 

The parsers have three key-value stores that they access. 


KEY-VALUE STORES AND DATA FLOW
------------------------------

1. BY_HOUR

The data structure could look like:

    BY_HOUR = {
      'hour_0' => { 'id_6' => true, 
              'id_21' => true, 
              'id_13' => true}
      'hour_1' => { 'id_16' => true, 
              'id_21' => true, 
              'id_1' => true}
      'hour_2' => { 'id_32' => true, 
              'id_21' => true, 
              'id_1' => true}
      ...
    }

For each website hit, the user id gets shoved into the appropriate hour.

2. BY_DAY

To save time in compiling the data later, the parser also saves the id as a key in BY_DAY while it has the website hit in memory. 

The data structure could look like this:

    BY_DAY = {
      'id_6' => 1,
      'id_21' => 2, 
      'id_13' => 1,
      'id_16' => 1,
      'id_32' => 1,
      'id_1' => 2}

3. DAILY_REPEATS

If key is already present in BY_DAY, it constitutes a repeat customer, so it will also be added to the DAILY_REPEATS key-value store. 

The data structure could look like this:

    DAILY_REPEATS = {
      'id_1' => true,
      'id_21' => true
    }


DATA FLOW SUMMARY
-----------------

To summarize the data flow, the controller assigns a particular log file to a parser, and for each website hit in that logfile the parser does the following:

  * Writes the user_id as a ken in BY_HOUR with a value of true.
  * Checks if there is a key matching the user_id in BY_DAY. If so, its value is incremented. If not, the user id is inserted as a key, with a value set to 1.
  * If in the last step the operation was an increment instead of an insert, also writes the user_id written as a key in DAILY_REPEATS with a value of true.

After all website hits are procesed as outlined above, the controller does the following to create the output report:

  * To find how many unique users per hour, just count how many keys there are in BY_HOUR['hour_0'], how many in BY_HOUR['hour_1'], etc.. 
  * To find which users visited twice or more in one day, just print all the keys in DAILY_REPEATS.


CHOOSING A KEY_VALUE STORE
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

So between the three stores, there could easily be 70 GB of data on a single node of the key-value store. Note that this data is not normalized, but by not normalizing it we save extra processing time later. And it is possible there may be more data than that, depending on what percentage of visitors are unique. Therefore I have chosen a drive-based (as opposed to an in-memory) key value store. 

CASSANDRA
---------

Cassandra was chosen to be the key-value store because it writes fast. A cluster of three is recommended to maintain high-availability. And it will run on two SSDs--a small one (128GB) for the  CommitLogDirectory (unwritten data) and a larger one (512 GB) for the DataFileDirectories (written data). 

With a three-node cassandra cluster using 3 of the server cores, that leaves 13 to run parsers.


SERVER HARDWARE
---------------

This is meant to be run on a single 16-core server.

  * cores: 16
  * RAM: 32GB (Cassandra runs faster the more memory it has)
  * 128GB SSD (for cassandra CommitLogDirectory)
  * 512GB SSD (for cassandra DataFileDirectories)
  * 2TB HDD (holds the operating system and the log files)

Since all the data can be processed on a single machine, network latency is kept to a minimum. With three processor cores occupied by the cassandra nodes, the controller is meant to launch up to 13 parsers at a time to make use of the remaining processing power.


CONCERNS WITH THIS DESIGN
-------------------------

Network Ports:
Generally a single cassandra node is installed on its own box, or virtual box, so configuration may be tricky figuring out which ports each one should access.

Drives:
While Cassandra can do a lot of its work in-memory if ample memory is provided (note the 32GB in the spec), it will still be dependent on the storage drives as its backend. SSDs have been provided to speed the seek time for randomly located data. However, it may be more efficient yet if each cassandra node actualy worked from a separate SSD instead of having to share.

Available Cores:
A single node of cassandra is aptly able to take advantage of multiple cores. Yet in this design I have allotted each node only a single core. While the design as presented does optimize network latency by putting everything on the same box, the system might run faster (even with the added network latency) if each cassandra node were moved to a different machine with several cores at its disposal. And if the cassandra nodes are being moved to different physical machines, there is no requirement for even the parsers to share the same machine, provided each parser has local access to the files it will be parsing. Spreading out the parsers to different machines as such would mean less load on the disk I/O of each machine, which may also speed things up.








