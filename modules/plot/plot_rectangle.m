function y = plot_rectangle(posiObjCam,widthRec,heigtRec,colorid)
  maxvalu = 1; % unwindowed max value
  posiObjCamX = posiObjCam(1);
  posiObjCamY = posiObjCam(2);
  xLine = [0:1:99]/100*widthRec+posiObjCamX;
  yLine = [0:1:99]/100*heigtRec+posiObjCamY;
  % assign color according to color id
  if colorid == 0
      coloris = 'r';
  elseif colorid == 1
      coloris = 'w';
  elseif colorid == 2
      coloris = 'k';
  else
      coloris = 'r';
  end
  line(xLine,ones(size(xLine))*posiObjCamY,ones(size(xLine))*maxvalu, ...
      'Color',coloris,'LineWidth',1)
  hold on
  line(ones(size(yLine))*posiObjCamX,yLine,ones(size(xLine))*maxvalu, ...
      'Color',coloris,'LineWidth',1)
  line(xLine,ones(size(xLine))*(posiObjCamY+heigtRec), ...
      ones(size(xLine))*maxvalu,'Color',coloris,'LineWidth',1)
  line(ones(size(yLine))*(posiObjCamX+widthRec),yLine, ...
      ones(size(xLine))*maxvalu,'Color',coloris,'LineWidth',1)
end