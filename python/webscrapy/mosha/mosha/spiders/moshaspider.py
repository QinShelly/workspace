# -*- coding: utf-8 -*-
import scrapy

from scrapy.spiders import BaseSpider
from scrapy.selector import HtmlXPathSelector
from scrapy.http.request import Request
from mosha.items import MoshaItem

class MoshaspiderSpider(scrapy.Spider):
    name = "moshaspider"
    allowed_domains = ["sqlblog.com"]
    start_urls = (
        'http://sqlblog.com/blogs/mosha/default.aspx',
    )

    def parse(self, response):
        next_page = response.xpath(
            "//div[@class='CommonSinglePager']/a[contains(text(),'Next page')]/@href").extract()
        self.log("next_page: %s" % next_page[0])
        if next_page:
            yield Request("http://sqlblog.com" + next_page[0], self.parse)
		
        for link in response.xpath("//h4[@class='BlogPostHeader']/a/@href").extract():
            self.log("link %s" % link)
            request = scrapy.Request("http://sqlblog.com/" + link, callback=self.parse_item)
            yield request

    def parse_item(self, response):
        item = MoshaItem()
        item["link"] = response.url
        item["title"] = map(unicode.strip,response.xpath("//h1[@class='BlogPostHeader']/text()").extract())
        item["content"] = response.xpath("//div[@class='BlogPostContent']").extract()
        file_path ="blogfiles/%s.htm" % item["title"][0].replace(':','-')
        # self.log("writing files {0}".format(file_path))
        with open(file_path, 'a') as f:
            f.write('{0}\n'.format(
                response.body))
        yield item