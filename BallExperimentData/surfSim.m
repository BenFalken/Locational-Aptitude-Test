%% Run

classdef surfSim
    properties(Constant)
        %Physics Constants
        gravity = 9.81; %m/s^2
        ballDensity = 0.45/((4/3)*(0.11^3)); %kg/m^3
        airDensity = 1.225; %kg/m^3
        dragCoef = 0.47;
        fricCoef = 0.325;
        % Function Parameters
        x_step = 0.01;
    
        lower_x_lim = 0;
        upper_x_lim = 10;
            
        lower_y_lim = 2;
        upper_y_lim = 5;
        
        x_allowance = 5;
        guess_error = 10;
    end
    methods(Static)
        function importSurfaceStats = loadData(surfaceIndex, figureArray, ballRad)
            surfaceDataPathway = what('RollSurfaces');
            %surfaceDataPathway = surfaceDataPathway.path;
            surfaceDataPathway = '/Users/benfalken/Documents/MATLAB/BallExperimentData/RollSurfaces';
            %disp(surfaceIndex);
            
            %Variable
            ballRad = 0.11; 
            ballVolume = (4/3)*(ballRad^3);
            ballMass = (surfSim.ballDensity)*ballVolume;
            ballCrossArea = pi*(ballRad^2);
            
            x_points = (surfSim.upper_x_lim+surfSim.x_allowance)/surfSim.x_step;
            feature_points = surfSim.upper_x_lim+surfSim.x_allowance;

            %% Create Function

            surfaceDomain = linspace(surfSim.lower_x_lim, surfSim.upper_x_lim + surfSim.x_allowance, x_points);
            randVals = ((surfSim.upper_y_lim-surfSim.lower_y_lim).*abs(rand(1, feature_points)))+surfSim.lower_y_lim;
            %disp(randVals);
            randVals(1) = randVals(2)+abs(rand(1));
            %disp(randVals);
            
            %disp(randVals);
            
            surfaceFit = polyfit(linspace(surfSim.lower_x_lim, surfSim.upper_x_lim+surfSim.x_allowance, feature_points), randVals, feature_points - 1);
            surfaceFunc = polyval(surfaceFit, surfaceDomain);
            surfaceFunc = ((surfaceFunc - surfSim.lower_y_lim)*(((surfSim.upper_y_lim - surfSim.lower_y_lim)/2)/max(abs(surfaceFunc - surfSim.lower_y_lim)))) + surfSim.lower_y_lim;
            

            %% Standardize all functions
            
            diff_surfaceFunc = horzcat(0, diff(surfaceFunc));
            concaveFunc = horzcat(100, abs(diff(diff_surfaceFunc)./surfSim.x_step));
            InflectionIndices = find(concaveFunc < 0.0005);
            downardSlopeIndices = find(diff_surfaceFunc < 0);
            
            %disp(InflectionIndices);
            %disp(downardSlopeIndices);
            
            InflectionPoints = intersect(InflectionIndices, downardSlopeIndices);
            
            %disp(InflectionPoints);
            
            firstX = InflectionPoints(1)*surfSim.x_step;
            %disp(firstX);
                
            surfaceDomain = linspace(surfSim.lower_x_lim+firstX, surfSim.upper_x_lim+firstX, x_points);
            surfaceFunc = polyval(surfaceFit, surfaceDomain);
            %disp(((surfSim.upper_y_lim-surfSim.lower_y_lim)/2)/max(abs(surfaceFunc)));
            surfaceFunc = ((surfaceFunc - surfSim.lower_y_lim)*((surfSim.upper_y_lim-surfSim.lower_y_lim)/2)/max(abs(surfaceFunc))) + surfSim.lower_y_lim;
            % Differentiate AGAIN
            diff_surfaceFunc = horzcat(0, diff(surfaceFunc));
            surfaceDomain = linspace(surfSim.lower_x_lim, surfSim.upper_x_lim, x_points);
            diff_surfaceDomain = horzcat(surfSim.x_step, diff(surfaceDomain));
            
            
            %% Test Enegery Capacity
            
            totalEnergy = ballMass*surfSim.gravity.*surfaceFunc(1); %Total potential energy at x=0
            %disp(totalEnergy);
            potentialEnergy = ballMass*surfSim.gravity.*surfaceFunc; %Potential energy at all points x
            
            
            diffAngles = atan(abs(diff_surfaceFunc./surfSim.x_step)); %Angles of the differentiable slope for all x
            intLen = diff_surfaceDomain./cos(diffAngles); %Lengths of each section of the differentiable function for all x
            
            fricForces = cos(diffAngles).*(surfSim.fricCoef*ballMass*surfSim.gravity.*intLen); %Calculate all friction forces
            summedFric = cumsum(fricForces);
            summedFric(1) = 0;
            %summedFric = horzcat(0, summedFric); %Change?
            summedTotalEnergy = -(potentialEnergy-totalEnergy)-summedFric;

            furthest_pt = find(summedTotalEnergy < 0, 1);
            if furthest_pt == 2
                pts_list = find(summedTotalEnergy < 0);
                for i=2:length(pts_list)
                    if pts_list(i)-pts_list(i-1) > 1
                        furthest_pt = pts_list(i);
                        break
                    end
                end
                %disp(find(summedTotalEnergy < 0));
                %disp(diff_surfaceFunc);
                %disp(diff(surfaceFunc));
            end
            if isempty(furthest_pt) %If somehow there is no stopping pt
                furthest_pt = (surfSim.upper_x_lim/surfSim.x_step);
            end
            if size(furthest_pt, 2) > 1 
                %disp('Hi');
                furthest_pt = furthest_pt(1, 2);
            end
            %disp(furthest_pt);
            
            %% Plot the damned thing
            
            figureArray{surfaceIndex} = figure;
            axes1 = axes('Parent',figureArray{surfaceIndex});
            axis([surfSim.lower_x_lim surfSim.upper_x_lim 0 surfSim.upper_y_lim]);
            %set(gca,'XTick',[], 'YTick', []);
            hold(axes1,'all');
            area(surfaceDomain, surfaceFunc);
            hold on
            scatter(surfaceDomain(furthest_pt), surfaceFunc(furthest_pt));
            saveas(figureArray{surfaceIndex}, ... 
                [surfaceDataPathway '/SurfaceGraph_' num2str(surfaceIndex) '.png'])  % Save the figure
            importSurfaceStats = struct('y_int', surfaceFunc(1), ...
                'abs_min', min(surfaceFunc), ...
                'ball_rad', ballRad, ...
                'furthest_pt_x', surfaceDomain(furthest_pt), ...
                'furthest_pt_y', surfaceFunc(furthest_pt) ...
            );
            % Export Info (Clean up)
            %disp(importSurfaceStats);
            hold off
        end
    end
end