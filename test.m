if isempty(gcp('nocreate'))
    parpool('Threads',2);
end
num_iterations = 8;
[self, update_queue] = ParWaitBar(num_iterations,'Name','Test','visible','off');
parfor (i=1:num_iterations,2)
    pause(1);
    send(update_queue,[]);
end
self.finish();
assert(self.state==num_iterations);
