#导入并整理应收表格，然后将数据转成数字格式
ys1 <- data.frame(read.xlsx2("应收.xls",sheetIndex = 1,stringsAsFactors=FALSE))
ys1 <-ys1[-1,]
ys1 <-ys1[-1335:-1338,]
ys1 <- ys1[!(ys1$期末余额==""),]
ys2 <- ys1[order(ys1$客商辅助核算名称),]
ys2 <-ys2[-1,]
ys2[,length(ys2)] <- as.numeric(ys2[,length(ys2)],fixed=TRUE)
#导入待处理的表格
dcl1 <- data.frame(read.xlsx2("待处理.XLS",sheetIndex = 1,stringsAsFactors=FALSE))
dcl1 <- dcl1[-1,]
dcl1 <- dcl1[-303:-305,]
dcl2 <- dcl1[order(dcl1$客户名称),]

#应收表格里有很多重复的，合并成一个，将期末余额加起来
newys <- data.frame(ys2[1,],stringsAsFactors = FALSE)
newys <- newys[-1,]
uni_ysname_list <- unique(ys2$客商辅助核算名称)
##只有期末余额是对的，其他数据都是错的，需要修改！！
for(irow in 1:length(uni_ysname_list)){
    temp_index <- grep(pattern = uni_ysname_list[irow],x = ys2$客商辅助核算名称)
    newys[irow,] <- ys2[grep(pattern = uni_ysname_list[irow],x = ys2$客商辅助核算名称)[1],]
    newys$期末余额[irow] <- sum(as.numeric(ys2$期末余额[grep(pattern = uni_ysname_list[irow],x = ys2$客商辅助核算名称)]))
}

