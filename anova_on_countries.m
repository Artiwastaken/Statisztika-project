%% ANOVA fejlett vs fejlodo orszagok: fossil_share_energy (2010-2023)
% Csoportositas: GDP/fő kuszob = 15000 (2011 PPP USD)

clear; clc;

% Parameterek
year_start = 2010;
year_end = 2023;
gdp_per_capita_threshold = 15000;

% Adatforras
data_file = fullfile('energy-data', 'owid-energy-data.csv');
T = readtable(data_file);

% Szükséges oszlopok ellenőrzése
required_vars = {'country','iso_code','year','gdp','population','fossil_share_energy'};
missing_vars = required_vars(~ismember(required_vars, T.Properties.VariableNames));
if ~isempty(missing_vars)
	error('Hianyzik a kovetkezo oszlop(ok): %s', strjoin(missing_vars, ', '));
end

% Csak valódi országok: ISO3 kod (aggregatumok kizárása)
is_country = ~ismissing(T.country) & ...
			 ~ismissing(T.iso_code) & ...
			 ~cellfun('isempty', regexp(T.iso_code, '^[A-Z]{3}$', 'once'));

% Időszűrés
in_window = T.year >= year_start & T.year <= year_end;

% Elemzeshez szukseges sorok
has_needed = ~isnan(T.gdp) & ...
			 ~isnan(T.population) & ...
			 ~isnan(T.fossil_share_energy) & ...
			 T.population > 0;

F = T(is_country & in_window & has_needed, :);

if isempty(F)
	error('Nincs eleg adat a szures utan.');
end

% GDP/fő szamitas
F.gdp_per_capita = F.gdp ./ F.population;

% Orszagszintu stabil csoportositas (median GDP/fő az idoszakban)
[G_country, country_list] = findgroups(F.country);
country_median_gdppc = splitapply(@median, F.gdp_per_capita, G_country);
country_group = repmat("Fejlodo", numel(country_list), 1);
country_group(country_median_gdppc >= gdp_per_capita_threshold) = "Fejlett";

country_group_tbl = table(country_list, country_median_gdppc, country_group, ...
	'VariableNames', {'country','median_gdp_per_capita','development_group'});

% Orszagszintu kimenet: fossil_share_energy atlag (1 sor / orszag)
country_mean_fossil = splitapply(@mean, F.fossil_share_energy, G_country);
country_anova_tbl = table(country_list, country_mean_fossil, ...
	'VariableNames', {'country','mean_fossil_share_energy'});

country_anova_tbl = innerjoin(country_anova_tbl, country_group_tbl, 'Keys', 'country');

% Biztonsagi szures
country_anova_tbl = country_anova_tbl(~isnan(country_anova_tbl.mean_fossil_share_energy), :);

% Csoportminta meretek
is_dev = country_anova_tbl.development_group == "Fejlett";
is_developing = country_anova_tbl.development_group == "Fejlodo";

n_dev = sum(is_dev);
n_developing = sum(is_developing);

if n_dev < 2 || n_developing < 2
	error('Tul kicsi csoportmeret ANOVA-hoz (Fejlett: %d, Fejlodo: %d).', n_dev, n_developing);
end

% Leiro statisztika
mean_dev = mean(country_anova_tbl.mean_fossil_share_energy(is_dev));
mean_developing = mean(country_anova_tbl.mean_fossil_share_energy(is_developing));

fprintf('\n=== Beallitasok ===\n');
fprintf('Idoszak: %d-%d\n', year_start, year_end);
fprintf('GDP/fő kuszob: %.0f\n', gdp_per_capita_threshold);

fprintf('\n=== Minta ===\n');
fprintf('Fejlett orszagok szama: %d\n', n_dev);
fprintf('Fejlodo orszagok szama: %d\n', n_developing);
fprintf('Fejlett atlagos fossil_share_energy: %.3f\n', mean_dev);
fprintf('Fejlodo atlagos fossil_share_energy: %.3f\n', mean_developing);

% Csoportonkenti peldaorszagok
dev_examples = country_anova_tbl.country(is_dev);
deving_examples = country_anova_tbl.country(is_developing);
fprintf('\nPelda fejlett orszagok: %s\n', strjoin(dev_examples(1:min(5, end)), ', '));
fprintf('Pelda fejlodo orszagok: %s\n', strjoin(deving_examples(1:min(5, end)), ', '));

% ANOVA input
y = country_anova_tbl.mean_fossil_share_energy;
grp = categorical(country_anova_tbl.development_group);

% 1) Varianciahomogenitas (Levene)
try
	p_levene = vartestn(y, grp, 'TestType', 'LeveneAbsolute', 'Display', 'off');
catch
	p_levene = NaN;
end

% 2) Normalitas (reziduum, Lilliefors)
overall_mean = mean(y);
residuals = y - overall_mean;
try
	[h_lillie, p_lillie] = lillietest(residuals);
catch
	h_lillie = NaN;
	p_lillie = NaN;
end

fprintf('\n=== Feltetelvizsgalat ===\n');
if isnan(p_lillie)
	fprintf('Normalitas (Lilliefors): nem elerheto ebben a MATLAB kornyezetben.\n');
else
	fprintf('Normalitas p-ertek (Lilliefors): %.4f\n', p_lillie);
end

if isnan(p_levene)
	fprintf('Levene teszt: nem elerheto ebben a MATLAB kornyezetben.\n');
else
	fprintf('Levene p-ertek: %.4f\n', p_levene);
end

% Egyutas ANOVA
[p_anova, anova_tbl, stats] = anova1(y, grp, 'off');

% Effektusmeret (eta^2)
group_means = splitapply(@mean, y, findgroups(grp));
group_counts = splitapply(@numel, y, findgroups(grp));
grand_mean = mean(y);

SS_between = sum(group_counts .* (group_means - grand_mean).^2);
SS_total = sum((y - grand_mean).^2);
eta_sq = SS_between / SS_total;

fprintf('\n=== ANOVA eredmeny ===\n');
fprintf('p-ertek: %.6f\n', p_anova);
fprintf('Eta-negyzet (eta^2): %.4f\n', eta_sq);

if p_anova < 0.05
	fprintf('Kovetkeztetes: szignifikans kulonbseg van a csoportok kozott.\n');
else
	fprintf('Kovetkeztetes: nincs szignifikans kulonbseg a csoportok kozott.\n');
end

% Fallback: ha feltetelek serulnek, nemparametrikus ellenorzes
run_kw = false;
if ~isnan(h_lillie) && h_lillie == 1
	run_kw = true;
end
if ~isnan(p_levene) && p_levene < 0.05
	run_kw = true;
end

if run_kw
	p_kw = kruskalwallis(y, grp, 'off');
	fprintf('\nKruskal-Wallis p-ertek (fallback): %.6f\n', p_kw);
end

% Vizualizacio
figure('Name', 'Fossil share energy: fejlett vs fejlodo');
boxplot(y, grp);
ylabel('Atlagos fossil\_share\_energy (%)');
xlabel('Fejlettsegi csoport');
title(sprintf('ANOVA (orszagatlag, %d-%d)', year_start, year_end));
grid on;

% Post-hoc osszehasonlitas (itt 2 csoportnal megegyezik a fo teszttel,
% de altalanosabban hasznalhato)
figure('Name', 'Post-hoc osszehasonlitas');
multcompare(stats);

% Opcionális export
% writetable(country_anova_tbl, 'anova_country_table.csv');
