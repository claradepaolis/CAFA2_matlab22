function [aucs] = cafa_sel_valid_term_auc(aucs)
%CAFA_SEL_VALID_TERM_AUC CAFA select valid term AUC
% {{{
%
% [aucs] = CAFA_SEL_VALID_TERM_AUC(aucs);
%
%   Filters models that made predictions.
%
% Input
% -----
% [cell]
% aucs:     The collected 'term_auc' structures
%           Each cell has the following fields.
%
%           [char]
%           .id     (Internel) model of the model
%
%           [cell]
%           .term   1-by-m, term ID list
%
%           [double]
%           .auc    1-by-m, AUC per term
%
%           See cafa_collect.m
%
% Output
% ------
% [cell]
% aucs:     The filtered cell 'aucs'.
%
% Dependency
% ----------
%[>]cafa_collect.m
% }}}

  % check inputs {{{
  if nargin ~= 1
    error('cafa_sel_valid_term_auc:InputCount', 'Expected 1 input.');
  end

  % check the 1st input 'aucs' {{{
  validateattributes(aucs, {'cell'}, {'nonempty'}, '', 'aucs', 1);
  n = numel(aucs);
  % }}}
  % }}}

  %filtering {{{
  drop = false(1, n);
  for i = 1 : n
    if strcmp(aucs{i}.id(1), 'B')
      % remove baseline methods
      drop(i) = true;
    elseif all(isnan(aucs{i}.auc) | aucs{i}.auc == 0.5)
      % remove methods having 0.5 (or NaN) as AUC on all terms
      drop(i) = true;
    end
  end
  aucs(drop) = [];
  %}}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University, Bloomington
% Last modified: Fri 17 Jul 2015 11:43:39 AM E
