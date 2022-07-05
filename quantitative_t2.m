addpath(genpath(pwd)); ccc;

%% =================================================================================================>Section 1
%--------------------Set parameters--------------------%
file_path = 't2data'; 
data_name = 't2data.mat';
data_path = [file_path,filesep,data_name];
roi_name = 'roi'; % ROI name for regional analysis
roi_shape = 'polygon'; % Can be 'polygon', 'rectangle', 'ellipse', 'circle', 'free', 'auto'
roi_subj_name = 'roi_subject'; % ROI name of subject for background removal
bcg_thres = 0.3; % Threshold (normally 0~1) set for backgroud removal
% rot_ang = 90;

%--------------------Read result--------------------%
load(data_path); % img: image series, vtr: TR list
% img = fliplr(imrotate(img,rot_ang)); % Rearrange img_all

%--------------------Get subject ROI for background removal--------------------%
roi_subj = draw_load_roi(file_path, img(:,:,1), roi_subj_name, 'auto', bcg_thres);

%--------------------Perform T1 titting--------------------%
iv=[0.1     -1      50];
lb=[-100    -100    0.5];
ub=[ 100    100     1000];
sz = size(img);
t2map = zeros(sz(1),sz(2));
count = 0;
if ~exist([file_path,filesep,'t2map.mat'],'file') ==1
    roi_subj_vec = roi_subj(:);
    roi_subj_vec(roi_subj_vec==0) = [];
    total_num = length(roi_subj_vec);
    h = waitbar(0, 'T2 fitting in progress, please wait >>>>>>');
    set(h,'unit','normalized','position',[0.4,0.1,0.25,0.08]);
    figure;
    tic;
    for m = 1:sz(1)
        for n = 1:sz(2)     
            if(roi_subj(m,n) == 1)
                % T2 fit function
                t2fcn = @(p,t) p(1)+p(2)*exp(-t/p(3));
                evol = squeeze(img(m,n,:))'; % Evolution curve
                fp = lsqcurvefit(t2fcn, iv, vte, evol, lb, ub);
                t2map(m,n) = fp(3);
                count = count+1;
                if mod(count,200)==0
                    evol_fit = t2fcn(fp,vte);
                    plot(vte,evol,'o',vte,evol_fit,'-')
                    txt_str = ['T2 = ',num2str(t2map(m,n)),' ms'];
                    uicontrol('Style','text','Position',[300 200 150 30],'String',txt_str);
                end
            end
            h = waitbar(count/total_num);
        end
    end
    toc;
    delete(h);
    save([file_path,filesep,'t2map.mat'],'t2map');
else
	load([file_path,filesep,'t2map.mat'], 't2map');
end

%% =================================================================================================>Section 2
%------------------------------Show and save results------------------------------%
cmap_type = hot; % Common options: parula, jet, hot
cbar_rg = [0,150]; % Colorbar scale, in ms
horiz_pos = 0.062; % Adjust the horizontal position of overlaying map, slightly change for different screen
fontsz = 18;
if_overlay = 1;
set(0,'defaultfigurecolor','w');
%------------------------------Show result of whole subject------------------------------%
if if_overlay == 1
    figure, overlay_img(t2map,img(:,:,1),roi_subj,cbar_rg,cmap_type,horiz_pos);
else
    figure, imagesc(t2map),caxis(cbar_rg),colormap(cmap_type);
    colorbar('FontWeight','bold' ,'linewidth',2);
    axis off, set(gca, 'FontWeight','bold','FontSize',fontsz);
end
export_fig(strcat(file_path,filesep,'t2map_',roi_subj_name),'-jpg');
title('T2 map','FontSize',fontsz);

%------------------------------Regional T1 calculation------------------------------%
answ = questdlg('Do you want to draw ROI for regional T2 analysis?', ...
    'Regional T2？', ...
    'No','Yes','No');
switch answ
    case 'Yes'
        roi = draw_load_roi(file_path, img(:,:,1), roi_name, roi_shape);
        for n = 1:size(roi,3)
            t2roi(n) = mean(t2map(roi==1));
        end
        path_str = [file_path,filesep,'t2_',roi_name,'.txt'];
        save_txt(path_str,t2roi);
        roi_map = sum(roi,3);
        if if_overlay == 1
            overlay_img(t2map,img(:,:,1),roi_map,cbar_rg,cmap_type,horiz_pos);
        else
            figure, imagesc(t2map.*roi_map),caxis(cbar_rg),colormap(cmap_type);
            colorbar('FontWeight','bold' ,'linewidth',2);
            axis off, set(gca, 'FontWeight','bold','FontSize',fontsz);
        end
        export_fig(strcat(file_path,filesep,'t2map_',roi_name),'-jpg');
        title('T2 map','FontSize',fontsz);
    case 'No'
        disp('T2 fitting is done!')
end