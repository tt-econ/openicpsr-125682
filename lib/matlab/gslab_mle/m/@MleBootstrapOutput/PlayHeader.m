function PlayHeader( obj, header )
% Private method to display header for bootstrap output
    disp(' ');
    disp(' ');
    disp(header);
    disp(' ');
    fprintf('MODEL: %10s\n', class(obj.model));
    disp(' ');
    fprintf('REPS:                   %15.0f\n', obj.reps);
    disp(' ');
end

