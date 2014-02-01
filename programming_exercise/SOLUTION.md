Programming Solution
====================

Setup
-----

The files are apparently organized by day---that is, a single file is for a single day.

Running the Code
----------------

  ruby programming_challenge/process.rb <file>

This code was developed using Ruby 2.0.0.


Algorithms Used
---------------

## Cost Tagging
To create a map of how much money was spent on each associated tag (where the tag categories were Application, Cluster, DataType, Environment, Name, Node, Role, and Service), an associative array (depth: 2) was used. 

The file was read in using the CSV library (which now includes the additions from FasterCSV). A single line at a time is processed. In LineItem#load the values from the line are stored as instance variables in the instance 'item'. Then in LineItem#save_to_class, each dollar_value that is of interest is added to the appropriate bin in the associative arrays LineItem.values and LineItem.instance_types, which are both class instance variables of the class LineItem.


## Unique EC2 Instance Types
To count the unique types of EC2 instances, a similar approach of saving the string value of the EC2 type as the key in an associative array.


### Time Complexity
The average time complexity is O(n), meaning a file with twice as many lines will take twice as much time to process.
The worst-case time complexity is also O(n), as the number of operations per line in the csv file is constant, even in the case of all tag values being unique.


### Space Complexity
The average space complexity is O(1), since a longer csv file will not necessarily require any additional storage. 
The worst-case space complexity is O(n). In the case of hosting costs, this occurs when each tag value is unique and thus requires a new key, value pair in LineItem.values. In the case of counting the unique types of EC2 instances, worst-case occurs when each EC2 instance is of a different type. 

### Optimization
Obviously, both of these problems were solved using an algorithm that optimized for space. Given that we do not know exactly how large these files may become (it was suggested that they may by many Gigabytes), it did not make sense to use any algorithm that required the entire data set to be stored in memory all at the same time. To do so could have run the machine out of memory. The speed that we give up by optimizing for space is only lost in how fast we can access data from the input file given that we can only accept it one line at a time, and that speed is largely dependent on the implementation of I/O buffering by the CSV library. 

### Multi Threaded Possibilities
Assuming that several of these files are available for processing at the same time, the workload can be spread among different processor cores either by starting a new instance 















