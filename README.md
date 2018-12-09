---
title: "爬主力進出"
author: "包孟晨"
date: "2017年9月30日"
output: 
 html_document:
   toc: true
   toc_depth: 3
   toc_float: true
   keep_md: true
---

以下是這次會用到的套件，xml2就是這次的主角，主要負責讀取網頁內容的內容。

```r
library(xml2)
library(magrittr)
library(ggplot2)
library(dplyr)
library(stringr)
```
##找尋目標URL
最近因為天堂m的關係而關注了橘子6180，也就這樣產生了想看看每天各大券商進出這支股票的數量，順便練習一下爬蟲。觀察一下目標網頁的內容：

<img src="picture/1.png" width="80%" />

我沒辦法從網址上找到有規律的邏輯。因此，我要透過其他方法來觀察目標網頁，在這裡用的是Chrome  的開發人員工具，先在這一頁按下快捷鍵Cmd/Ctrl + Shift + i(或者是右上角三個點點  > 更多工具 > 開發人員工具)，切換到Network分頁，重新整理後便可以看到瀏覽過程的所有連線。

不過還是沒辦法取得我想要的資訊，這時候將連線清除(左上角禁止的圖案)，然後點選查詢來查詢最近一日
的主力進出!  

<img src="picture/2.png" width="80%" />  

所以我就找到啦!  
 $\rightarrow$ http://jdata.yuanta.com.tw/z/zc/zco/zco.djhtm?a=6180&e=2017-9-29&f=2017-9-29  
 網址上包含了股票代碼以及搜尋日期，也就是說我只需要更動這三個地方就能取得資料。
 
##Double-Digtal日期格式

