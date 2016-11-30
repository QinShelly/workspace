[Scapy install guide](http://doc.scrapy.org/en/latest/intro/install.html)

# On Linux #
## 安装pip的方法 ##
Install pip and virtualenv for Ubuntu 10.10 Maverick and newer
 
    $ sudo apt-get install python-pip python-dev build-essential 
    $ sudo pip install --upgrade pip 

    $ sudo pip install --upgrade virtualenv 

## Install Scrapy ##
    sudo pip install scrapy

- for pyasn1 error

    sudo pip install pyasn1 --upgrade

## Install Selenium ##
	sudo pip install selenium
Downgrade to 2.53.6 to work with FireFox 28   
	
`sudo pip install selenium==2.53.6`

## Install SQLite ##
	sudo apt-get update.
	sudo apt-get install sqlite3 libsqlite3-dev

## Install git ##
	sudo apt-get install git

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