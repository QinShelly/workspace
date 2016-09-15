[Scapy install guide](http://doc.scrapy.org/en/latest/intro/install.html)

## 安装pip的方法 ##
Install pip and virtualenv for Ubuntu 10.10 Maverick and newer
 
    $ sudo apt-get install python-pip python-dev build-essential 
    $ sudo pip install --upgrade pip 
    $ sudo pip install --upgrade virtualenv 

For older versions of Ubuntu

    sudo python get-pip.py

## Install Scrapy ##
    sudo pip install scrapy

for pyasn1 error

    sudo pip install pyasn1 --upgrade

## Install Homebrew ##
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

prompted to install Xcode command tool

This error can be resolved by OS X installation section
> cannot import name xmlrpc_client


## Run Scrapy ##
without project

    scrapy runspider myspider.py


with project
    
    scrapy crawl meizitu

## Python path ##
/Library/Python/2.7/site-packages/scrapy/commands/bench.py

/usr/local/lib/python2.7/site-packages/requests-2.9.1-py2.7.egg
