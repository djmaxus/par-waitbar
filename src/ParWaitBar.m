classdef ParWaitBar < handle
    %PARWAITBAR waitbar wrapper to track progress of parallel loops
    %
    % Copyright (C) 2025 Maksim Elizarev
    %
    % This program is free software: you can redistribute it and/or modify
    % it under the terms of the GNU General Public License as published by
    % the Free Software Foundation, either version 3 of the License, or
    % (at your option) any later version.
    %
    % This program is distributed in the hope that it will be useful,
    % but WITHOUT ANY WARRANTY; without even the implied warranty of
    % MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    % GNU General Public License for more details.
    %
    % You should have received a copy of the GNU General Public License
    % along with this program.  If not, see <https://www.gnu.org/licenses/>.

    properties
        state
        final_state
        wb
        start_time
        stop_button
        last_reported_state
        last_reported_time
        elapsed
    end

    methods
        function [self, update_queue] = ParWaitBar(max_iterations,varargin)
            self.final_state = max_iterations;
            update_queue = parallel.pool.DataQueue;

            if self.final_state == 0
                return;
            end

            self.state = 0;

            msg = sprintf('%u total iterations', max_iterations);

            self.wb = waitbar(self.state, msg, varargin{:});
            self.start_time = tic();

            self.last_reported_state = self.state;
            self.last_reported_time = 0;

            afterEach(update_queue,@(~) self.update());
        end

        function flag = enabled(self)
            flag = self.final_state > 0;
        end

        function update(self)
            if self.final_state == 0
                return;
            end
            self.state = self.state + 1;
            self.elapsed = toc(self.start_time);

            time_to_report = (self.elapsed - self.last_reported_time) > 1;
            state_to_report = (self.state - self.last_reported_state) > self.final_state * 0.01;

            if ~(time_to_report || state_to_report)
                return;
            end

            self.last_reported_state = self.state;
            self.last_reported_time = self.elapsed;

            pace_integral = self.elapsed / self.state;
            eta_estimate = (self.final_state - self.state) * pace_integral;
            eta = duration(seconds(eta_estimate), 'Format', 'hh:mm:ss');
            elapsed_str = duration(seconds(self.elapsed), 'Format', 'hh:mm:ss');
            message = sprintf('iteration %u/%u \n passed: %s | ETA: %s', ...
                self.state, self.final_state, elapsed_str, eta);

            if ~isvalid(self.wb)
                return;
            end
            waitbar(self.state / self.final_state, self.wb, message);
        end

        function finish(self)
            if self.final_state == 0
                return;
            end
            self.elapsed = toc(self.start_time);
            elapsed_str = duration(seconds(self.elapsed), 'Format', 'hh:mm:ss');
            message = sprintf('%u/%u iterations\n in %s', self.state, ...
                self.final_state, elapsed_str);

            if ~isvalid(self.wb)
                return;
            end
            waitbar(1, self.wb, message);
        end

        function delete(self)
            finish(self);
        end
    end
end
