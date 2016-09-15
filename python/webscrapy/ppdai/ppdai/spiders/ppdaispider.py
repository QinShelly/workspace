# -*- coding: utf-8 -*-
import scrapy
import re
import ppdai.config
from scrapy.contrib.spiders.init import InitSpider
from scrapy.selector import HtmlXPathSelector
from scrapy.http import Request, FormRequest
from ppdai.items import PpdaiItem
import sqlite3

#inherit from InitSpider for authentication
class PpdaispiderSpider(InitSpider):
    name = "ppdaispider"
    # have to visit login otherwise cannot see sex, age, etc
    login_page = 'https://ac.ppdai.com/User/Login'
    allowed_domains = ["ppdai.com"]
    start_urls = (
        'http://invest.ppdai.com/loan/list_riskmiddle',
        # 'http://invest.ppdai.com/loan/list_riskmiddle_s4_p2?Rate=18&DidIBid=on',
    )

    def init_request(self):
        """This function is called before crawling starts."""
        return Request(url=self.login_page, callback=self.login)

    def login(self, response):
        """Generate a login request."""
        return FormRequest.from_response(response,
                                             formdata={'UserName': ppdai.config.accounts['username']
                                             , 'Password': ppdai.config.accounts['password']},
                                         callback=self.check_login_response)

    def check_login_response(self, response):
        """Check the response returned by a login request to see if we are
        successfully logged in.
        """
        # print response.body
        if "密码错误" in response.body:
            self.log("Bad times :(")
            # Something went wrong, we couldn't log in, so nothing happens.
        else:
            self.log("Successfully logged in. Let's start crawling!")
            # Now the crawling can begin..
            return self.initialized()

    def parse(self, response):
        conn = sqlite3.connect('example.db')

        visited_link = []

        for row in conn.execute("select id from ppdai"):
            visited_link.append(row[0])

        conn.close()
        """go through link in list of riskmiddle page"""
        for link in response.xpath("//div[@class='w230 listtitle']/a/@href").extract():
            if link in visited_link:
                self.log("link %s is visited before" % link)
            else:
                self.log("link %s is new link to be scraped!!!!!" % link)
                request = scrapy.Request(link, callback=self.parse_item)
                yield request

        # to test a specific page
        # link = 'http://invest.ppdai.com/loan/info?id=15711524'
        # request = scrapy.Request(link, callback=self.parse_item)
        # yield request

        pages = response.xpath("//a[@class='nextpage']/@href").extract()
        print('next page: %s' % pages)
        if len(pages) >= 1:
            page_link = pages[0]
            page_link = page_link.replace('/a/', '')
            request = scrapy.Request('http://invest.ppdai.com/%s' % page_link, callback=self.parse)
            yield request

    def parse_item(self, response):
        item = PpdaiItem()
        item["id"] = response.url
        rank = response.xpath("//div[@class='newLendDetailInfoLeft']/a[@class='altQust']/span/@class").extract()
        item["rank"] = rank[0].replace('creditRating', '')
        item["title"] = response.xpath("//div[@class='newLendDetailbox']/h3/span/text()").extract()
        item["brate"] = map(unicode.strip,response.xpath("//div[@class='newLendDetailMoneyLeft']/dl[2]/dd/text()").extract())
        item["qty"] = response.xpath("//div[@class='newLendDetailMoneyLeft']/dl[1]/dd/text()").extract()[0].replace(u',', '')
        item["limitTime"] = response.xpath("//div[@class='newLendDetailMoneyLeft']/dl[@class='nobdr']/dd/text()").extract()
        # 借款人相关信息
        item["purpose"] = ""
        purpose = response.xpath("//table[@class='lendDetailTab_tabContent_table1'][1]/tr[2]/td[1]/text()").extract()
        if purpose:
            item["purpose"] = purpose[0]
        item["sex"] = response.xpath("//table[@class='lendDetailTab_tabContent_table1'][1]/tr[2]/td[2]/text()").extract()
        item["age"] = response.xpath("//table[@class='lendDetailTab_tabContent_table1'][1]/tr[2]/td[3]/text()").extract()
        item["marriage"] = response.xpath("//table[@class='lendDetailTab_tabContent_table1'][1]/tr[2]/td[4]/text()").extract()
        item["education"] = response.xpath("//table[@class='lendDetailTab_tabContent_table1'][1]/tr[2]/td[5]/text()").extract()
        item["house"] = map(unicode.strip,response.xpath("//table[@class='lendDetailTab_tabContent_table1'][1]/tr[2]/td[6]/text()").extract())
        item["car"] = map(unicode.strip,response.xpath("//table[@class='lendDetailTab_tabContent_table1'][1]/tr[2]/td[7]/text()").extract())

        # 学历认证
        item["school"] = ""
        item["study_level"] = ""
        item["study_format"] = ""
        education_cert = response.xpath(
                u"//div[@class='lendDetailTab_tabContent']/p[contains(text(),'学历认证：')]/text()").extract()
        if education_cert:
            t = education_cert[0]
            m = re.match(u"学历认证：（毕业学校：([^，]*)，", t)
            if m:
                item["school"] = m.group(1)

            m = re.match(u".*学历：([^，]*)，", t)
            if m:
                item["study_level"] = m.group(1)

            m = re.match(u".*学习形式：([^，]*)）", t)
            if m:
                item["study_format"] = m.group(1)

        # 户口
        item["hukou"] = ""
        hukou = response.xpath(
                u"//div[@class='lendDetailTab_tabContent']/p[contains(text(),'户口所在地：')]/text()").extract()
        if hukou:
            item["hukou"] = hukou[0]

        # 借款详情
        item["detail"] = ""
        detail = response.xpath(
                u"//div[@class='lendDetailTab_tabContent']/h3[contains(text(),'借款详情')]/following-sibling::p/text()").extract()
        if detail:
            if not u'拍拍贷将以客观' in detail[0]:
                item["detail"] = detail[0]

        # 审核
        item["audit"] = ""
        audit = response.xpath(
                u"//div[@class='lendDetailTab_tabContent']/h3[contains(text(),'拍拍贷审核信息')]/following-sibling::table[@class='lendDetailTab_tabContent_table1']").extract()
        if audit:
            item["audit"] = audit[0]

        # 拍拍贷统计信息
        item["pay_clear"] = ""
        item["over1_15"] = ""
        item["over15plus"] = ""
        history = response.xpath(
                u"//div[@class='lendDetailTab_tabContent']/h3[contains(text(),'拍拍贷统计信息')]/following-sibling::p[contains(text(),'正常还清：')]/text()").extract()
        if history:
            t = history[0]
            m = re.match(u".*正常还清：(\d+).*次，", t)
            if m:
                item["pay_clear"] = m.group(1)

            m = re.match(u".*逾期还清\(1-15\)：(\d+).*次，", t)
            if m:
                item["over1_15"] = m.group(1)

            m = re.match(u".*逾期还清\(>15\)：(\d+).*次", t)
            if m:
                item["over15plus"] = m.group(1)

        item["total_borrow"] = ""
        total_borrow = response.xpath(
                u"//div[@class='lendDetailTab_tabContent']/h3[contains(text(),'拍拍贷统计信息')]/following-sibling::p[contains(text(),'共计借入：')]/span[1]/text()").extract()
        if total_borrow:
            item["total_borrow"] = total_borrow[0].replace(u'¥', '').replace(u',', '')

        item["to_pay"] = ""
        to_pay = response.xpath(
           u"//div[@class='lendDetailTab_tabContent']/h3[contains(text(),'拍拍贷统计信息')]/following-sibling::p[contains(text(),'共计借入：')]/span[2]/text()").extract()
        if to_pay:
            item["to_pay"] = to_pay[0].replace(u'¥', '').replace(u',', '')

        item["to_receive"] = ""
        to_receive = map(unicode.strip,response.xpath(
           u"//div[@class='lendDetailTab_tabContent']/h3[contains(text(),'拍拍贷统计信息')]/following-sibling::p[contains(text(),'共计借入：')]/span[3]/text()").extract())
        if to_receive:
            item["to_receive"] = to_receive[0].replace(u'¥', '').replace(u',', '')

        yield item
