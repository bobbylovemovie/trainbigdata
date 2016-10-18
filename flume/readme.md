start flume-service

$ sudo service flume-ng-agent restart 

coppy flume.conf to /etc/flume-ng/conf/flume.conf 

start flume agent 

$ sudo flume-ng agent --conf /etc/flume-ng/conf/ --conf-file /etc/flume-ng/conf/flume.conf --name agent -Dflume.root.logger=INFO,console