```r
#目標股票
stock <- as.character(6180)
#運用X來標記要消掉的
date <- as.Date(0:365,origin = "2017-7-30") %>% format("%Y-X%m-X%d") %>% 
            gsub("X0","",.) %>% gsub("X","",.) 
url <- paste0('http://jdata.yuanta.com.tw/z/zc/zco/zco.djhtm?a=',stock,'&e=',date,'&f=',date)
```
關於日期date的部分讓我頭痛了一陣子，因為我發現元大網站並不支援R內建時間格式2017-09-09這樣月跟日
是double-digtal，只能是2017-9-9這樣的形式，也就是我必須想辦法把0去掉。假如是單純的把0去掉，也會
把年分2017的0也去掉了，後來我爬了stackoverflow的文，發現[這篇文](https://stackoverflow.com/questions/31065993/how-to-deal-with-days-and-or-month-with-one-digit-remove-the-0-in-r)**RHertel**大所提供的方法挺有趣又好用的!

也就是我`date`裡面所用到的方法，他是透過用"X"來標記月跟日的前面，透過`gsub`將"X0"消掉前面有0的數字，然後再`gsub`一次將剩餘沒搭配到0的"X"給消掉，這樣就不會消到2017的0又能將月跟日的0給消掉了!

##目標資料
<img src="picture/3.png" width="80%" />


這就是我想要取下來的資料，對著其中一欄點右鍵$\rightarrow$檢查 會得到xpath


<img src="picture/4.png" width="80%" />

我們會發現券商的名字那格都會叫做`td class='t4t1'`，而後面的資料都叫做`td class='t3n1'`
這些將有利我撰寫xpath，讓我可以順利從網頁上下載我想要的資料。
###套件xml2
我使用的套件是`xml2`，主要是使用以下函數:
+ read_html()：將網址所對應的html頁面，儲存成一個物件。

+ xml_find_all()：找到符合「規則」的所有html原始碼。

+ xml_text()：從html原始碼中，取出內容。

+ xml_attr()：從html原始碼中，取出屬性。


```r
#券商的標籤
xpath1 <- '//*[@class="t4t1"]/a'
#券商資料的標籤
xpath2 <-'//*[@class="t3n1"]'
#extract node
target = xml_find_all(read_html(url(url[2])), xpath1)##2017-7-31
target2 <- xml_find_all(read_html(url(url[2])), xpath2)
#2017-7-31當日主力券商
broker = xml_text(target)
```


然後取得券商後面的資料


```r
#2017-7-31
rawdata <- xml_text(target2)
rawdata 
```

```
##   [1] "48"     "7"      "41"     "8.49%"  "0"      "73"     "73"    
##   [8] "15.11%" "29"     "0"      "29"     "6%"     "2"      "26"    
##  [15] "24"     "4.97%"  "27"     "0"      "27"     "5.59%"  "0"     
##  [22] "20"     "20"     "4.14%"  "23"     "0"      "23"     "4.76%" 
##  [29] "0"      "20"     "20"     "4.14%"  "15"     "0"      "15"    
##  [36] "3.11%"  "0"      "12"     "12"     "2.48%"  "13"     "0"     
##  [43] "13"     "2.69%"  "0"      "11"     "11"     "2.28%"  "16"    
##  [50] "5"      "11"     "2.28%"  "0"      "10"     "10"     "2.07%" 
##  [57] "10"     "0"      "10"     "2.07%"  "0"      "10"     "10"    
##  [64] "2.07%"  "10"     "0"      "10"     "2.07%"  "0"      "10"    
##  [71] "10"     "2.07%"  "10"     "0"      "10"     "2.07%"  "0"     
##  [78] "10"     "10"     "2.07%"  "10"     "0"      "10"     "2.07%" 
##  [85] "0"      "10"     "10"     "2.07%"  "9"      "0"      "9"     
##  [92] "1.86%"  "0"      "10"     "10"     "2.07%"  "10"     "1"     
##  [99] "9"      "1.86%"  "0"      "8"      "8"      "1.66%"  "8"     
## [106] "0"      "8"      "1.66%"  "0"      "8"      "8"      "1.66%" 
## [113] "8"      "1"      "7"      "1.45%"  "0"      "8"      "8"     
## [120] "1.66%"  "232"    "244"    "36.24"  "36.18"
```

```r
#去掉後面四個多餘的資料
rawdata <- rawdata[-c(121:124)]
rawdata
```

```
##   [1] "48"     "7"      "41"     "8.49%"  "0"      "73"     "73"    
##   [8] "15.11%" "29"     "0"      "29"     "6%"     "2"      "26"    
##  [15] "24"     "4.97%"  "27"     "0"      "27"     "5.59%"  "0"     
##  [22] "20"     "20"     "4.14%"  "23"     "0"      "23"     "4.76%" 
##  [29] "0"      "20"     "20"     "4.14%"  "15"     "0"      "15"    
##  [36] "3.11%"  "0"      "12"     "12"     "2.48%"  "13"     "0"     
##  [43] "13"     "2.69%"  "0"      "11"     "11"     "2.28%"  "16"    
##  [50] "5"      "11"     "2.28%"  "0"      "10"     "10"     "2.07%" 
##  [57] "10"     "0"      "10"     "2.07%"  "0"      "10"     "10"    
##  [64] "2.07%"  "10"     "0"      "10"     "2.07%"  "0"      "10"    
##  [71] "10"     "2.07%"  "10"     "0"      "10"     "2.07%"  "0"     
##  [78] "10"     "10"     "2.07%"  "10"     "0"      "10"     "2.07%" 
##  [85] "0"      "10"     "10"     "2.07%"  "9"      "0"      "9"     
##  [92] "1.86%"  "0"      "10"     "10"     "2.07%"  "10"     "1"     
##  [99] "9"      "1.86%"  "0"      "8"      "8"      "1.66%"  "8"     
## [106] "0"      "8"      "1.66%"  "0"      "8"      "8"      "1.66%" 
## [113] "8"      "1"      "7"      "1.45%"  "0"      "8"      "8"     
## [120] "1.66%"
```


##整理資料
我們會發現每四筆資料為一組，並且依照順序為買進、賣出、買超和佔成交比重，賣超方則為買進、賣出、賣超及佔成交比重。


```r
data1 <- matrix(rawdata,ncol=length(rawdata)/4,nrow=4) %>% t() 
data1 <- data.frame(broker,data1,date[2])
colnames(data1)[c(2:6)] <- c("買進","賣出","買賣超","佔成交比重","日期")
head(data1)
```

```
##      broker 買進 賣出 買賣超 佔成交比重      日期
## 1      美林   48    7     41      8.49% 2017-7-31
## 2 日盛-大墩    0   73     73     15.11% 2017-7-31
## 3  瑞士信貸   29    0     29         6% 2017-7-31
## 4  華南永昌    2   26     24      4.97% 2017-7-31
## 5 臺銀-臺南   27    0     27      5.59% 2017-7-31
## 6 日盛-園區    0   20     20      4.14% 2017-7-31
```

資料蒐集到後養成習慣看一下它的結構


```r
str(data1)
```

```
## 'data.frame':	30 obs. of  6 variables:
##  $ broker    : Factor w/ 30 levels "大昌-安康","大慶-富順",..: 16 9 26 25 28 10 27 11 29 19 ...
##  $ 買進      : Factor w/ 12 levels "0","10","13",..: 10 1 9 6 8 1 7 1 4 1 ...
##  $ 賣出      : Factor w/ 11 levels "0","1","10","11",..: 9 10 1 7 1 6 1 6 1 5 ...
##  $ 買賣超    : Factor w/ 15 levels "10","11","12",..: 11 13 10 8 9 6 7 6 5 3 ...
##  $ 佔成交比重: Factor w/ 15 levels "1.45%","1.66%",..: 15 4 14 12 13 10 11 10 9 7 ...
##  $ 日期      : Factor w/ 1 level "2017-7-31": 1 1 1 1 1 1 1 1 1 1 ...
```

發現我們爬到的資料在合併到data.frame的過程中被"貼心"的轉成factor了，data.frame函數裡面有個參數`stringsAsFactors = TRUE`，其內建是TRUE，所以我們不要的話可以在這邊改成FALSE或者直接`options(stringsAsFactors = FALSE)`改掉預設值。但是在這邊我還不需要把變數轉成它應該的種類，我們稍後爬取大量資料時在一次處理。

我取得了2017-7-31日當天主力進出的各個券商，值得注意的是奇數是買超券商，偶數是賣超券商。所以分組過後$\downarrow$

```r
#奇數買超券商
netbuyer <- data1[(1:length(broker))%%2!=0,]
#偶數賣超券商
netseller <-data1[(1:length(broker))%%2==0,]
netbuyer;netseller
```

```
##        broker 買進 賣出 買賣超 佔成交比重      日期
## 1        美林   48    7     41      8.49% 2017-7-31
## 3    瑞士信貸   29    0     29         6% 2017-7-31
## 5   臺銀-臺南   27    0     27      5.59% 2017-7-31
## 7   臺銀-民權   23    0     23      4.76% 2017-7-31
## 9   德信-中正   15    0     15      3.11% 2017-7-31
## 11       亞東   13    0     13      2.69% 2017-7-31
## 13  兆豐-板橋   16    5     11      2.28% 2017-7-31
## 15  富邦-建國   10    0     10      2.07% 2017-7-31
## 17  元大-沙鹿   10    0     10      2.07% 2017-7-31
## 19  元大-苑裡   10    0     10      2.07% 2017-7-31
## 21  元大-中和   10    0     10      2.07% 2017-7-31
## 23  大慶-富順    9    0      9      1.86% 2017-7-31
## 25  元富-大昌   10    1      9      1.86% 2017-7-31
## 27  康和-高雄    8    0      8      1.66% 2017-7-31
## 29 港商德意志    8    1      7      1.45% 2017-7-31
```

```
##           broker 買進 賣出 買賣超 佔成交比重      日期
## 2      日盛-大墩    0   73     73     15.11% 2017-7-31
## 4       華南永昌    2   26     24      4.97% 2017-7-31
## 6      日盛-園區    0   20     20      4.14% 2017-7-31
## 8      玉山-士林    0   20     20      4.14% 2017-7-31
## 10     統一-桃園    0   12     12      2.48% 2017-7-31
## 12     凱基-台北    0   11     11      2.28% 2017-7-31
## 14   盈溢-籬子內    0   10     10      2.07% 2017-7-31
## 16     大昌-安康    0   10     10      2.07% 2017-7-31
## 18     國票-台東    0   10     10      2.07% 2017-7-31
## 20     玉山-高雄    0   10     10      2.07% 2017-7-31
## 22     富邦-敦南    0   10     10      2.07% 2017-7-31
## 24     元大-南屯    0   10     10      2.07% 2017-7-31
## 26      中國信託    0    8      8      1.66% 2017-7-31
## 28 德信-台北(停)    0    8      8      1.66% 2017-7-31
## 30     富邦-世貿    0    8      8      1.66% 2017-7-31
```

##自動化爬取
成功試爬一天的資料後，將爬取資料擴大到一年份。在這邊運用for迴圈，讓程式爬取2017-7-30往後365天的資料。另外，在爬取長時間的股市資料日期中，休盤日會是一個大問題。休盤日意味著股市沒有運作，股市沒有運作則目標網頁上就不會有資料，那在爬的過程中就會因為xpath錯誤而ERROR。所以我想到兩種方式可以解決問題，第一種是運用`trycatch()`它是類似C語言專門處理例外機制的函數，不過這邊用第二種的會比較簡單。  

第二種方法就是用`if else`！其實大多數的例外機制可以透過簡單的`if else`來處理，例如這邊以下的情況。由於休盤日，所以目標網頁會沒有資料，我所設定的xpath就不會存在，那這樣xml_text()就不會有資料其為空值，所以`if else`的條件式就可以針對這點去做檢測，當不等於0的時候運行，等於0的時候則執行`next()`來跳過現階段的迴圈。  

###For迴圈

```r
#創建一個物件儲存資料
netbuyer_all <- NULL 
netseller_all <- NULL 
broker_data_all <- NULL
##彙整2017-7-30 ~ 2018-7-30
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
head(broker_data_all);tail(broker_data_all)
```

###資料處理
因為data.frame對於變數預設的關係，我們必須要將一些欄位轉換成我們想要的類別。比較值得一提的，factor在轉換成numeric的時候要先轉成character再轉換成numeric。為什麼呢？因為factor是帶有次序的，所以當你直接轉成numeric，轉換的值會是其在Levels的位置。例如"10"在某個factor變數中其Levels是第二個，那你在轉換的時候"10"都會被轉換成2。

```r
broker_data_all$買進 %<>% as.character() %>% as.numeric()
broker_data_all$賣出 %<>% as.character() %>% as.numeric()
broker_data_all$日期 %<>% as.Date()
```
###分組運算
現在想要再增加一欄變數是根據券商每日的進出進行累計加總，這邊運用的是`dplyr`套件，透過`group_by`進行分組再運用`mutate`進行增加欄位和函數計算。

```r
broker_data_all %<>% group_by(券商) %>%  mutate(當日進出 = 買進 - 賣出,累計進出 = cumsum(當日進出)) %>%
  as.data.frame()
```

##ggplot作圖
###累計進出達到250
看一下那些一直收購或賣出的券商曾經累積的量達到250的有哪些？它們又是在哪個時間點出手的呢？

```r
#累計進出曾經達到250
broker_name <-  broker_data_all[abs(broker_data_all$累計進出) > 250,"券商"] %>% unique()
ggdata <- broker_data_all[which(broker_data_all$券商 %in% broker_name),] 
#作圖
ggdata %>% 
  ggplot(aes(x = 日期,y=累計進出,color = 券商)) +
  geom_line(size = 1.5) + 
  geom_point(size = 3.5) + 
  theme_bw() + #去掉背景色
  theme(panel.grid=element_blank(),  #去掉網線
        panel.border=element_blank(),#去掉邊線
        axis.line=element_line(size=1,colour="black")) + #加深XY線軸
  scale_y_continuous(breaks = seq(-800,500,100))
```

![](crawl6180_files/figure-html/ggplot1-1.png)<!-- -->

###6180收盤價
元大的目標網頁有點難爬收盤價資料，我找來找去最後在這個網頁找到點蛛絲馬跡。  
$\rightarrow$ http://www.yuanta.com.tw/pages/content/StockInfo.aspx?Node=fad9d056-9903-40f4-9806-b810b59c4b1c  
怎麼找的呢?跟前述的方法雷同，只不過我在切換網頁年跟月的時候發現這個URL http://jdata.yuanta.com.tw/z/BCD/czkc1.djbcd?a=6180&b=M&E=1&ver=5 會隨之變化其中一個參數，所以我們要的日收盤價就在這個URL$\rightarrow$ http://jdata.yuanta.com.tw/z/BCD/czkc1.djbcd?a=6180&b=D&E=1&ver=5
既然找到URL了，那就趕快來爬取資料吧。


```r
rawdata6180 <- "http://jdata.yuanta.com.tw/z/BCD/czkc1.djbcd?a=6180&b=D&E=1&ver=5" %>% 
                 url %>% read_html %>% xml_text()
```

這邊我們爬取下來的資料是一整串的char，看起來好像很亂，但是仔細觀察你會發現它是有規律的。首先，它是依照空格進行類別的歸類，第一個空格以前都是日期，第一個空格到第二個空格之前是開盤價或最低價等等。所以我們要做的事情是將資料先依照空格來分割然後選取我們要的第一個(日期)和第五個物件(收盤價)，最後依照逗號來進行分割再轉成日期和numeric。


```r
#第五個是6180收盤價，命名為累計進出是方便跟ggdata進行rbind做後續的畫圖處理
data6180 <- data.frame(
            日期 = str_split(rawdata6180," ") %>% "[["(1) %>% "["(1) %>% 
              str_split(",") %>% "[["(1) %>% as.Date(),
            累計進出 = str_split(rawdata6180," ") %>% "[["(1) %>% "["(5) %>% 
              str_split(",") %>% "[["(1) %>% as.numeric()
                       )
data6180 <- cbind(券商 = "6180",
                  data6180[ data6180$日期 %>% "%in%" (ggdata$日期 %>% unique() ),])

ggdata_250 <- rbind(cbind(data6180[,c("券商","日期")],
                          累計進出 = data6180[,"累計進出"] * 10 - 800),
                    #將6180收盤價依照比例轉換
                    ggdata[,c("券商",'日期','累計進出')]
                   )

ggdata_250 %>% 
  ggplot(aes(x = 日期,y=累計進出,color = 券商,alpha = 券商,size = 券商)) +
  geom_line() + 
  geom_point() + 
  geom_hline(yintercept = 0,linetype = "dashed",size = 2) +
  ##設定y的主標籤軸刻度以及添加第二個y的標籤軸
  scale_y_continuous(breaks = seq(-800,500,100),
                     sec.axis = sec_axis(~ (.+800) / 10 ,breaks = seq(0,120,20)))+  
  scale_alpha_manual(values = c(1,rep(0.6,10))) +
  scale_size_manual(values = c(4,rep(2,10))) + 
  theme_bw() + #去掉背景色
  theme(panel.grid=element_blank(),  #去掉網線
        panel.border=element_blank(),#去掉邊線
        axis.line=element_line(size=1,colour="black"))#加深XY線軸
```

![](crawl6180_files/figure-html/ggplot2-1.png)<!-- -->

看一下上圖(雖然看起來很亂)可以發現自7/31起外資一直賣，國內券商和散戶一直在買，尤其是2017-8月到2018-1月真的很神奇．．．

###指定券商
最後來看一下美林、台灣摩根士丹利、美商高盛、元大和新光搭配6180收盤價來當個結尾。


```r
#挑出幾間外資,幾間國內的券商
broker_name_mypick <- c("美林","台灣摩根士丹利","美商高盛","元大","新光")

#將挑出券商資料和6180合併
ggdata_mypick <- rbind(cbind(data6180[,c("券商","日期")],
                             累計進出 = data6180[,"累計進出"] * 10 - 800),
                       #將6180收盤價依照比例轉換
                       broker_data_all[broker_data_all$券商 %in% broker_name_mypick,
                                       c("券商",'日期','累計進出')]
                       )

ggdata_mypick %>% 
  ggplot(aes(x = 日期,y=累計進出,color = 券商,alpha = 券商,size = 券商)) +
  geom_line() + 
  geom_point() + 
  geom_hline(yintercept = 0,linetype = "dashed",size = 2) +
  ##設定y的主標籤軸刻度以及添加第二個y的標籤軸
  scale_y_continuous(breaks = seq(-800,500,100),
                     sec.axis = sec_axis(~ (.+800) / 10 ,breaks = seq(0,120,20)))+  
  scale_alpha_manual(values = c(1,rep(0.6,10))) +
  scale_size_manual(values = c(4,rep(2,10))) + 
  theme_bw() + #去掉背景色
  theme(panel.grid=element_blank(),  #去掉網線
        panel.border=element_blank(),#去掉邊線
        axis.line=element_line(size=1,colour="black"))
```

![](crawl6180_files/figure-html/ggplot3-1.png)<!-- -->

