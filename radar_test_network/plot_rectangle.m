function y = plot_rectangle(posiObjCam,widthRec,heigtRec)
  maxvalu =1.0e+16*5.0;
  posiObjCamX = posiObjCam(1);
  posiObjCamY = posiObjCam(2);
  xLine = [0:1:99]/100*widthRec+posiObjCamX;
  yLine = [0:1:99]/100*heigtRec+posiObjCamY;
  line(xLine,ones(size(xLine))*posiObjCamY,ones(size(xLine))*maxvalu,'Color','r','LineWidth',1)
  hold on
  line(ones(size(yLine))*posiObjCamX,yLine,ones(size(xLine))*maxvalu,'Color','r','LineWidth',1)
  line(xLine,ones(size(xLine))*(posiObjCamY+heigtRec),ones(size(xLine))*maxvalu,'Color','r','LineWidth',1)
  line(ones(size(yLine))*(posiObjCamX+widthRec),yLine,ones(size(xLine))*maxvalu,'Color','r','LineWidth',1)
end