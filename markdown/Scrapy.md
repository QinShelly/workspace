# PPDai #
- Ubuntu Desktop （for Firefox）
- pip （install other requirement）
- Firefox
- Python
- requests module (selenium_ppdai.py)
- geckodriver
- Selenium 
- Scrapy
- SQLite
- git (to get code)
- JDK （for DBeaver）
- DBeaver （connect SQLite and Mysql）
- Mysql
- MysqlDB （python module to use mysql)

##用Apt-get安装的
pip
 `$ sudo apt-get install python-pip python-dev build-essential `
scrapy的依赖
	`$ sudo apt-get install build-essential libssl-dev libffi-dev python-dev`
	
SQLlite
	sudo apt-get install sqlite3 libsqlite3-dev

Git
	sudo apt-get install git
##用pip安装的
安装scrapy   
`sudo pip install scrapy`
	
- for pyasn1 error

`sudo pip install pyasn1 --upgrade`

# On Ubuntu #

## 安装pip的方法 ##
Install pip and virtualenv for Ubuntu 10.10 Maverick and newer
 
    $ sudo apt-get install python-pip python-dev build-essential 
    $ sudo pip install --upgrade pip 

    $ sudo pip install --upgrade virtualenv 

## Install geckodriver
ubuntu16.04环境下 解决方法：下载 geckodriverckod   地址： [mozilla/geckodriver](https://link.zhihu.com/?target=https%3A//github.com/mozilla/geckodriver/releases)解压后将geckodriverckod 存放至 /usr/local/bin/ 路径下即可
`sudo mv ～/Downloads/geckodriver /usr/local/bin/`


## Install Scrapy 
[官方Scapy install guide](http://doc.scrapy.org/en/latest/intro/install.html)

[安装Scrapy的检查步骤]
(http://wiki.jikexueyuan.com/project/python-crawler-guide/the-configuration-of-scrapy.html)

[安装Cryptograpy的步骤]
(https://cryptography.io/en/latest/installation/)

	$ sudo apt-get install build-essential libssl-dev libffi-dev python-dev

安装scrapy   
`sudo pip install scrapy`

- for pyasn1 error

`sudo pip install pyasn1 --upgrade`

- for cryptograpy error     
install openssl

- for openssl error  
to do 

## Install Selenium ##
	sudo pip install selenium
Selenium 2.53.6 work with FireFox 28   
Selenium 3.0.2 work with Firefox 47.0.1
	
`sudo pip install selenium==2.53.6`

## Install SQLite ##
	sudo apt-get update.
	sudo apt-get install sqlite3 libsqlite3-dev

## Install git ##
	sudo apt-get install git

copy file from util folder.   
config.py to ppdai/ppdai folder. Modify the file.   
example.db to ppdai folder. 

## Install JDK
[百度经验](http://jingyan.baidu.com/article/e2284b2b61a2efe2e6118d39.html)

## Install DBeaver
install SQLite and Mysql driver

## Clone Repository ##
	git clone https://github.com/QinShelly/workspace.git

## Run spider ##
- Get bids  
	./run_ppdai_scrawler
- Bid money  
	python selenium_ppdai.py

# On Mac #
## Install Homebrew ##
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

prompted to install Xcode command tool

This error can be resolved by OS X installation section
> cannot import name xmlrpc_client

## Python path ##
/Library/Python/2.7/site-packages/scrapy/commands/bench.py

/usr/local/lib/python2.7/site-packages/requests-2.9.1-py2.7.egg

## Run Scrapy ##
without project

    scrapy runspider myspider.py

with project
    
    scrapy crawl meizitu
    
# mysql

## install 
1. sudo apt-get install mysql-server
 
2. sudo apt-get install mysql-client
 
3. sudo apt-get install libmysqlclient-dev
　　
## test setup
mysqladmin --version

or 

sudo netstat -tap | grep mysql

## start mysql
(mac)
mysqld 

or
(ubuntu)
/etc/init.d/mysql start

## stop 
/etc/init.d/mysql stop

## connect 
mysql -u root  
mysql -u root -p

ctrl z 退出

## Python MysqlDB module
sudo easy_install mysql-python

pip install MySQL-python