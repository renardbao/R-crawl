library(xml2)
library(magrittr)
library(ggplot2)
library(dplyr)
library(stringr)
#目標股票
stock <- as.character(6180)
#運用X來標記要消掉的
date <- as.Date(0:365,origin = "2017-7-30") %>% format("%Y-X%m-X%d") %>% 
            gsub("X0","",.) %>% gsub("X","",.) 
url <- paste0('http://jdata.yuanta.com.tw/z/zc/zco/zco.djhtm?a=',stock,'&e=',date,'&f=',date)
#券商的標籤
xpath1 <- '//*[@class="t4t1"]/a'
#券商資料的標籤
xpath2 <-'//*[@class="t3n1"]'
#extract node
target = xml_find_all(read_html(url(url[2])), xpath1)##2017-7-31
target2 <- xml_find_all(read_html(url(url[2])), xpath2)
#2017-7-31當日主力券商
broker = xml_text(target)
#2017-7-31
rawdata <- xml_text(target2)
#去掉後面四個多餘的資料
rawdata <- rawdata[-c(121:124)]
#將爬下來的資料整理成一個table
data1 <-matrix(rawdata,ncol=length(rawdata)/4,nrow=4) %>% t() 
data1 <- data.frame(broker,data1,date[2])
colnames(data1)[c(2:6)] <- c("買進","賣出","買賣超","佔成交比重","日期")
#奇數買超券商
netbuyer <- data1[(1:length(broker))%%2!=0,]
#偶數賣超券商
netseller <-data1[(1:length(broker))%%2==0,]
netbuyer;netseller

#創建一個物件儲存資料
netbuyer_all <- NULL 
netseller_all <- NULL 
broker_data_all <- NULL
##彙整2017-7-30 ~ 2017-8-8
for(i in 1:365){
  
    #extract node
    target = xml_find_all(read_html(url(url[i])), xpath1)
    target2 <- xml_find_all(read_html(url(url[i])), xpath2)
    broker_all = xml_text(target)
    ##偵測是否為停止交易日
    if(length(broker_all) != 0){
      rawdata_all <- xml_text(target2)
      #去掉後面四個多餘的資料
      rawdata_all <- rawdata[-c(121:124)]
      #將爬下來的資料整理成一個table
      broker_data <-matrix(rawdata_all,ncol=length(rawdata_all)/4,nrow=4) %>% t() 
      broker_data <- data.frame(broker_all,broker_data,date[i])
      colnames(broker_data) <- c("券商","買進","賣出","買賣超","佔成交比重","日期")
      #奇數買超券商
      netbuyer_temp <- broker_data[(1:length(broker))%%2!=0,]
      netbuyer_all <- rbind(netbuyer_all,netbuyer_temp)
      
      #偶數賣超券商
      netseller_temp <-broker_data[(1:length(broker))%%2==0,]
      netseller_all <- rbind(netseller_all,netseller_temp)
      broker_data_all <- rbind(broker_data_all,broker_data)
      #Sys.sleep(sample(3:7,1)) #跑一次讓系統暫停幾秒來模擬快速版人類行為
    }
    else
      {
      next()
    }
      
    
}
#將列名清除
rownames(netbuyer_all) <- NULL
rownames(netseller_all) <- NULL
#刪掉暫存的中繼變數
rm(netbuyer_temp);rm(netseller_temp);rm(broker_all);rm(rawdata_all)
broker_data_all$買進 %<>% as.character() %>% as.numeric()
broker_data_all$賣出 %<>% as.character() %>% as.numeric()
broker_data_all$日期 %<>% as.Date()
broker_data_all %<>% group_by(券商) %>%  mutate(當日進出 = 買進 - 賣出,累計進出 = cumsum(當日進出)) %>%
  as.data.frame()
#累計進出曾經達到250
broker_name <-  broker_data_all[abs(broker_data_all$累計進出) > 250,"券商"] %>% unique()
ggdata <- broker_data_all[which(broker_data_all$券商 %in% broker_name),] 
ggdata %>% group_by(券商) %>% summarise(n()) %>% as.data.frame()
#作圖
ggdata %>% ggplot(aes(x = 日期,y=累計進出,color = 券商)) +
  geom_line(size = 1.5) + 
  geom_point(size = 3.5) + 
  theme_bw() + #去掉背景色
  theme(panel.grid=element_blank(),  #去掉網線
        panel.border=element_blank(),#去掉邊線
        axis.line=element_line(size=1,colour="black")) + #加深XY線軸
  scale_y_continuous(breaks = seq(-800,500,100))
