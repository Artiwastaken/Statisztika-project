%% Eves ANOVA: GDP/fo kontinensek szerint (year_start - 2023)
% Minden evre kulon ANOVA: kontinensenként atlagos GDP/fo
% Vizualizacio: eves csoport-kulonbsegek (atlagok + p-ertek + eta^2)

clear; clc;

% -------------------------------------------------------------------------
% Parameterek
% -------------------------------------------------------------------------
year_start = 1980;
year_end   = 2023;

% Adatforras
data_file = fullfile('energy-data', 'owid-energy-data.csv');
T = readtable(data_file);

% Szukseges oszlopok ellenorzese
required_vars = {'country','iso_code','year','gdp','population'};
missing_vars = required_vars(~ismember(required_vars, T.Properties.VariableNames));
if ~isempty(missing_vars)
    error('Hianyzik a kovetkezo oszlop(ok): %s', strjoin(missing_vars, ', '));
end

% -------------------------------------------------------------------------
% Kontinens-lista (orszagnev -> kontinens)
% -------------------------------------------------------------------------
north_america_countries = {
    'Antigua and Barbuda', 'Bahamas', 'Barbados', 'Belize', 'Canada', ...
    'Costa Rica', 'Cuba', 'Dominica', 'Dominican Republic', 'El Salvador', ...
    'Grenada', 'Guatemala', 'Haiti', 'Honduras', 'Jamaica', ...
    'Mexico', 'Nicaragua', 'Panama', 'Puerto Rico', 'Greenland', ...
    'Saint Kitts and Nevis', 'Saint Lucia', 'Saint Vincent and the Grenadines', ...
    'Trinidad and Tobago', 'United States'
}';

south_america_countries = {
    'Argentina', 'Bolivia', 'Brazil', 'Chile', 'Colombia', ...
    'Ecuador', 'Guyana', 'Paraguay', 'Peru', 'Suriname', ...
    'Uruguay', 'Venezuela'
}';

europe_countries = {
    'Albania', 'Andorra', 'Austria', 'Belarus', 'Belgium', ...
    'Bosnia and Herzegovina', 'Bulgaria', 'Croatia', 'Cyprus', 'Czechia', ...
    'Czech Republic', 'Denmark', 'Estonia', 'Finland', 'France', ...
    'Germany', 'Greece', 'Hungary', 'Iceland', 'Ireland', ...
    'Italy', 'Kosovo', 'Latvia', 'Liechtenstein', 'Lithuania', ...
    'Luxembourg', 'Malta', 'Moldova', 'Monaco', 'Montenegro', ...
    'Netherlands', 'North Macedonia', 'Norway', 'Poland', 'Portugal', ...
    'Romania', 'Russia', 'San Marino', 'Serbia', 'Slovakia', ...
    'Slovenia', 'Spain', 'Sweden', 'Switzerland', 'Turkey', 'Turkiye', ...
    'Ukraine', 'United Kingdom'
}';

asia_countries = {
    'Afghanistan', 'Armenia', 'Azerbaijan', 'Bahrain', 'Bangladesh', ...
    'Bhutan', 'Brunei', 'Cambodia', 'China', 'Georgia', ...
    'India', 'Indonesia', 'Iran', 'Iraq', 'Israel', ...
    'Japan', 'Jordan', 'Kazakhstan', 'Kuwait', 'Kyrgyzstan', ...
    'Laos', 'Lebanon', 'Malaysia', 'Maldives', 'Mongolia', ...
    'Myanmar', 'Nepal', 'North Korea', 'Oman', 'Pakistan', ...
    'Palestine', 'Philippines', 'Qatar', 'Saudi Arabia', 'Singapore', ...
    'South Korea', 'Sri Lanka', 'Syria', 'Taiwan', 'Tajikistan', ...
    'Thailand', 'Timor', 'Timor-Leste', 'Turkmenistan', ...
    'United Arab Emirates', 'Uzbekistan', 'Vietnam', 'Yemen'
}';

oceania_countries = {
    'Australia', 'Fiji', 'Kiribati', 'Marshall Islands', 'Micronesia', ...
    'Nauru', 'New Zealand', 'Palau', 'Papua New Guinea', 'Samoa', ...
    'Solomon Islands', 'Tonga', 'Tuvalu', 'Vanuatu'
}';

% Egyseges lookup tabla
n_NA = numel(north_america_countries);
n_SA = numel(south_america_countries);
n_EU = numel(europe_countries);
n_AS = numel(asia_countries);
n_OC = numel(oceania_countries);

continent_map = table( ...
    [north_america_countries; south_america_countries; europe_countries; ...
     asia_countries; oceania_countries], ...
    [repmat({'Eszak-Amerika'}, n_NA, 1); repmat({'Del-Amerika'}, n_SA, 1); ...
     repmat({'Europa'}, n_EU, 1); repmat({'Azsia'}, n_AS, 1); ...
     repmat({'Oceania'}, n_OC, 1)], ...
    'VariableNames', {'country', 'continent'});

cont_names = {'Azsia', 'Del-Amerika', 'Eszak-Amerika', 'Europa', 'Oceania'};
n_cont = numel(cont_names);

