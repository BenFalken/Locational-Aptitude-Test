%% Run
classdef curveSimulator
    methods(Static)
        function importSurfaceStats = loadData(surfaceIndex, figureArray)
            surfaceDataPathway = what('RollSurfaces');
            surfaceDataPathway = surfaceDataPathway.path;
            disp(surfaceIndex);
            
            %% Define Ball Parameters

            %Constant
            gravity = 9.81; %m/s^2
            ballDensity = 0.45/((4/3)*(0.11^3)); %kg/m^3
            airDensity = 1.225; %kg/m^3
            dragCoef = 0.47;
            
            %Variable
            ballRad = 0.11; 
            ballVolume = (4/3)*(ballRad^3);
            ballMass = ballDensity*ballVolume;
            ballCrossA = pi*(ballRad^2);

            %% Define Function Parameters

            x_step = 0.01;

            lower_x_lim = 0;
            upper_x_lim = 10;
            x_points = upper_x_lim/x_step;
            feature_points = upper_x_lim;
            
            lower_y_lim = 2;
            upper_y_lim = 5;
            
            %% Create Function

            surfaceDomain = linspace(lower_x_lim, upper_x_lim, x_points);
            %randVals = lower_y_lim + abs((upper_y_lim-lower_y_lim)*rand(1, feature_points));
            randVals = ((upper_y_lim-lower_y_lim).*abs(rand(1, feature_points)))+lower_y_lim;
            disp(randVals);
            randVals(1) = randVals(2)+abs(rand(1));
            
            %disp(randVals);
            
            surfaceFit = polyfit(linspace(0, upper_x_lim, feature_points), randVals, feature_points - 1);
            surfaceFunc = polyval(surfaceFit, surfaceDomain);
            surfaceFunc = ((surfaceFunc - lower_y_lim)*(((upper_y_lim - lower_y_lim)/2)/max(abs(surfaceFunc - lower_y_lim)))) + lower_y_lim;
            
            %% Find Stopping Point
            
            % Differentiate
            diff_surfaceFunc = diff(surfaceFunc);
            diff_surfaceDomain = diff(surfaceDomain);
            
            potentialEnergy = ballMass*gravity*surfaceFunc(1);
            
            fricCoef = 0.5;
            diffAngles = atan(abs(diff_surfaceFunc/x_step));
            lenDiff = diff_surfaceDomain./cos(diffAngles);
            
            fricForces = -1.*cos(diffAngles).*(fricCoef*ballMass*gravity*lenDiff);
            kineticForces = -1.*(abs(diff_surfaceFunc)/diff_surfaceFunc)*(sin(diffAngles).*(fricCoef*ballMass*gravity*lenDiff));
            
            added_kineticForces = kineticForces+fricForces;
            totaled_kineticForces = cumsum(added_kineticForces);
            furthest_pt = find(totaled_kineticForces < 0, 1);
            disp(furthest_pt);
            disp(size(furthest_pt));
            if isempty(furthest_pt) 
                furthest_pt = (upper_x_lim/x_step);
            end
            if size(furthest_pt, 2) > 1 
                disp('Hi');
                furthest_pt = furthest_pt(1, 2);
            end
            disp(furthest_pt);
            
            %% Plot the damned thing
            
            figureArray{surfaceIndex} = figure;
            axes1 = axes('Parent',figureArray{surfaceIndex});
            axis([lower_x_lim upper_x_lim 0 upper_y_lim]);
            %set(gca,'XTick',[], 'YTick', []);
            hold(axes1,'all');
            area(surfaceDomain, surfaceFunc);
            hold on
            scatter(surfaceDomain(furthest_pt), surfaceFunc(furthest_pt));
            saveas(figureArray{surfaceIndex}, ... 
                [surfaceDataPathway 'SurfaceGraph_' num2str(surfaceIndex) '.png'])  % Save the figure
            importSurfaceStats = [surfaceFunc(1), min(surfaceFunc), ballRad, ...
                surfaceDomain(furthest_pt), surfaceFunc(furthest_pt)]; % Export Info (Clean up)
            %disp(importSurfaceStats);
            hold off
        end
    end
end