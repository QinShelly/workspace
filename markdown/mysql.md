# mysql

## install 
1. sudo apt-get install mysql-server
 
　　2. apt-get install mysql-client
 
　　3.  sudo apt-get install libmysqlclient-dev
　　
## test setup
mysqladmin --version

or 

sudo netstat -tap | grep mysql

## start mysql
mysqld

or

/etc/init.d/mysql start

## connect 
mysql -u root  
mysql -u root -p

ctrl z 退出

## Python MysqlDB module
sudo easy_install mysql-python
