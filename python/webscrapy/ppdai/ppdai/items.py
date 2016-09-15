# -*- coding: utf-8 -*-

# Define here the models for your scraped items
#
# See documentation in:
# http://doc.scrapy.org/en/latest/topics/items.html

import scrapy

class PpdaiItem(scrapy.Item):
    # define the fields for your item here like:
    rank = scrapy.Field()
    title = scrapy.Field()
    link = scrapy.Field()
    brate = scrapy.Field()
    qty = scrapy.Field()
    limitTime = scrapy.Field()
    id = scrapy.Field()
    purpose = scrapy.Field()
    sex = scrapy.Field()
    age = scrapy.Field()
    marriage = scrapy.Field()
    education = scrapy.Field()
    house = scrapy.Field()
    car = scrapy.Field()
    school = scrapy.Field()
    study_level = scrapy.Field()
    study_format = scrapy.Field()
    detail = scrapy.Field()
    hukou = scrapy.Field()
    audit = scrapy.Field()
    pay_clear = scrapy.Field()
    over1_15 = scrapy.Field()
    over15plus = scrapy.Field()
    total_borrow = scrapy.Field()
    to_pay = scrapy.Field()
    to_receive = scrapy.Field()

