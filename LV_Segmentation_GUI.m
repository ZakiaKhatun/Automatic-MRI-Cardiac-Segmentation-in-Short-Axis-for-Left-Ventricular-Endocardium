function LV_segmentation

clc
clear all
close all

hFig4D = figure('Position',[120 5 660 680],'Units','normalized');
handles.loadFile = uicontrol('Style','push','String','Input','Position',[400 200 50 30],'Callback', @loadFileCallBack);
    function loadFileCallBack(~,~)
        [filename, pathname] = uigetfile({'*.nii'},'Pick a file');
        
        file = strcat(pathname, filename);
        data = load_nii(file);
        im4d = data.img;
        
        [sz_y, sz_x, sz_z, sz_t] = size(im4d);
        
        NumSlices = size(im4d,3);
        NumFrames = size(im4d,4);
        
        handles.axes1 = axes('Units','pixels','Position',[40 390 sz_x sz_y]);
        
        handles.InputSliderSlice = uicontrol('Style','slider','Position',[152 326 sz_z*10 18],'Min',1,'Max',NumSlices,'Value',1,'SliderStep',[1/NumSlices 2/NumSlices],'Callback',@InputSliderSliceCallback);
        handles.InputSliderSlicexListener = addlistener(handles.InputSliderSlice,'Value','PostSet',@(s,e) InputSliceListenerCallBack);
        
        handles.InputSliderFrame = uicontrol('Style','slider','Position',[152 356 sz_z*10 18],'Min',1,'Max',NumFrames,'Value',1,'SliderStep',[1/NumFrames 2/NumFrames],'Callback',@InputSliderSliceCallback);
        handles.InputSliderFramexListener = addlistener(handles.InputSliderFrame,'Value','PostSet',@(s,e) InputFrameListenerCallBack);
        
        handles.Text1 = uicontrol('Style','Text','Position',[25 324 100 20],'String','Current slice');
        handles.Edit1 = uicontrol('Style','Edit','Position',[120 326 20 20],'String','1');
        
        handles.Text2 = uicontrol('Style','Text','Position',[25 354 100 20],'String','Current frame');
        handles.Edit2 = uicontrol('Style','Edit','Position',[120 356 20 20],'String','1');
        
        setappdata(hFig4D,'vol4D',im4d);
        axes(handles.axes1);
        imshow(im4d(:,:,1,1),[])
        guidata(hFig4D,handles);
        
        function InputSliceListenerCallBack
            handles = guidata(gcf);
            im4d = getappdata(hFig4D,'vol4D');
            CurrentSlice = round((get(handles.InputSliderSlice,'Value')));
            CurrentFrame = round((get(handles.InputSliderFrame,'Value')));
            set(handles.Edit1,'String',num2str(CurrentSlice));
            imshow(im4d(:,:,CurrentSlice,CurrentFrame),[],'Parent',handles.axes1);
            guidata(hFig4D,handles);
        end
        function InputSliderSliceCallback(~,~)
            handles = guidata(gcf);
            im4d = getappdata(hFig4D,'vol4D');
            CurrentSlice = round((get(handles.InputSliderSlice,'Value')));
            CurrentFrame = round((get(handles.InputSliderFrame,'Value')));
            set(handles.Edit1,'String',num2str(CurrentSlice));
            imshow(im4d(:,:,CurrentSlice,CurrentFrame),[],'Parent',handles.axes1);
            guidata(hFig4D,handles);
        end
        
        function InputFrameListenerCallBack
            handles = guidata(gcf);
            im4d = getappdata(hFig4D,'vol4D');
            CurrentSlice = round((get(handles.InputSliderSlice,'Value')));
            CurrentFrame = round((get(handles.InputSliderFrame,'Value')));
            set(handles.Edit2,'String',num2str(CurrentFrame));
            imshow(im4d(:,:,CurrentSlice,CurrentFrame),[],'Parent',handles.axes1);
            guidata(hFig4D,handles);
        end
        function InputSliderFrameCallback(~,~)
            handles = guidata(gcf);
            im4d = getappdata(hFig4D,'vol4D');
            CurrentSlice = round((get(handles.InputSliderSlice,'Value')));
            CurrentFrame = round((get(handles.InputSliderFrame,'Value')));
            set(handles.Edit2,'String',num2str(CurrentFrame));
            imshow(im4d(:,:,CurrentSlice,CurrentFrame),[],'Parent',handles.axes1);
            guidata(hFig4D,handles);
        end
        
        handles.segmentLV = uicontrol('Style','push','String','Segment LV','Position',[400 160 80 30],'Callback', @segmentLVCallBack);
        function segmentLVCallBack(~,~)
            [bw4d_LV, ~] = localizeLV(im4d, 1);
            %% segmented
            handles.axes2 = axes('Units','pixels','Position',[sz_x+100 390 sz_x sz_y]);
            handles.SegmentSliderSlice = uicontrol('Style','slider','Position',[sz_x+212 326 sz_z*10 20],'Min',1,'Max',NumSlices,'Value',1,'SliderStep',[1/NumSlices 2/NumSlices],'Callback',@SegmentSliderSliceCallback);
            handles.SegmentSliderSlicexListener = addlistener(handles.SegmentSliderSlice,'Value','PostSet',@(s,e) SegmentSliceListenerCallBack);
            
            handles.SegmentSliderFrame = uicontrol('Style','slider','Position',[sz_x+212 356 sz_z*10 20],'Min',1,'Max',NumFrames,'Value',1,'SliderStep',[1/NumFrames 2/NumFrames],'Callback',@SegmentSliderSliceCallback);
            handles.SegmentSliderFramexListener = addlistener(handles.SegmentSliderFrame,'Value','PostSet',@(s,e) SegmentFrameListenerCallBack);
            
            handles.Text3 = uicontrol('Style','Text','Position',[sz_x+85 324 100 20],'String','Current slice');
            handles.Edit3 = uicontrol('Style','Edit','Position',[sz_x+180 326 20 20],'String','1');
            
            handles.Text4 = uicontrol('Style','Text','Position',[sz_x+85 354 100 20],'String','Current frame');
            handles.Edit4 = uicontrol('Style','Edit','Position',[sz_x+180 356 20 20],'String','1');
            
            setappdata(hFig4D,'LVseg',bw4d_LV);
            axes(handles.axes2);
            imshow(bw4d_LV(:,:,1,1),[])
            guidata(hFig4D,handles);
            
            function SegmentSliceListenerCallBack
                handles = guidata(gcf);
                bw4d_LV = getappdata(hFig4D,'LVseg');
                CurrentSlice = round((get(handles.SegmentSliderSlice,'Value')));
                CurrentFrame = round((get(handles.SegmentSliderFrame,'Value')));
                set(handles.Edit3,'String',num2str(CurrentSlice));
                imshow(bw4d_LV(:,:,CurrentSlice,CurrentFrame),[],'Parent',handles.axes2);
                guidata(hFig4D,handles);
            end
            function SegmentSliderSliceCallback(~,~)
                handles = guidata(gcf);
                bw4d_LV = getappdata(hFig4D,'LVseg');
                CurrentSlice = round((get(handles.SegmentSliderSlice,'Value')));
                CurrentFrame = round((get(handles.SegmentSliderFrame,'Value')));
                set(handles.Edit3,'String',num2str(CurrentSlice));
                imshow(bw4d_LV(:,:,CurrentSlice,CurrentFrame),[],'Parent',handles.axes2);
                guidata(hFig4D,handles);
            end
            
            function SegmentFrameListenerCallBack
                handles = guidata(gcf);
                bw4d_LV = getappdata(hFig4D,'LVseg');
                CurrentSlice = round((get(handles.SegmentSliderSlice,'Value')));
                CurrentFrame = round((get(handles.SegmentSliderFrame,'Value')));
                set(handles.Edit4,'String',num2str(CurrentFrame));
                imshow(bw4d_LV(:,:,CurrentSlice,CurrentFrame),[],'Parent',handles.axes2);
                guidata(hFig4D,handles);
            end
            function SegmentSliderFrameCallback(~,~)
                handles = guidata(gcf);
                bw4d_LV = getappdata(hFig4D,'LVseg');
                CurrentSlice = round((get(handles.SegmentSliderSlice,'Value')));
                CurrentFrame = round((get(handles.SegmentSliderFrame,'Value')));
                set(handles.Edit4,'String',num2str(CurrentFrame));
                imshow(bw4d_LV(:,:,CurrentSlice,CurrentFrame),[],'Parent',handles.axes2);
                guidata(hFig4D,handles);
            end
            
            %% input + segmented
            comb1 = zeros(sz_y, sz_x, 3, sz_z, sz_t);
            for i=1:sz_z
                for j=1:sz_t
                    comb1(:,:,:,i,j) = imfuse(im4d(:,:,i,j),bw4d_LV(:,:,i,j));
                end
            end
            comb1  = uint8(comb1);
            
            handles.axes3 = axes('Units','pixels','Position',[40 86 sz_x sz_y]);
            handles.Comb1SliderSlice = uicontrol('Style','slider','Position',[152 22 sz_z*10 20],'Min',1,'Max',NumSlices,'Value',1,'SliderStep',[1/NumSlices 2/NumSlices],'Callback',@Comb1SliderSliceCallback);
            handles.Comb1SliderSlicexListener = addlistener(handles.Comb1SliderSlice,'Value','PostSet',@(s,e) Comb1SliceListenerCallBack);
            
            handles.Comb1SliderFrame = uicontrol('Style','slider','Position',[152 52 sz_z*10 20],'Min',1,'Max',NumFrames,'Value',1,'SliderStep',[1/NumFrames 2/NumFrames],'Callback',@Comb1SliderSliceCallback);
            handles.Comb1SliderFramexListener = addlistener(handles.Comb1SliderFrame,'Value','PostSet',@(s,e) Comb1FrameListenerCallBack);
            
            handles.Text5 = uicontrol('Style','Text','Position',[25 20 100 20],'String','Current slice');
            handles.Edit5 = uicontrol('Style','Edit','Position',[120 22 20 20],'String','1');
            
            handles.Text6 = uicontrol('Style','Text','Position',[25 50 100 20],'String','Current frame');
            handles.Edit6 = uicontrol('Style','Edit','Position',[120 52 20 20],'String','1');
            
            setappdata(hFig4D,'Comb1', comb1);
            axes(handles.axes3);
            imshow(comb1(:,:,:,1,1),[])
            guidata(hFig4D,handles);
            
            function Comb1SliceListenerCallBack
                handles = guidata(gcf);
                comb1 = getappdata(hFig4D,'Comb1');
                CurrentSlice = round((get(handles.Comb1SliderSlice,'Value')));
                CurrentFrame = round((get(handles.Comb1SliderFrame,'Value')));
                set(handles.Edit5,'String',num2str(CurrentSlice));
                imshow(comb1(:,:,:,CurrentSlice,CurrentFrame),[],'Parent',handles.axes3);
                guidata(hFig4D,handles);
            end
            function Comb1SliderSliceCallback(~,~)
                handles = guidata(gcf);
                comb1 = getappdata(hFig4D,'Comb1');
                CurrentSlice = round((get(handles.Comb1SliderSlice,'Value')));
                CurrentFrame = round((get(handles.Comb1SliderFrame,'Value')));
                set(handles.Edit5,'String',num2str(CurrentSlice));
                imshow(comb1(:,:,:,CurrentSlice,CurrentFrame),[],'Parent',handles.axes3);
                guidata(hFig4D,handles);
            end
            
            function Comb1FrameListenerCallBack
                handles = guidata(gcf);
                comb1 = getappdata(hFig4D,'Comb1');
                CurrentSlice = round((get(handles.Comb1SliderSlice,'Value')));
                CurrentFrame = round((get(handles.Comb1SliderFrame,'Value')));
                set(handles.Edit6,'String',num2str(CurrentFrame));
                imshow(comb1(:,:,:,CurrentSlice,CurrentFrame),[],'Parent',handles.axes3);
                guidata(hFig4D,handles);
            end
            function Comb1SliderFrameCallback(~,~)
                handles = guidata(gcf);
                comb1 = getappdata(hFig4D,'Comb1');
                CurrentSlice = round((get(handles.Comb1SliderSlice,'Value')));
                CurrentFrame = round((get(handles.Comb1SliderFrame,'Value')));
                set(handles.Edit6,'String',num2str(CurrentFrame));
                imshow(comb1(:,:,:,CurrentSlice,CurrentFrame),[],'Parent',handles.axes3);
                guidata(hFig4D,handles);
            end
   
            
            guidata(hFig4D,handles);
        end
    end
end