
%% ANOVA kontinensek szerint: low_carbon_share_energy (2010-2023)
% Csoportositas: Eszak-Amerika, Del-Amerika, Europa, Azsia, Oceania
% Egyseg: orszagonkenti idoszaki atlag (1 sor/orszag)

clear; clc;

% Parameterek
year_start = 2010;
year_end   = 2023;

% Adatforras
data_file = fullfile('energy-data', 'owid-energy-data.csv');
T = readtable(data_file);

% Szukseges oszlopok ellenorzese
required_vars = {'country','iso_code','year','low_carbon_share_energy'};
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

% Egyseges lookup tabla osszeallatasa
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

% -------------------------------------------------------------------------
% Adatszures
% -------------------------------------------------------------------------

% Csak valodi orszagok (ISO3 kod, aggregatumok kizarasa)
is_country = ~ismissing(T.country) & ...
             ~ismissing(T.iso_code) & ...
             ~cellfun('isempty', regexp(T.iso_code, '^[A-Z]{3}$', 'once'));

% Idoszak
in_window = T.year >= year_start & T.year <= year_end;

% Szukseges ertekek megvannak
has_needed = ~isnan(T.low_carbon_share_energy);

F = T(is_country & in_window & has_needed, :);

if isempty(F)
    error('Nincs eleg adat a szures utan.');
end

% Kontinens hozzarendelese (innerjoin kizarja a nem terkepezett orszagokat)
F = innerjoin(F, continent_map, 'Keys', 'country');

if isempty(F)
    error('Kontinens-hozzarendeles utan nincs maradt adat. Ellenorizd a nevazonossagot.');
end

% -------------------------------------------------------------------------
% Orszagszintu idoszaki atlag (1 sor / orszag)
% -------------------------------------------------------------------------
[G_country, country_list] = findgroups(F.country);
country_mean_lc   = splitapply(@mean, F.low_carbon_share_energy, G_country);
country_continent = splitapply(@(x) x(1), F.continent, G_country);

country_tbl = table(country_list, country_mean_lc, country_continent, ...
    'VariableNames', {'country', 'mean_low_carbon_share_energy', 'continent'});

country_tbl = country_tbl(~isnan(country_tbl.mean_low_carbon_share_energy), :);

% -------------------------------------------------------------------------
% Leiro statisztika kontinensenkent
% -------------------------------------------------------------------------
fprintf('\n=== Beallitasok ===\n');
fprintf('Valtozo : low_carbon_share_energy\n');
fprintf('Idoszak : %d-%d\n', year_start, year_end);

cont_list = unique(country_tbl.continent);
n_cont    = numel(cont_list);

fprintf('\n=== Minta kontinensenkent ===\n');
fprintf('%-20s  %6s  %10s  %10s\n', 'Kontinens', 'N', 'Atlag (%)', 'Std (%)');
fprintf('%s\n', repmat('-', 1, 52));
for i = 1:n_cont
    mask = strcmp(country_tbl.continent, cont_list{i});
    vals = country_tbl.mean_low_carbon_share_energy(mask);
    fprintf('%-20s  %6d  %10.2f  %10.2f\n', cont_list{i}, numel(vals), mean(vals), std(vals));
end

% Csoportmeret ellenorzese
[G2, ugrps] = findgroups(categorical(country_tbl.continent));
grp_sizes   = splitapply(@numel, country_tbl.mean_low_carbon_share_energy, G2);
if any(grp_sizes < 2)
    small = cellstr(ugrps(grp_sizes < 2));
    error('Tul kicsi csoportmeret ANOVA-hoz: %s', strjoin(small, ', '));
end

% -------------------------------------------------------------------------
% Feltetelvizsgalat
% -------------------------------------------------------------------------
y   = country_tbl.mean_low_carbon_share_energy;
grp = categorical(country_tbl.continent);

% Normalitas (Lilliefors, rezidualison)
group_means_vec = splitapply(@mean, y, G2);   % 1 ertek / csoport
group_resid     = y - group_means_vec(G2);    % visszaterjesztve megfigyelesenkent
try
    [h_lillie, p_lillie] = lillietest(group_resid);
catch
    h_lillie = NaN;  p_lillie = NaN;
end

% Varianciahomogenitas (Levene)
try
    p_levene = vartestn(y, grp, 'TestType', 'LeveneAbsolute', 'Display', 'off');
catch
    p_levene = NaN;
end

