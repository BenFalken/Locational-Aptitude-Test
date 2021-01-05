%% Run

classdef surfaceCreator
    properties(Constant)
        %Physics Constants
        gravity = 9.81; %m/s^2
        ballDensity = 0.45/((4/3)*(0.11^3)); %kg/m^3
        airDensity = 1.225; %kg/m^3
        dragCoef = 0.47;
        fricCoef = 0.015;
        initVelocity = 0.1;   %m/s
        % Function Parameters
        x_step = 0.01;
    
        lower_x_lim = 0;
        upper_x_lim = 10;
            
        lower_y_lim = 2;
        upper_y_lim = 8;
        
        x_allowance = 0;
        guess_error = 10;
    end
    methods(Static)
        function importSurfaceStats = loadData(surfaceIndex, newlyCreatedSurfacesRecord, ballRad)
            %surfaceDataPathway = what('RollSurfaces');
            %surfaceDataPathway = surfaceDataPathway.path;
            surfaceDataPathway = '/Users/benfalken/Documents/MATLAB/BallExperimentData/RollSurfaces';
            
            %Variable
            ballRad = round(0.1 + abs(0.2*rand(1)), 2); 
            ballVolume = (4/3)*(ballRad^3);
            ballMass = (surfaceCreator.ballDensity)*ballVolume;
            ballCrossArea = pi*(ballRad^2);
            
            x_points = (surfaceCreator.upper_x_lim)/surfaceCreator.x_step;

            %% Create Function

            surfaceDomain = linspace(surfaceCreator.lower_x_lim, surfaceCreator.upper_x_lim + surfaceCreator.x_allowance, x_points);
            
            randIntercept = 8-abs(4*rand(1));
            randDownRate = (randIntercept/2)*abs(surfaceCreator.x_step*rand(1));
            randDownFunc = (randIntercept/2)+(randDownRate*((surfaceDomain-10).^2));
            randAmplitude = abs(4*rand(1));
            randAmplitudeRate = randAmplitude*abs(sin(rand(1)*cos((rand(1)*surfaceDomain)-rand(1))));
            randPeriod = 0.5*pi - (0.5*pi*(rand(1)*surfaceDomain.^2)/100);
            
            surfaceFunc = randDownFunc-(randAmplitudeRate.*sin(randPeriod.*surfaceDomain));
            
            inputforDistanceFunc = @(x) sqrt(1 + (diff(surfaceFunc)).^2);
            
            %distanceFunc = integral(inputforDistanceFunc, 0, inf, 'ArrayValued', true);
            
            thetaFunc = cos(atan(diff(surfaceFunc.*x_points)));
            thetaFunc = [0 thetaFunc];
            
            thetaSum = zeros(1, x_points);
            
            for i=2:x_points
                thetaSum(1, i) = thetaSum(1, i-1)+thetaFunc(i);
            end
            
            workByFric = surfaceCreator.fricCoef*ballMass*surfaceCreator.gravity*thetaSum;
            
            sumOfGainedEnergy =  [0 (surfaceFunc(1) - surfaceFunc(2:end))*ballMass*surfaceCreator.gravity];
            
            initKineticEnergy = 0.5*ballMass*surfaceCreator.initVelocity^2;
            
            totalEnergyAtPoint = initKineticEnergy + sumOfGainedEnergy - workByFric;
            
            firstPointWhereNoMoreEnergy = min(find(totalEnergyAtPoint < 0));
            
            xPointWhereNoMoreEnergy = surfaceDomain(firstPointWhereNoMoreEnergy);

            
            %% Plot the damned thing
            
            axis square
            
            newlyCreatedSurfacesRecord{surfaceIndex} = figure;
            axes1 = axes('Parent',newlyCreatedSurfacesRecord{surfaceIndex});
            axis([0 10 0 10]);
            %set(gca,'XTick',[], 'YTick', []);
            hold(axes1,'all');
            area(surfaceDomain, surfaceFunc);
            
            hold on
            %scatter(surfaceDomain(firstPointWhereNoMoreEnergy), surfaceFunc(firstPointWhereNoMoreEnergy));
            saveas(newlyCreatedSurfacesRecord{surfaceIndex}, ... 
                [surfaceDataPathway '/SurfaceGraph_' num2str(surfaceIndex) '.png'])  % Save the figure
            hold off
            
            importSurfaceStats = struct('y_int', surfaceFunc(1), ...
                'abs_min', min(surfaceFunc), ...
                'down_rate', randDownRate, ...
                'amplitude', randAmplitude, ...
                'ball_rad', ballRad, ...
                'furthest_pt_x', xPointWhereNoMoreEnergy, ...
                'furthest_pt_y', surfaceFunc(firstPointWhereNoMoreEnergy) ...
            );
        end
    end
end