#範圍大致落在500 ~ -800 之間

#http://www.yuanta.com.tw/pages/content/StockInfo.aspx?Node=fad9d056-9903-40f4-9806-b810b59c4b1c
#http://jdata.yuanta.com.tw/z/BCD/czkc1.djbcd?a=6180&b=D&E=1&ver=5
#library(jsonlite)
#library(RCurl)
#rawdata6180 <- getURL("http://jdata.yuanta.com.tw/z/BCD/czkc1.djbcd?a=6180&b=D&E=1&ver=5") 

#xml2寫法
rawdata6180 <- read_html(url("http://jdata.yuanta.com.tw/z/BCD/czkc1.djbcd?a=6180&b=D&E=1&ver=5")) %>% xml_text()
data6180 <- data.frame(
            日期 = str_split(rawdata6180," ") %>% "[["(1) %>% "["(1) %>% str_split(",") %>% 
              "[["(1) %>% as.Date(),
            累計進出 = str_split(rawdata6180," ") %>% "[["(1) %>% "["(5) %>% str_split(",") %>% 
              "[["(1) %>% as.numeric()
                       )
data6180 <- cbind(券商 = "6180",data6180[ data6180$日期 %>% "%in%" (ggdata$日期 %>% unique() ),])

ggdata_250 <- rbind(
                    cbind(data6180[,c("券商","日期")],累計進出 = data6180[,"累計進出"] * 10 - 800), #將6180收盤價依照比例轉換
                    ggdata[,c("券商",'日期','累計進出')]
                   )

ggdata_250 %>% ggplot(aes(x = 日期,y=累計進出,color = 券商,alpha = 券商,size = 券商)) +
  geom_line() + 
  geom_point() + 
  geom_hline(yintercept = 0,linetype = "dashed",size = 2) +
  ##設定y的主標籤軸刻度以及添加第二個y的標籤軸
  scale_y_continuous(breaks = seq(-800,500,100),sec.axis = sec_axis(~ (.+800) / 10 ,breaks = seq(0,120,20)))+  
  scale_alpha_manual(values = c(1,rep(0.6,10))) +
  scale_size_manual(values = c(4,rep(2,10))) + 
  theme_bw() + #去掉背景色
  theme(panel.grid=element_blank(),  #去掉網線
        panel.border=element_blank(),#去掉邊線
        axis.line=element_line(size=1,colour="black"))#加深XY線軸

#找出非個別通路
broker_data_all[broker_data_all$券商 %>% str_detect("-") %>% "!"() ,"券商"] %>% unique()
#挑出幾間外資,幾間國內的券商
broker_name_mypick <- c("美林","台灣摩根士丹利","美商高盛","元大","新光")

#將挑出券商資料和6180合併
ggdata_mypick <- rbind(
                       cbind(data6180[,c("券商","日期")],累計進出 = data6180[,"累計進出"] * 10 - 800), #將6180收盤價依照比例轉換
                       broker_data_all[broker_data_all$券商 %in%  broker_name_mypick,c("券商",'日期','累計進出')]
)

ggdata_mypick %>% ggplot(aes(x = 日期,y=累計進出,color = 券商,alpha = 券商,size = 券商)) +
  geom_line() + 
  geom_point() + 
  geom_hline(yintercept = 0,linetype = "dashed",size = 2) +
  ##設定y的主標籤軸刻度以及添加第二個y的標籤軸
  scale_y_continuous(breaks = seq(-800,500,100),sec.axis = sec_axis(~ (.+800) / 10 ,breaks = seq(0,120,20)))+  
  scale_alpha_manual(values = c(1,rep(0.6,10))) +
  scale_size_manual(values = c(4,rep(2,10))) + 
  theme_bw() + #去掉背景色
  theme(panel.grid=element_blank(),  #去掉網線
        panel.border=element_blank(),#去掉邊線
        axis.line=element_line(size=1,colour="black"))