#将待处理表格里名称重复的项合并起来，各年欠款相加
newdcl <- data.frame(dcl2[1,],stringsAsFactors = FALSE)
newdcl <- newdcl[-1,]
uni_dclname_list <- unique(dcl2$客户名称)
for(irow in 1:length(uni_dclname_list)){
    temp_index <- grep(pattern = uni_dclname_list[irow],x = dcl2$客户名称,fixed = TRUE)
    newdcl[irow,] <- dcl2[grep(pattern = uni_dclname_list[irow],x = dcl2$客户名称,fixed = TRUE)[1],]
    newdcl$X1年以内[irow] <- sum(as.numeric(dcl2$X1年以内[grep(pattern = uni_dclname_list[irow],x = dcl2$客户名称,fixed = TRUE)]))
    newdcl$X1.2年[irow] <- sum(as.numeric(dcl2$X1.2年[grep(pattern = uni_dclname_list[irow],x = dcl2$客户名称,fixed = TRUE)]))
    newdcl$X2.3年[irow] <- sum(as.numeric(dcl2$X2.3年[grep(pattern = uni_dclname_list[irow],x = dcl2$客户名称,fixed = TRUE)]))
    newdcl$X3.4年[irow] <- sum(as.numeric(dcl2$X3.4年[grep(pattern = uni_dclname_list[irow],x = dcl2$客户名称,fixed = TRUE)]))
    newdcl$X4.5年[irow] <- sum(as.numeric(dcl2$X4.5年[grep(pattern = uni_dclname_list[irow],x = dcl2$客户名称,fixed = TRUE)]))
    newdcl$X5年以上[irow] <- sum(as.numeric(dcl2$X5年以上[grep(pattern = uni_dclname_list[irow],x = dcl2$客户名称,fixed = TRUE)]))
}
#增加年初项目，就是以前欠款的总和
newdcl$NianChu2015<-as.numeric(newdcl$X1.2年)+as.numeric(newdcl$X1年以内)+as.numeric(newdcl$X2.3年)+as.numeric(newdcl$X3.4年)+as.numeric(newdcl$X4.5年)+as.numeric(newdcl$X5年以上)
#增加年末项目，今年欠款的总和
newdcl$NianMo2015 <- 0
#变为数字格式
for (icol in 3:length(newdcl)) {
    newdcl[,icol] <- as.numeric(newdcl[,icol],fixed=TRUE)
}
newdcl$备注 <- ""
#开始整理
for (irow in 1:nrow(newys)) {
#本次处理的公司名字
temp_name <- newys$客商辅助核算名称[irow]
#本次处理的公司名字对应在待处理表格里的一行数据
temp_line <- newdcl[newdcl$客户名称==temp_name,]
#本次处理的公司在待处理表格里对应的行索引
temp_DclIndex <- grep(pattern = temp_name,newdcl$客户名称)
#本次处理的公司年末数据，就是应收的总额
temp_NianMoYuE <- newys$期末余额[irow]
#如果找不到应收的公司，说明以前没有欠款，那么创建一个新行来记录这个公司
if (nrow(temp_line)==0){
    #创建一个新行，结构跟待处理表格一样的
    temp_line <- data.frame(newdcl[1,],stringsAsFactors = FALSE)
    #temp_line <- temp_line[-1,]
    #设定本次处理的公司名称
    temp_line$客户名称 <- temp_name
    #第一年开始欠费
    temp_line$X1年以内 <- newys$期末余额[irow]
    #年初欠费应该为0
    temp_line$NianChu2015 <- 0
    #年末欠费就是今年新欠的
    temp_line$NianMo2015 <- temp_line$X1年以内
    newdcl <- rbind(newdcl,temp_line)
    #找到数据的情况，也就是说以前欠费了
}else{
    #年初余额，以前欠费的总额
    temp_NianChuYuE <- temp_line$NianChu2015
    #年初余额小于或者等于年末余额，就是说欠款一分钱没还(相等)，或者借了更多的钱(小于)
    if(temp_NianChuYuE == temp_NianMoYuE || temp_NianChuYuE < temp_NianMoYuE){
    #新借了多少钱
        ChaE <- temp_NianMoYuE - temp_NianChuYuE
        #账龄转移到下一年
        newdcl$X5年以上[temp_DclIndex] <- newdcl$X5年以上[temp_DclIndex] + newdcl$X4.5年[temp_DclIndex]
        newdcl$X4.5年[temp_DclIndex] <- newdcl$X3.4年[temp_DclIndex]
        newdcl$X3.4年[temp_DclIndex] <- newdcl$X2.3年[temp_DclIndex]
        newdcl$X2.3年[temp_DclIndex] <- newdcl$X1.2年[temp_DclIndex]
        newdcl$X1.2年[temp_DclIndex] <- newdcl$X1年以内[temp_DclIndex]
        newdcl$X1年以内[temp_DclIndex] <- ChaE
        #增加年末余额这一项
        newdcl$NianMo2015[temp_DclIndex] <- temp_NianMoYuE
    #另外一种情况，年初余额大于年末余额，就是说还了一部分钱
    }else{
        #首先打*标记
        newdcl$备注[temp_DclIndex] <- "*"
        #剩余未还的钱
        temp_WeiHuan <- temp_NianChuYuE - temp_NianMoYuE
        temp_sum <- 0
        #优先扣除账龄长的项目，得到剩余账龄分布
        for (iyear in 3:8) {
            temp_sum <- temp_sum + newdcl[temp_DclIndex,iyear]
            if(temp_sum == temp_WeiHuan||temp_sum > temp_WeiHuan){
                newdcl[temp_DclIndex,iyear] <- newdcl[temp_DclIndex,iyear]-(temp_sum-temp_WeiHuan)
                newdcl[temp_DclIndex,(iyear+1):8] <- 0
                break
            }
        }
        #账龄转移
        newdcl$X5年以上[temp_DclIndex] <- newdcl$X5年以上[temp_DclIndex] + newdcl$X4.5年[temp_DclIndex]
        newdcl$X4.5年[temp_DclIndex] <- newdcl$X3.4年[temp_DclIndex]
        newdcl$X3.4年[temp_DclIndex] <- newdcl$X2.3年[temp_DclIndex]
        newdcl$X2.3年[temp_DclIndex] <- newdcl$X1.2年[temp_DclIndex]
        newdcl$X1.2年[temp_DclIndex] <- newdcl$X1年以内[temp_DclIndex]
        newdcl$X1年以内[temp_DclIndex] <- 0
        newdcl$NianMo2015[temp_DclIndex] <- temp_NianMoYuE
        }
    }
}
#如果年末为0，说明今年已经还清了所有欠款，那么将账龄清零
newdcl[newdcl$NianMo2015==0,3:8] <- 0
#生成顺序的序号
newdcl$序号 <- as.numeric(c(1:nrow(newdcl)),fixed=TRUE)
#整理完毕，写入表格res1.xlsx
write.xlsx(newdcl,"res1.xlsx")