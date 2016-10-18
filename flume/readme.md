start flume-service \n
$ sudo service flume-ng-agent <start | stop | restart> \n
coppy flume.conf to /etc/flume-ng/conf/flume.conf \n
start flume agent \n
$ sudo flume-ng agent --conf /etc/flume-ng/conf/ --conf-file /etc/flume-ng/conf/flume.conf --name agent -Dflume.root.logger=INFO,console

