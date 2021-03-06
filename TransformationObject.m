classdef TransformationObject < handle
    %TRANSFORMATIONOBJECT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        sampleSize_1
        sampleSize_2       
        start_pt
        end_pt
        angles
        arms
        
        original_pts       
        transformed_pts_tsp        
        transformed_pts_jsp
        error
        trajectory
        meanError
        maxError
        original_pts_polar_phi
        original_pts_polar_r
        dets2
        kond2
    end
    
    methods
        function obj = TransformationObject(start_pt,end_pt, sampleSize_1, sampleSize_2,angles,arms)
            obj.start_pt = start_pt;
            obj.end_pt = end_pt;
            obj.sampleSize_1 = sampleSize_1;
            obj.sampleSize_2 = sampleSize_2;
            obj.angles = angles;
            obj.arms = arms;
            obj.meanError = realmax;
            obj.maxError = realmax;
        end
        function obj = toJSpace(obj)
            obj.original_pts = sample(obj.start_pt,obj.end_pt,-1,obj.sampleSize_1); %sample points from line
            [obj.original_pts_polar_phi,obj.original_pts_polar_r] = cart2pol(obj.original_pts(1,:),(obj.original_pts(2,:)));
            obj.transformed_pts_jsp = (transform(obj.original_pts, obj.angles,obj.arms)); %to joint space
            %berechne determinante von jacobi matrix mit werten(winkeln)
            %aus den spalten von pts_jsp
                      
        end
        function obj = trajGen(obj)
            %build trajectory from transformed points
            obj.trajectory = (trajectory1(obj.transformed_pts_jsp,obj.sampleSize_2)); %in joint space
            for p = 1:length(obj.trajectory)
                point = obj.trajectory(:,p);
                obj.dets2(p) = obj.arms(1)*obj.arms(2)*sin(point(1) + point(2))*cos(point(1)) - obj.arms(1)*obj.arms(2)*cos(point(1) + point(2))*sin(point(1))
                [j,d] = jac(obj.arms(1),obj.arms(2),obj.arms(3),point(1),point(2),point(3));
%                obj.dets2(p) = d;
                if p==1
                    def = obj.dets2(p);
                else
                 def = obj.dets2(p)-obj.dets2(p-1);
                end
            obj.kond2(p) = cond(j);
            end
        end
        function obj = toTSpace(obj)
            obj.transformed_pts_tsp = retransform(obj.arms,obj.trajectory); %from joint space to 
        end
        function obj = computeError(obj)
            ori_pts = [];
            ori_pts(1,:) = sample_multiple(obj.original_pts(1,:), obj.sampleSize_2);
            ori_pts(2,:) = sample_multiple(obj.original_pts(2,:),obj.sampleSize_2);

            trs_pts = obj.transformed_pts_tsp;
            trs_pts(3,:) = [];
            abstand = sqrt(sum((trs_pts - ori_pts).^2));
            abstand_quadriert = sum((trs_pts-ori_pts).^2);
            obj.error = sum((trs_pts-ori_pts).^2);
            obj.meanError = sum(obj.error)/size(obj.error,2);
            obj.maxError = max(max(obj.error));
        end
        function plot(obj)
            
            figure
            ax1 = subplot(2,1,1);
            max_values = find(obj.error > obj.maxError - obj.maxError*0.05);
            min_val = min(max_values);
            plot(obj.error);
            %line(xlim,[min_val,min_val])
            hold on;
            plot(max_values, obj.maxError, 'd');
            str = strcat('Error (meanError=',num2str(double(obj.meanError)),')'); %double precision
            title(ax1,str);

            ax2 = subplot(2,1,2);
            plot(obj.transformed_pts_tsp(1,:),obj.transformed_pts_tsp(2,:));
            hold on;
            plot(obj.original_pts(1,:),obj.original_pts(2,:));
            title(ax2,'Original and Transformed Points');
            hold off;
            
            %berechne determinante an max_values
            figure
            plot(obj.dets2, obj.error)
            title('Determinanten und Fehler')
            
            figure
            plot(obj.kond2,obj.error)
            title('Konditionszahl und Fehler')
            
       end
    
    end
end

