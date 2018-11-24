library(xml2)
library(magrittr)
#目標股票
stock <- as.character(6180)
#運用X來標記要消掉的
date <- as.Date(0:60,origin = "2017-7-30") %>% format("%Y-X%m-X%d") %>% 
            gsub("X0","",.) %>% gsub("X","",.) 
url <- paste0('http://jdata.yuanta.com.tw/z/zc/zco/zco.djhtm?a=',stock,'&e=',date,'&f=',date)

#券商的標籤
xpath1 <- '//*[@class="t4t1"]/a'
target = xml_find_all(read_html(url(url[2])), xpath1)##2017-7-31
#2017-7-31當日主力券商
broker = xml_text(target)
#券商資料的標籤
xpath2 <-'//*[@class="t3n1"]'
target2 <- xml_find_all(read_html(url(url[2])), xpath2)
rawdata <- xml_text(target2)
#去掉後面四個多餘的資料
rawdata <- rawdata[-c(121:124)]
#將爬下來的資料整理成一個table
data1 <-matrix(rawdata,ncol=length(rawdata)/4,nrow=4) %>% t() 
data1 <- data.frame(broker,data1)
colnames(data1)[c(2:5)] <- c("買進","賣出","買賣超","佔成交比重")
#奇數買超券商
netbuyer <- data1[(1:length(broker))%%2!=0,]
#偶數賣超券商
netseller <-data1[(1:length(broker))%%2==0,]

