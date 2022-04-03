function file_index = extract_file_index(dirname, ext, multi)
    if nargin < 3, multi = 0; end

    file_index = {};
    flist = dir(dirname);

    idx = 1;
    for x=1:length(flist)
        if multi == 1
            strs = str_token(flist(x,1).name, '_');
        else
            strs = str_token(flist(x,1).name, '.');
        end
        if(length(strs) >= 2)
            if strcmp(strs{2}, ext) | strcmp(strs{2}, ['0.' ext])
                file_index{idx} = strs{1};
                idx = idx+1;
            end
        end
    end
end   

function strs = str_token(input, delim)
    strs = {};
    idx = 1;
    while(size(input,2) > 2)
        [a, input] = strtok(input, delim);
        strs{idx} = a;
        idx = idx+1;
    end
end

