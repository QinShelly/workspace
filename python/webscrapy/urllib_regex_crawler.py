import urllib2
import urllib
import cookielib

#proxy
enable_proxy = False
proxy_handler = urllib2.ProxyHandler({"http" : 'http://some-proxy.com:8080'})
null_proxy_handler = urllib2.ProxyHandler({})

if enable_proxy:
    opener = urllib2.build_opener(proxy_handler)
else:
    opener = urllib2.build_opener(null_proxy_handler)

urllib2.install_opener(opener)

#cookie
filename = 'cookie.txt'
cookie = cookielib.MozillaCookieJar(filename)
handler = urllib2.HTTPCookieProcessor(cookie)
opener = urllib2.build_opener(handler)

#post
user_agent = 'Mozilla/4.0 (compatible; MSIE 5.5; Windows NT)'  
headers = { 'User-Agent' : user_agent } 
postdata = urllib.urlencode({'form_email' : 'keneas0083@hotmail.com',  
'form_password' : '' 
} ) 
 
loginurl = "https://accounts.douban.com/login?source=book"
myurl = "https://book.douban.com/mine?icn=index-nav"

try:
	#first response for login
	response = opener.open(loginurl,postdata)
	cookie.save(ignore_discard=True, ignore_expires=True)

	#this gets actual contents with user context
	response = opener.open(myurl)
	print response.read()
except urllib2.URLError, e:
    print e.code
    print e.reason

#show cookie
# for item in cookie:
#     print 'Name = '+item.name
#     print 'Value = '+item.value

