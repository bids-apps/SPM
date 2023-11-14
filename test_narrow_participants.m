%
% script based testing for narrow_participants
% participants.json adds a 'meta' field that can be avoided when selecting only some participants
%

bids_dir = [tempname '_bids_test'];
try
  % build minimal BIDS filesystem: participants.json and 1 anat file pair
  system(['mkdir -p ' bids_dir '/sub-{a,b}/ses-{1,2}/anat/']);
  system([   'touch ' bids_dir '/sub-{a,b}/ses-{1,2}/anat/T1.{json,nii.gz}']);
  system(['echo -e ''participant_id\nsub-a\nsub-a\nsub-b\nsub-b'' > '  bids_dir '/participants.tsv']);
  system(['echo ''{ "Name": "test", "BIDSVersion": "1.4.1"}'' > '  bids_dir '/dataset_description.json']);
  system(['echo ''{ "age": { "Description": "xyz" } }'' > '  bids_dir '/participants.json']);

  % get what we built -- matches expectations
  BIDS = spm_BIDS(bids_dir);
  assert(length(BIDS.participants.participant_id) == 4)

  % narrowing works
  BIDS_narrow = narrow_participants(BIDS, {'sub-a'})
  assert(length(BIDS_narrow.participants.participant_id) == 2)
  
  % no change on empty
  BIDS_nochange = narrow_participants(BIDS, {}); % TODO: {{}}?
  assert(length(BIDS_nochange.participants.participant_id) == 4)

catch me
     rmdir(bids_dir,'s')
     rethrow(me)
end
