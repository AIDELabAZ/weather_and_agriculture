## make plots for visualizing survey and station locations
## highlight stations that have data in time period of interest
## use anonymized locations (first wave) for publication

##=======================================================================
##  set up workspace and define variables                               =
##=======================================================================
# required packages
pkgs <- c('terra','dplyr','data.table','tidyterra','ggplot2')
for (p in pkgs){
  if(!require(p, character.only = T)){
    # unzip files to Rpackages/bin 
    install.packages(p)
  }
  library(p,character.only = T)
}

# set dirs
wkdir <- 'W:/sm_work/KCP_confidentialData/weather2'
figdir <- file.path(wkdir,'figs')

##=======================================================================
##  make plots                                                          =
##=======================================================================
# save output - change output png file for different layouts
reso <- 300
png(paste0(figdir,"/surveys_3x2_ghcn_stations.png"),res=reso,height=11,width=8.5,units="in")
#png(paste0(figdir,"/surveys_2x3_ghcn_stations.png"),res=reso,height=8.5,width=11,units="in")

# set plot layout - change par for different layout
par(mfrow = c(3,2))
#par(mfrow = c(2,3))

# define inputs
isos <- c("MWI","TZA","NGA","ETH","UGA","NER")
suids <- c("IHS3","NPS","GHS","ESS","UNPS","ECVMA")

# loop through inputs and plot
for (i in 0:5) {
  iso = isos[i+1]
  #suid = "ESS Y1"
  xydir <- paste0('W:/sm_work/KCP_confidentialData/weather2/',tolower(iso))
  v1 <- vect(paste0(xydir,"/",iso,"_ea_pub.shp"))
  #get stations with data
  stavsel <- vect(paste0(xydir,"/ghcn_sta.shp"))
  dat <- as.data.frame(fread(paste0(xydir,"/",iso,"_ghcn_prcp.csv"),stringsAsFactors=F))
  stadat <- subset(stavsel,ID %in% dat[,1],NSE=T)
  #get map extent
  ctr <- vect("W:/00_GLB/003_boundaries/WB_OFFICIAL_SHP_75130/Data_10mil_Revised_20201116/ne_10m_WB2019_admin_0_countries.shp")
  aoi <- subset(ctr,WB_ISO==iso,NSE=T)
  aoib <- buffer(aoi,100000)
  #make plot
  plot(aoi,border="gray55",ext=ext(aoib),axes = FALSE,mar=c(0.5,0.5,1.5,0.5))
  mtext(suids[i+1],adj=0.5)
  plot(v1,add=T,cex=0.5)
  plot(stavsel,pch=17,add=T,col="orange",cex=1.7)
  plot(stadat,pch=17,add=T,col="blue",cex=1.7)
  box()
}

dev.off()

#useful tips
#https://bookdown.org/ndphillips/YaRrr/arranging-plots-with-parmfrow-and-layout.html
#https://r-charts.com/base-r/margins/  
  

