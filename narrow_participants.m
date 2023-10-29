function BIDS = narrow_participants(BIDS, labels)
% NARROW_PARTICIPANTS - restrict BIDS struct to only requested labels
%

% nothing to do if no labels to change?
if isempty(labels)
   return
end

idx = ismember({BIDS.subjects.name},labels);
BIDS.subjects = BIDS.subjects(idx);

idx = ismember(BIDS.participants.participant_id,labels);
for fn=fieldnames(BIDS.participants)'
  replace = BIDS.participants.(char(fn));
  % BIDS.participants.meta is 1x1. other fields are 1xN
  if(length(replace) < length(idx))
     warning('BIDS participants field "%s" too short: ID idx len %d > number of field values %d; ignored', ...
        char(fn), length(idx), length(replace))
     continue
  end
  BIDS.participants.(char(fn)) = replace(idx);
end

end
