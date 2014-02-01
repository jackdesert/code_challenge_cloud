Programming Solution
====================

The Challenge
-------------
Using the attached files (which may be many GB in size):

Using any tool, technology, and technique that you find relevant and are comfortable with, develop an app (or apps) that does the following:
  Count the unique types of EC2 instances within the file.
  Generate a report of total cost by day, by tag. (i.e. on March 3rd, Environment = Production cost $100.0)
Bonus points:
  Find instances that changed tags during the month, and the timestamp on which they changed.

With each solution, please include a README file that has the following info.
How to run the application against a file.
Any notes about approach that you think are relevant and tradeoffs you made
in your solution.
For the algorithms you implement, the time and space complexity in Big-O
notation
Which constraint (time v. space) you optimized for and why.
Bonus points:
For the algorithms you implement, the best- and worst-case
runtime complexity and the scenarios under which they occur.



Setup
-----

The files are apparently organized by day---that is, a single file is for a single day. Therefore, there is no requirement to store data for multiple days at a time. 

Running the Code
----------------

  ruby programming_challenge/run.rb <file>

This code was developed using Ruby 2.0.0.


Algorithms Used
---------------

Since both of the requirements require iterating through the entire file, I chose an approach that does both challenges in the same pass-through. 

## Cost by Tag
To create a map of how much money was spent on each associated tag (where the tag categories were Application, Cluster, DataType, Environment, Name, Node, Role, and Service), an associative array (depth: 2) was used. Dollar amounts were saved using a BigDecimal, which adds easily and does not suffer from rounding errors.

First the file was opened using the CSV library (which now includes the additions from FasterCSV), which delivers up the contents of a single line at a time.. A single line at a time is processed. In LineItem#load the values from the line are stored as instance variables in the instance 'item'. Then in LineItem#save_to_class, each dollar_value that is of interest is added to the appropriate bin in the associative arrays LineItem.values and LineItem.instance_types, which are both class instance variables of the class LineItem.


## Unique EC2 Instance Types
To count the unique types of EC2 instances, a similar approach of saving the string value of the EC2 type as the key in an associative array.


### Time Complexity
The average time complexity is O(n), meaning a file with twice as many lines will take twice as much time to process.
The worst-case time complexity is also O(n), as the number of operations per line in the csv file is constant, even in the case where all tag values are unique.


### Space Complexity
The average space complexity is O(1), since a longer csv file will not necessarily require any additional storage. 
The worst-case space complexity is O(n). In the case of hosting costs, this occurs when each tag value is unique and thus requires a new key/value pair in LineItem.values. In the case of counting the unique types of EC2 instances, worst-case occurs when each EC2 instance is of a different type, requiring a new key/value pair in LineItem.instance_types. 

### Optimization
Obviously, both of these problems were solved using an algorithm that optimized for space. Given that we do not know exactly how large these files may become (it was suggested that they may by many Gigabytes), it did not make sense to use any algorithm that required the entire data set to be stored in memory all at the same time. To do so could have run the machine out of memory. The speed that we give up by optimizing for space is only lost in how fast we can access data from the input file, given that we can only accept it one line at a time, and that speed is largely dependent on the implementation of I/O buffering by the CSV library. 












