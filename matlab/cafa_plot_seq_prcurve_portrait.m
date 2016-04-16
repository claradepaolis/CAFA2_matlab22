function [] = cafa_plot_seq_prcurve_portrait(pfile, pttl, data, bsl_data, mark_alt)
%CAFA_PLOT_SEQ_PRCURVE_PORTRAIT CAFA plot sequence-centric pr-rc curves (portrait)
% {{{
%
% [] = CAFA_PLOT_SEQ_PRCURVE_PORTRAIT(pttl, data, bsl_data, mark_alt);
%
%   Plots precision-recall curves from given data (including baseline data).
%
% Input
% -----
% (required)
% [char]
% pfile:    The filename of the plot.
%           Note that the file extension must be either 'eps' or 'png'.
%           default: 'png'
%
% [char]
% pttl:     The plot title.
%
% [cell]
% data:     The data containing curves and other information to plot.
%           Each cell has the thing needed for plotting a single curve.
%           .curve      [double]  n x 2, points on the curve
%           .opt_point  [double]  1 x 2, the optimal point (corresp. to Fmax)
%           .alt_point  [double]  1 x 2, the alternative optimal point (corresp. to Smin)
%           .tag        [char]    for the legend of the plot
%
%           See cafa_sel_top_seq_prcurve.m
%
% [cell]
% bsl_data: A 1 x 2 cell containing the information for baselines, i.e.
%           Naive and BLAST. Each cell has the same structure as 'data'.
%
% (optional)
% [logical]
% mark_alt: Toggle for mark alternative points corresp. to optimal Smin on curves.
%           (notes: result generated by early versions might not have .alt_point
%           field in the data structure)
%           default: false.
%
% Output
% ------
% None.
%
% Dependency
% ----------
%[>]embed_canvas.m
%
% See Also
% --------
%[>]cafa_sel_top_seq_prcurve.m
% }}}

  % check inputs {{{
  if nargin < 4 || nargin > 5
    error('cafa_plot_seq_prcurve_portrait:InputCount', 'Expected 4 or 5 inputs.');
  end

  if nargin == 4
    mark_alt = false;
  end

  % check the 1st input 'pfile' {{{
  validateattributes(pfile, {'char'}, {'nonempty'}, '', 'pfile', 1);
  [p, f, e] = fileparts(pfile);
  if isempty(e)
    e = '.png';
  end
  ext = validatestring(e, {'.eps', '.png'}, '', 'pfile', 1);
  if strcmp(ext, '.eps')
    device_op = '-depsc';
  elseif strcmp(ext, '.png')
    device_op = '-dpng';
  end
  % }}}

  % check the 2nd input 'pttl' {{{
  validateattributes(pttl, {'char'}, {}, '', 'pttl', 2);
  % }}}

  % check the 3rd input 'data' {{{
  validateattributes(data, {'cell'}, {'nonempty'}, '', 'data', 3);
  n = numel(data);
  % }}}

  % check the 4th input 'bsl_data' {{{
  validateattributes(bsl_data, {'cell'}, {'numel', 2}, '', 'bsl_data', 4);
  % }}}

  % check the 5th input 'mark_alt' {{{
  validateattributes(mark_alt, {'logical'}, {'nonempty'}, '', 'mark_alt', 5);
  if mark_alt && ~isfield(data{1}, 'alt_point')
    error('cafa_plot_seq_prcurve_portrait:NoAlt', 'No ''alt_point'' field from ''data''.');
  end
  % }}}
  % }}}

  % collect data {{{
  N = n + 2; % number of curves: n curves + 2 baseline curves

  pr  = cell(N, 1);
  rc  = cell(N, 1);
  opt = cell(N, 1);
  tag = cell(N, 1);

  if mark_alt
    alt = cell(N, 1);
  end

  for i = 1 : n
    pr{i}  = data{i}.curve(:, 1);
    rc{i}  = data{i}.curve(:, 2);
    opt{i} = data{i}.opt_point;
    tag{i} = data{i}.tag;

    if mark_alt
      alt{i} = data{i}.alt_point;
    end
  end

  for i = 1 : 2
    pr{n + i}  = bsl_data{i}.curve(:, 1);
    rc{n + i}  = bsl_data{i}.curve(:, 2);
    opt{n + i} = bsl_data{i}.opt_point;
    tag{n + i} = bsl_data{i}.tag;

    if mark_alt
      alt{n + i} = bsl_data{i}.alt_point;
    end
  end
  % }}}

  % determine line styles for each curve {{{
  % !! This block of choosing colors can be customized

  % color {{{
  % find 12 distinguishable colors for plotting
  cmap = colormap('colorcube'); % Matlab 2014b
  clr = zeros(12, 3);
  for i = 1 : 12
    clr(i, :) = cmap((i - 1) * 3 + 1, :);
  end

  if n > 12
    clr = [clr; clr(1 : n - 12, :)];
  else
    clr(n + 1 : end, :) = [];
  end

  clr(n + 1, :) = [1.00, 0.00, 0.00]; % red for Naive
  clr(n + 2, :) = [0.00, 0.00, 1.00]; % blue for BLAST
  % }}}

  % line style and width {{{
  style_ext = {'', '.'};  % supports at most 2 x 12 = 24 curves
  ls = cell(N, 1);        % line style
  lw = zeros(N, 1);       % line width
  for i = 1 : n % model curves
    ls{i} = ['-', style_ext{floor((i - 1) / 12) + 1}];  % line style
    lw(i) = 1.5;                                        % line width
  end
  for i = n + 1 : N
    ls{i} = ':';    % baseline curves
    lw(i) = 3;      % line width
  end
  % }}}
  % }}}

  % plotting {{{
  h = figure('Visible', 'off');
  hold on;

  % default position by MATLAB: [0.1300 0.1100 0.7750 0.8150]
  ax = gca;
  ax.Position      = [0.15 0.30 0.80 0.60];
  ax.XLim          = [0, 1];
  ax.YLim          = [0, 1];
  ax.XLabel.String = 'Recall';
  ax.YLabel.String = 'Precision';
  ax.Title.String  = pttl;

  % plot prcurves of selected models {{{
  ph = zeros(N, 1);
  for i = 1 : N
    ph(i) = plot(rc{i}, pr{i}, ls{i}, 'Color', clr(i, :), 'LineWidth', lw(i, :));
  end
  % }}}

  % plot markers on curves {{{
  for i = 1 : N
    % plot the optimal point (Fmax) on curves
    plot(opt{i}(2), opt{i}(1), '.', 'Color', clr(i, :), 'MarkerSize', 20);
    plot(opt{i}(2), opt{i}(1), 'o', 'Color', clr(i, :), 'MarkerSize', 10);

    if mark_alt
      % plot the alternative point (Smin) on curves
      plot(alt{i}(2), alt{i}(1), 's', 'Color', clr(i, :), 'MarkerSize', 10);
    end
  end
  % }}}

  % plot Fmax mesh curves {{{
  x = 0 : 0.05 : 1.0;
  y = 0 : 0.05 : 1.0;
  [X, Y] = meshgrid(x, y);
  Z = 2 .* X .* Y ./ (X + Y);
  contour(X, Y, Z, 'ShowText', 'on', 'LineColor', [1, 1, 1] * 0.5, 'LineStyle', ':', 'LabelSpacing', 288);
  % }}}

  % suppress (F=xx, C=xx) in legend
  tag = regexprep(tag, ' \(.*\)', '');

  % add legend
  halfN = round(N/2);
  l1 = legend(ph(1:halfN), tag(1:halfN));
  l1.FontSize    = 10;
  l1.Interpreter = 'none';
  l1.Box         = 'off';
  l1.Position    = [0.15, 0.00, 0.40, 0.25];

  ax2 = axes('Position', ax.Position, 'Visible', 'off');
  l2 = legend(ax2, ph(halfN+1:N), tag(halfN+1:N));
  l2.FontSize    = 10;
  l2.Interpreter = 'none';
  l2.Box         = 'off';
  l2.Position    = [0.55, 0.00, 0.40, 0.25];

  embed_canvas(h, 5, 6);
  print(h, pfile, device_op, '-r300');
  close;
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Thu 14 Apr 2016 05:11:48 PM E
