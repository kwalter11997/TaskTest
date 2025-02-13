%% task decider
vec = [zeros(5,1);ones(5,1)]; %vector of 5 zeros and 5 ones (10 trials total)

for row = 31:2:40 %all odds
    decider(:,row) = vec(randperm(10))'; %get a random shuffle of tasks
    decider(:,row+1) = abs(decider(:,row)-1); %make the next row the inverse of that shuffle (to maintain task equality) 
end
    