% -------------------------------------------------------------------------
% Alapszures (csak valodi orszagok)
% -------------------------------------------------------------------------
is_country = ~ismissing(T.country) & ...
             ~ismissing(T.iso_code) & ...
             ~cellfun('isempty', regexp(T.iso_code, '^[A-Z]{3}$', 'once'));

has_needed = ~isnan(T.gdp) & ~isnan(T.population) & T.population > 0;

T_base = T(is_country & has_needed, :);
T_base.gdp_per_capita = T_base.gdp ./ T_base.population;

% Kontinens hozzarendeles egyszer, az egesz adathalmazra
T_mapped = innerjoin(T_base, continent_map, 'Keys', 'country');

% -------------------------------------------------------------------------
% Eves ANOVA ciklus
% -------------------------------------------------------------------------
years = (year_start:year_end)';
n_years = numel(years);

% Eredmenyek tarolasa
p_values         = NaN(n_years, 1);
eta_sq           = NaN(n_years, 1);
cont_means       = NaN(n_years, n_cont);   % sor=ev, oszlop=kontinens
cont_stds        = NaN(n_years, n_cont);
cont_ns          = NaN(n_years, n_cont);

fprintf('\n=== Eves ANOVA: GDP/fo kontinensenkent ===\n');
fprintf('Idoszak: %d - %d\n', year_start, year_end);
fprintf('\n%-6s  %10s  %8s\n', 'Ev', 'p-ertek', 'eta^2');
fprintf('%s\n', repmat('-', 1, 30));

for yi = 1:n_years
    yr = years(yi);
    F_yr = T_mapped(T_mapped.year == yr, :);

    if isempty(F_yr)
        continue;
    end

    % Kontinensenként: orszagonkenti atlag (1 ev -> csak 1 ertek/orszag,
    % de vannak adathianyos evek, ezert megtartjuk a splitapply-t)
    [G_c, ~] = findgroups(categorical(F_yr.continent));
    ugrps_yr = unique(F_yr.continent);

    y_yr  = F_yr.gdp_per_capita;
    grp_yr = categorical(F_yr.continent);

    % Csoportmeret ellenorzese (min 2/csoport az ANOVA-hoz)
    grp_sz = splitapply(@numel, y_yr, G_c);
    if any(grp_sz < 2) || numel(unique(cellstr(ugrps_yr))) < 2
        continue;
    end

    % ANOVA (nepesseg-sulyozott)
    pop_yr = F_yr.population;
    try
        tbl_anova = table(grp_yr, y_yr, pop_yr, 'VariableNames', {'continent', 'gdp_per_capita', 'pop'});
        lm_yr = fitlm(tbl_anova, 'gdp_per_capita ~ continent', 'Weights', tbl_anova.pop);
        at_yr = anova(lm_yr);
        p_yr  = at_yr.pValue(1);
    catch
        continue;
    end

    % Eta^2 (nepesseg-sulyozott)
    grand_m_w = sum(pop_yr .* y_yr) / sum(pop_yr);
    SS_t_w = sum(pop_yr .* (y_yr - grand_m_w).^2);
    SS_b_w = 0;
    ugrps2 = unique(cellstr(grp_yr));
    for ci2 = 1:numel(ugrps2)
        mask_c2 = strcmp(cellstr(grp_yr), ugrps2{ci2});
        pop_c2  = pop_yr(mask_c2);
        y_c2    = y_yr(mask_c2);
        if sum(pop_c2) > 0
            mean_c2 = sum(pop_c2 .* y_c2) / sum(pop_c2);
            SS_b_w  = SS_b_w + sum(pop_c2) * (mean_c2 - grand_m_w)^2;
        end
    end
    eta2_yr = SS_b_w / SS_t_w;

    p_values(yi) = p_yr;
    eta_sq(yi)   = eta2_yr;

    fprintf('%-6d  %10.6f  %8.4f\n', yr, p_yr, eta2_yr);

    % Csoport-atlagok mentese (rogzitett sorrend: cont_names) – nepesseg-sulyozott
    for ci = 1:n_cont
        mask_c  = strcmp(cellstr(grp_yr), cont_names{ci});
        if sum(mask_c) >= 1
            pop_c   = pop_yr(mask_c);
            tot_pop = sum(pop_c);
            if tot_pop > 0
                cont_means(yi, ci) = sum(pop_c .* y_yr(mask_c)) / tot_pop;
                w_c = pop_c / tot_pop;
                cont_stds(yi, ci)  = sqrt(sum(w_c .* (y_yr(mask_c) - cont_means(yi, ci)).^2));
                cont_ns(yi, ci)    = sum(mask_c);
            end
        end
    end
end

% -------------------------------------------------------------------------
% Vizualizacio – egy tabfules figure (4 ful)
% -------------------------------------------------------------------------
colors = lines(n_cont);

fig = figure('Name', sprintf('Eves ANOVA GDP/fo (%d-%d)', year_start, year_end), ...
             'NumberTitle', 'off', 'Position', [80 80 1000 620]);
tg = uitabgroup(fig, 'Units', 'normalized', 'Position', [0 0 1 1]);

