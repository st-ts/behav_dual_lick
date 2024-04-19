% Number of elements in the sequence
N =total_tr;
rng(65);

% Initialize the sequence
seq = zeros(1, N);
seq(1) = randsample([-1, 1], 1);

% Counter for consecutive choices
consecutiveCount = 1;

% Start from the second element
for i = 2:N
    if consecutiveCount == 4
        % Force change if 4 in a row
        seq(i) = -seq(i-1);
        consecutiveCount = 1;
    else
        % Randomly choose the same or different
        choice = randsample([-1, 1], 1);
        if choice == seq(i-1)
            consecutiveCount = consecutiveCount + 1;
        else
            consecutiveCount = 1;
        end
        seq(i) = choice;
    end
end

switches=zeros(1, N);

for i=2:N
    if seq(i)==-1 & seq(i-1)==1
        switches(i)=21;
    elseif seq(i)==1 & seq(i-1)==-1
        switches(i)=12;
    end
end



sw12 = num2str(length(switches(switches==12)));
sw21 = num2str(length(switches(switches==21)));
disp(sw12)
disp(sw21)
% disp(seq);

seq_laser = zeros(1,N);

for i = 2:N
    if (switches(i)==21) & (seq_laser(i-1) == 0)
        seq_laser(i) = randsample([0, 1, 1], 1);
    elseif switches(i)==12 & (seq_laser(i-1) == 0)
        seq_laser(i) = randsample([0, -1, -1], 1);
    end
end


sw12 = num2str(length(seq_laser(seq_laser==1)));
sw21 = num2str(length(seq_laser(seq_laser==-1)));
disp(sw12)
disp(sw21)