fprintf('\n=== Feltetelvizsgalat ===\n');
if isnan(p_lillie)
    fprintf('Normalitas (Lilliefors): nem elerheto ebben a MATLAB kornyezetben.\n');
else
    fprintf('Normalitas p-ertek (Lilliefors, rezidualis): %.4f  [%s]\n', ...
        p_lillie, ternary_str(h_lillie == 0, 'sertetlen', 'SERULT'));
end
if isnan(p_levene)
    fprintf('Levene teszt: nem elerheto ebben a MATLAB kornyezetben.\n');
else
    fprintf('Levene p-ertek (varianciahomogenitas):       %.4f  [%s]\n', ...
        p_levene, ternary_str(p_levene >= 0.05, 'sertetlen', 'SERULT'));
end

% -------------------------------------------------------------------------
% Egyutas ANOVA
% -------------------------------------------------------------------------
[p_anova, anova_tbl, stats] = anova1(y, grp, 'off');

% Eta^2 effektusmeret
group_means  = splitapply(@mean, y, G2);
group_counts = splitapply(@numel, y, G2);
grand_mean   = mean(y);
SS_between   = sum(group_counts .* (group_means - grand_mean).^2);
SS_total     = sum((y - grand_mean).^2);
eta_sq       = SS_between / SS_total;

fprintf('\n=== Egyutas ANOVA eredmeny ===\n');
fprintf('p-ertek : %.6f\n', p_anova);
fprintf('eta^2   : %.4f  (%s effektus)\n', eta_sq, effect_size_label(eta_sq));
if p_anova < 0.05
    fprintf('Kovetkeztetes: SZIGNIFIKANS kulonbseg van a kontinensek kozott (p < 0.05).\n');
else
    fprintf('Kovetkeztetes: nincs szignifikans kulonbseg a kontinensek kozott (p >= 0.05).\n');
end

% -------------------------------------------------------------------------
% Nemparametrikus ellenorzes (Kruskal-Wallis) - ha feltetelek serulnek
% -------------------------------------------------------------------------
run_kw = (~isnan(h_lillie) && h_lillie == 1) || (~isnan(p_levene) && p_levene < 0.05);
if run_kw
    p_kw = kruskalwallis(y, grp, 'off');
    fprintf('\nKruskal-Wallis p-ertek (nemparametrikus ellenorzes): %.6f\n', p_kw);
end

% -------------------------------------------------------------------------
% Vizualizacio 1 – Boxplot
% -------------------------------------------------------------------------
figure('Name', 'Low carbon share energy kontinensenkent', 'NumberTitle', 'off');
boxplot(y, grp);
ylabel('Atlagos low\_carbon\_share\_energy (%)');
xlabel('Kontinens');
title(sprintf('ANOVA – low carbon share energy kontinensenkent (%d–%d)', year_start, year_end));
grid on;

% -------------------------------------------------------------------------
% Vizualizacio 2 – Post-hoc paronkenti osszehasonlitas (Tukey)
% -------------------------------------------------------------------------
figure('Name', 'Post-hoc osszehasonlitas (Tukey)', 'NumberTitle', 'off');
[c_mc, ~, ~, gnames] = multcompare(stats, 'Display', 'on');
title('Tukey post-hoc: low carbon share energy – kontinensek paronkenti osszehasonlitasa');

% Post-hoc tablazat konzolra
fprintf('\n=== Post-hoc paronkenti osszehasonlitas (Tukey) ===\n');
fprintf('%-20s  vs  %-20s  p-ertek\n', 'Csoport 1', 'Csoport 2');
fprintf('%s\n', repmat('-',1,60));
for r = 1:size(c_mc, 1)
    g1 = gnames{c_mc(r,1)};
    g2 = gnames{c_mc(r,2)};
    pv = c_mc(r,6);
    sig = '';
    if pv < 0.001, sig = '***'; elseif pv < 0.01, sig = '**'; elseif pv < 0.05, sig = '*'; end
    fprintf('%-20s  vs  %-20s  %.4f  %s\n', g1, g2, pv, sig);
end

% -------------------------------------------------------------------------
% Segedfuggvenyek
% -------------------------------------------------------------------------
function s = ternary_str(cond, a, b)
    if cond, s = a; else, s = b; end
end

function lbl = effect_size_label(eta2)
    if eta2 < 0.01,      lbl = 'elhanyagolhato';
    elseif eta2 < 0.06,  lbl = 'kis';
    elseif eta2 < 0.14,  lbl = 'kozepes';
    else,                lbl = 'nagy';
    end
end