% --- Tab 1: GDP/fo eves atlagok ---
tab1 = uitab(tg, 'Title', 'GDP/fo atlagok');
ax1  = axes(tab1);
hold(ax1, 'on');
for ci = 1:n_cont
    valid = ~isnan(cont_means(:, ci));
    if sum(valid) < 2, continue; end
    plot(ax1, years(valid), cont_means(valid, ci), ...
        '-o', 'Color', colors(ci,:), 'LineWidth', 1.8, 'MarkerSize', 4, ...
        'DisplayName', cont_names{ci});
end
hold(ax1, 'off');
xlabel(ax1, 'Ev');
ylabel(ax1, 'Atlagos GDP/fo (2011 PPP USD)');
title(ax1, sprintf('GDP/fo kontinensenkent (%d–%d)', year_start, year_end));
legend(ax1, 'Location', 'northwest');
grid(ax1, 'on');

% --- Tab 2: ANOVA p-ertek ---
tab2 = uitab(tg, 'Title', 'p-ertekek');
ax2  = axes(tab2);
valid_p = ~isnan(p_values);
bar(ax2, years(valid_p), p_values(valid_p), 'FaceColor', [0.4 0.6 0.9], 'EdgeColor', 'none');
hold(ax2, 'on');
yline(ax2, 0.05, '--r', 'LineWidth', 1.5, 'Label', 'p = 0.05', ...
      'LabelHorizontalAlignment', 'left');
hold(ax2, 'off');
xlabel(ax2, 'Ev');
ylabel(ax2, 'p-ertek (ANOVA)');
title(ax2, sprintf('Eves ANOVA p-ertekek: GDP/fo kontinensenkent (%d–%d)', year_start, year_end));
ylim(ax2, [0, max([0.1; p_values(valid_p)]) * 1.1]);
grid(ax2, 'on');

% --- Tab 3: Eta^2 ---
tab3 = uitab(tg, 'Title', 'Eta^2');
ax3  = axes(tab3);
valid_e = ~isnan(eta_sq);
plot(ax3, years(valid_e), eta_sq(valid_e), '-s', 'Color', [0.2 0.6 0.3], ...
     'LineWidth', 1.8, 'MarkerSize', 5);
hold(ax3, 'on');
yline(ax3, 0.14, ':k', 'LineWidth', 1.2, 'Label', 'nagy effektus (0.14)', ...
      'LabelHorizontalAlignment', 'left');
yline(ax3, 0.06, '--k', 'LineWidth', 1.0, 'Label', 'kozepes (0.06)', ...
      'LabelHorizontalAlignment', 'left');
hold(ax3, 'off');
xlabel(ax3, 'Ev');
ylabel(ax3, 'eta^2');
title(ax3, sprintf('Effektusmeret (eta^2) (%d–%d)', year_start, year_end));
ylim(ax3, [0, min(1, max(eta_sq(valid_e)) * 1.15)]);
grid(ax3, 'on');

% --- Tab 4: Heatmap – nepesseg-sulyozott relativ elteres ---
tab4 = uitab(tg, 'Title', 'Heatmap (sulyozott)');
ax4  = axes(tab4);
rel_diff = NaN(n_years, n_cont);
for yi = 1:n_years
    row = cont_means(yi, :);
    if all(isnan(row)), continue; end
    gm = nanmean(row);
    if gm == 0, continue; end
    rel_diff(yi, :) = (row - gm) / gm * 100;
end
valid_rows = ~all(isnan(rel_diff), 2);
if sum(valid_rows) >= 2
    imagesc(ax4, rel_diff(valid_rows, :));
    colormap(ax4, redblue_colormap());
    colorbar(ax4);
    set(ax4, 'XTick', 1:n_cont, 'XTickLabel', cont_names, 'XTickLabelRotation', 30);
    yrs_valid = years(valid_rows);
    ytick_step = max(1, floor(numel(yrs_valid) / 10));
    set(ax4, 'YTick', 1:ytick_step:numel(yrs_valid), ...
             'YTickLabel', yrs_valid(1:ytick_step:end));
    xlabel(ax4, 'Kontinens');
    ylabel(ax4, 'Ev');
    title(ax4, {'GDP/fo relativ elteres a nepesseg-sulyozott kontinens-atlagtol (%)'; ...
               sprintf('(%d–%d)', year_start, year_end)});
    clim_val = max(abs(rel_diff(valid_rows,:)), [], 'all', 'omitnan');
    if ~isnan(clim_val) && clim_val > 0
        clim(ax4, [-clim_val, clim_val]);
    end
end

fprintf('\nKesz.\n');

% -------------------------------------------------------------------------
% Segedfuggvenyek
% -------------------------------------------------------------------------
function cmap = redblue_colormap()
    % Egyszerű piros-feher-kek szimmetrikus szinkeppaletta
    n = 64;
    half = n / 2;
    r = [linspace(0, 1, half), ones(1, half)];
    g = [linspace(0, 1, half), linspace(1, 0, half)];
    b = [ones(1, half), linspace(1, 0, half)];
    cmap = [r(:), g(:), b(:)];
end
