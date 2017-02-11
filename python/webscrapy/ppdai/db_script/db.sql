--drop table ppdai
CREATE TABLE IF NOT EXISTS ppdai
 (id text PRIMARY KEY, ppdai_level text, title text, rate real, amount real, limitTime real, sex text
,purpose text, age real, marriage text, education text, house text, car text
	,school text, education_level text, education_method text, detail text, hukou text
	,certificates_in_str text, cnt_return_on_time real, cnt_return_less_than_15 real, over15plus real, total_borrow text
	, waiting_to_pay text, waiting_to_get_back text, bid integer, insert_dt dt default current_timestamp)

CREATE TABLE IF NOT EXISTS another
 (id text  , star text)

CREATE TABLE IF NOT EXISTS bidProcess
 (id text  , processFlag text, insert_dt dt default current_timestamp
 	update_bid0_dt dt,
 	update_bid1_dt dt)

CREATE TABLE IF NOT EXISTS school_rank
 (wsl_rank real  , school text)

-- from http://news.koolearn.com/20160315/1077611.html
insert into school_rank ( wsl_rank,school)
values 
(1	,'清华大学'),
(2	,'浙江大学'),
(3	,'北京大学'),
(4	,'上海交通大学'),
(5	,'复旦大学'),
(6	,'南京大学'),
(7	,'武汉大学'),
(8	,'四川大学'),
(9	,'中山大学'),
(10	,'华中科技大学'),
(11	,'山东大学'),
(12	,'吉林大学'),
(13	,'哈尔滨工业大学'),
(14	,'西安交通大学'),
(15	,'中国科学技术大学'),
(16	,'南开大学'),
(17	,'东南大学'),
(18	,'中南大学'),
(19	,'同济大学'),
(20	,'中国人民大学'),
(22	,'天津大学'),
(21	,'华南理工大学'),
(23	,'厦门大学'),
(24	,'北京师范大学'),
(25	,'北京航空航天大学'),
(26	,'大连理工大学'),
(27	,'重庆大学'),
(28	,'苏州大学'),
(29	,'兰州大学'),
(30	,'北京理工大学'),
(31	,'西北工业大学'),
(32	,'湖南大学'),
(33	,'华东师范大学'),
(34	,'中国农业大学'),
(35	,'华东理工大学'),
(36	,'南京航空航天大学'),
(37	,'郑州大学'),
(38	,'西南大学'),
(39	,'电子科技大学'),
(40	,'南京农业大学'),
(41	,'华中师范大学'),
(42	,'武汉理工大学'),
(43	,'上海大学'),
(44	,'东北大学'),
(45	,'南京理工大学'),
(46	,'西安电子科技大学'),
(47	,'西北农林科技大学'),
(48	,'江苏大学'),
(49	,'江南大学'),
(50	,'哈尔滨工程大学'),
(51	,'华中农业大学'),
(52	,'北京化工大学'),
(53	,'西南交通大学'),
(54	,'北京科技大学'),
(55	,'东北师范大学'),
(56	,'暨南大学'),
(57	,'南京师范大学'),
(58	,'北京交通大学'),
(59	,'河海大学'),
(60	,'华南师范大学'),
(61	,'华北电力大学'),
(62	,'浙江工业大学'),
(63	,'陕西师范大学'),
(64	,'首都医科大学'),
(65	,'东华大学'),
(66	,'中国海洋大学'),
(67	,'西北大学'),
(68	,'河南大学'),
(69	,'福州大学'),
(70	,'中国矿业大学（华东）'),
(71	,'南昌大学'),
(72	,'北京工业大学'),
(73	,'南京工业大学'),
(74	,'扬州大学'),
(75	,'南京医科大学'),
(76	,'合肥工业大学'),
(77	,'北京邮电大学'),
(78	,'燕山大学'),
(79	,'浙江师范大学'),
(80	,'华南农业大学'),
(81	,'湖南师范大学'),
(82	,'中国地质大学（武汉）'),
(83	,'中南财经政法大学'),
(84	,'首都师范大学'),
(85	,'湘潭大学'),
(86	,'上海财经大学'),
(87	,'中国石油大学（华东）'),
(88	,'宁波大学'),
(89	,'山西大学'),
(90	,'福建师范大学'),
(91	,'昆明理工大学'),
(92	,'云南大学'),
(93	,'黑龙江大学'),
(94	,'广西大学'),
(95	,'青岛大学'),
(96	,'中国医科大学'),
(97	,'上海师范大学'),
(98	,'西南财经大学'),
(99	,'北京林业大学'),
(100	,'长安大学'),
(101	,'哈尔滨医科大学'),
(102	,'山东农业大学'),
(103	,'上海理工大学'),
(104	,'四川农业大学'),
(105	,'南方医科大学'),
(106	,'东北林业大学'),
(107	,'中国药科大学'),
(108	,'南京信息工程大学'),
(109	,'重庆医科大学'),
(110	,'中国石油大学（北京）'),
(111	,'安徽大学'),
(112	,'中国传媒大学'),
(113	,'中国地质大学（北京）'),
(114	,'太原理工大学'),
(115	,'南京邮电大学'),
(116	,'浙江理工大学'),
(117	,'中央财经大学'),
(118	,'河北大学'),
(119	,'对外经济贸易大学'),
(120	,'安徽师范大学'),
(121	,'深圳大学'),
(122	,'西北师范大学'),
(123	,'贵州大学'),
(124	,'河南师范大学'),
(125	,'济南大学'),
(126	,'广东工业大学'),
(127	,'东北财经大学'),
(128	,'天津医科大学'),
(129	,'温州医科大学'),
(130	,'中国政法大学'),
(131	,'青岛科技大学'),
(132	,'浙江工商大学'),
(133	,'山东师范大学'),
(134	,'华侨大学'),
(135	,'东北农业大学'),
(136	,'新疆大学'),
(137	,'天津师范大学'),
(138	,'南通大学'),
(139	,'哈尔滨师范大学'),
(140	,'广东外语外贸大学'),
(141	,'西安理工大学'),
(142	,'安徽医科大学'),
(143	,'杭州师范大学'),
(144	,'南京林业大学'),
(145	,'西南政法大学'),
(146	,'南京中医药大学'),
(147	,'山东科技大学'),
(148	,'江苏师范大学'),
(149	,'四川师范大学'),
(150	,'杭州电子科技大学'),
(151	,'西安建筑科技大学'),
(152	,'中央民族大学'),
(153	,'江西师范大学'),
(154	,'大连海事大学'),
(155	,'江西财经大学'),
(156	,'河北医科大学'),
(157	,'辽宁大学'),
(158	,'中北大学'),
(159	,'北京中医药大学'),
(160	,'福建农林大学'),
(161	,'汕头大学'),
(162	,'武汉科技大学'),
(163	,'河南科技大学'),
(164	,'天津工业大学'),
(165	,'河南理工大学'),
(166	,'河北工业大学'),
(167	,'内蒙古大学'),
(168	,'长沙理工大学'),
(169	,'石河子大学'),
(170	,'广州大学'),
(171	,'广西师范大学'),
(172	,'华东政法大学'),
(173	,'沈阳药科大学'),
(174	,'湖南农业大学'),
(175	,'河南农业大学'),
(176	,'西南科技大学'),
(177	,'上海中医药大学'),
(178	,'成都理工大学'),
(179	,'山东理工大学'),
(180	,'上海外国语大学'),
(181	,'河北师范大学'),
(182	,'河北农业大学'),
(183	,'陕西科技大学'),
(184	,'中国矿业大学（北京）'),
(185	,'北京外国语大学'),
(186	,'温州大学'),
(187	,'长春理工大学'),
(188	,'湖北大学'),
(189	,'辽宁师范大学'),
(190	,'哈尔滨理工大学'),
(191	,'天津科技大学'),
(192	,'兰州理工大学'),
(193	,'中南民族大学'),
(194	,'三峡大学'),
(195	,'南华大学'),
(196	,'广州中医药大学'),
(197	,'辽宁工程技术大学'),
(198	,'聊城大学'),
(199	,'中国计量大学'),
(200	,'重庆邮电大学')
