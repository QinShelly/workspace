## SSH ##

[Adding an SSH key to your Stash account on Windows](https://confluence.atlassian.com/display/STASH028/Adding+an+SSH+key+to+your+Stash+account+on+Windows)

[Adding an SSH key to your Stash account on Linux and Mac](https://confluence.atlassian.com/display/STASH028/Adding+an+SSH+key+to+your+Stash+account+on+Linux+and+Mac)

[Set Github on Ubuntu](http://www.ubuntumanual.org/posts/393/how-to-setup-and-use-github-in-ubuntu)

CD to
C:\Users\<user>\.ssh

$cd ~/.ssh

ssh-keygen -t rsa -C your.name@retailsolutions.com

Open id_rsa.pub, copy content
Add the Stash -- > Manage Account

On Linux, have to run SSH-add to make it work *** Important

For this error message
no matching key exchange method found. their offer diffie-hellman-group1-sha1

Copy the config file to .ssh folder. Config file Content:
Host 10.172.4.66
     KexAlgorithms +diffie-hellman-group1-sha1
