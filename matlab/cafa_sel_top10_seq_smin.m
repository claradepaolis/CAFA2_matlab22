function [sel, bsl, info] = cafa_sel_top10_seq_smin(smins, naive, blast, config)
%CAFA_SEL_TOP10_SEQ_SMIN CAFA bar top10 sequence-centric Smin
% {{{
%
% [sel, bsl, info] = CAFA_SEL_TOP10_SEQ_SMIN(smins, cnaive, blast, onfig);
%
%   Picks the top10 bootstrapped Smin.
%
% Input
% -----
% [cell]
% smins:      The pre-calculated Smin structures.
%             [char]      [1-by-n]    .id
%             [double]    [B-by-1]    .smin_bst
%             [double]    [B-by-2]    .point_bst
%             [double]    [B-by-1]    .tau_bst
%             [double]    [B-by-1]    .coverage_bst
%
%             See cafa_eval_seq_smin_bst.m
%
% [char]
% config: The file having team information. The file should have the
%         folloing columns:
%
%       * 1. <internalID>
%       * 2. <externalID>
%         3. <teamname>
%       * 4. <type>
%       * 5. <displayname>
%       * 6. <pi>
%
%         Note:
%         1. The starred columns (*) will be used in this function.
%         2. 'type':  'q'  - qualified
%                     'd'  - disqualified
%                     'n'  - Naive model (baseline 1)
%                     'b'  - BLAST model (baseline 2)
%
% Output
% ------
% [cell]
% sel:  The bars and related information ready for plotting:
%
%       [double]
%       .smin_mean      scalar, "bar height".
%
%       [double]
%       .smin_q05       scalar, 5% quantiles.
%
%       [double]
%       .smin_q95       scalar, 95% quantiles.
%
%       [double]
%       .coverage       scalar, averaged coverage.
%
%       [char]
%       .tag            tag of the model.
%
% [cell]
% bsl:  The baseline bars and related information. Each cell has the
%       same structure as 'sel'.
%
% [struct]
% info: Extra information.
%       [cell]
%       .all_mid:   internal ID of all participating models.
%
%       [cell]
%       .top10_mid: internal ID of top 10 models (ranked from 1 to 10)
%
% Dependency
% ----------
%[>]cafa_eval_seq_smin_bst.m
%[>]cafa_read_team_info.m
% }}}

  % check inputs {{{
  if nargin ~= 4
    error('cafa_sel_top10_seq_smin:InputCount', 'Expected 4 inputs.');
  end

  % check the 1st input 'smins' {{{
  validateattributes(smins, {'cell'}, {'nonempty'}, '', 'smins', 1);
  % }}}

  % check the 2nd input 'naive' {{{
  validateattributes(naive, {'char'}, {'nonempty'}, '', 'naive', 2);
  % }}}

  % check the 3rd input 'blast' {{{
  validateattributes(blast, {'char'}, {'nonempty'}, '', 'blast', 3);
  % }}}

  % check the 4th input 'config' {{{
  validateattributes(config, {'char'}, {'nonempty'}, '', 'config', 4);
  [team_id, ext_id, ~, team_type, disp_name, pi_name] = cafa_read_team_info(config);
  % }}}
  % }}}

  % clean up and filter models {{{
  % 1. remove 'disqualified' teams;
  % 2. set aside baseline models;
  % 3. match team names for display.
  % 4. calculate averaged Smin.

  n = numel(smins);
  qld = cell(1, n); % all qualified teams
  bsl = cell(1, 2); % two baseline models
  avg_smins = zeros(1, n);

  kept = 0;

  % parse model number 1, 2 or 3 from external ID {{{
  model_num = cell(1, n);
  for i = 1 : n
    splitted_id = strsplit(ext_id{i}, '-');
    model_num{i} = splitted_id{2};
  end
  % }}}

  for i = 1 : n
    index = find(strcmp(team_id, smins{i}.id));
    if strcmp(smins{i}.id, naive)
      bsl{1}.smin_mean = nanmean(smins{i}.smin_bst);
      bsl{1}.smin_q05  = prctile(smins{i}.smin_bst, 5);
      bsl{1}.smin_q95  = prctile(smins{i}.smin_bst, 95);
      bsl{1}.coverage  = nanmean(smins{i}.coverage_bst);
      bsl{1}.tag = sprintf('%s', disp_name{index});
    elseif strcmp(smins{i}.id, blast)
      bsl{2}.smin_mean = nanmean(smins{i}.smin_bst);
      bsl{2}.smin_q05  = prctile(smins{i}.smin_bst, 5);
      bsl{2}.smin_q95  = prctile(smins{i}.smin_bst, 95);
      bsl{2}.coverage  = nanmean(smins{i}.coverage_bst);
      bsl{2}.tag = sprintf('%s', disp_name{index});
    elseif strcmp(team_type(index), 'q') % qualified teams
      % filtering {{{
      % skip models with 0 coverage
      if ~any(smins{i}.coverage_bst)
        continue;
      end

      % skip models covering less than 10 proteins on average
      if mean(smins{i}.ncovered_bst) < 10
        continue;
      end

      avg_smin = nanmean(smins{i}.smin_bst);

      % skip models with 'NaN' Smin values
      if isnan(avg_smin)
        continue;
      end
      % }}}

      % collecting {{{
      kept = kept + 1;
      qld{kept}.mid       = smins{i}.id; % for temporary useage, will be removed
      qld{kept}.smin_mean = avg_smin;
      qld{kept}.smin_q05  = prctile(smins{i}.smin_bst, 5);
      qld{kept}.smin_q95  = prctile(smins{i}.smin_bst, 95);
      qld{kept}.coverage  = nanmean(smins{i}.coverage_bst);
      avg_smins(kept)     = avg_smin;
      qld{kept}.disp_name = disp_name{index};
      qld{kept}.tag       = sprintf('%s-%s', disp_name{index}, model_num{index});
      qld{kept}.pi_name   = pi_name{index};
      % }}}
    else
      % do nothing
    end
  end
  qld(kept + 1 : end) = []; % truncate the trailing empty cells
  avg_smins(kept + 1 : end) = [];
  % }}}

  % sort averaged Smin and pick the top 10 {{{
  % keep find the next team until
  % 1. find K (= 10) teams, or
  % 2. exhaust the list
  % Note that we only allow one model selected per PI.

  K = 10; % target number of seletect teams
  sel = cell(1, K);
  sel_pi = {};
  [~, index] = sort(avg_smins, 'ascend');
  nsel = 0;
  for i = 1 : numel(qld)
    if ~ismember(qld{index(i)}.pi_name, sel_pi)
      nsel = nsel + 1;
      sel_pi{end + 1} = qld{index(i)}.pi_name;
      sel{nsel} = qld{index(i)};
    end
    if nsel == K
      break;
    end
  end
  if nsel < K
    warning('cafa_sel_top10_seq_smin:LessThenTen', 'Only selected %d models.', nsel);
    sel(nsel + 1 : end) = [];
  end
  % }}}

  % fill-up extra info {{{
  info.all_mid = cell(1, numel(qld));
  for i = 1 : numel(qld)
    info.all_mid{i} = qld{i}.mid;
  end

  info.top10_mid = cell(1, numel(sel));
  for i = 1 : numel(sel)
    info.top10_mid{i} = sel{i}.mid;
    sel{i} = rmfield(sel{i}, 'mid'); % remove temporary field: mid
  end
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Fri 17 Jul 2015 11:42:43 AM E
