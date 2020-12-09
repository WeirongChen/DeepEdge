function x = hasfield(s, f)
% x = hasfield(s, field)
%    checks if the struct 's' has the fieldname 'f'. 
%    return x = true if 's' has 'f' field, otherwise returns false.
x = any(ismember( fieldnames(s), f));
end