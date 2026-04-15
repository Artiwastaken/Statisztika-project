%% Összefüggés: population vs energy_per_capita
valid = ~isnan(world_energy.population) & ~isnan(world_energy.energy_per_capita);
pop = world_energy.population(valid);
epc = world_energy.energy_per_capita(valid);

% Person korreláció
R = corrcoef(pop, epc);
fprintf('Person korreláció: %.4f\n', R(1,2));

% Lineáris regresszió
p = polyfit(pop, epc, 1);
fprintf('Regresszió: energy_per_capita = %.4e * population + %.4f\n', p(1), p(2));

% Scatter + illesztés
figure;
scatter(pop, epc, 20, [0.2 0.4 0.8], 'filled')
hold on
x_fit = linspace(min(pop), max(pop), 100);
plot(x_fit, polyval(p, x_fit), 'r-', 'LineWidth', 2)
xlabel('Population')
ylabel('Energy per capita (kWh)')
title(sprintf('Correláció = %.4f', R(1,2)))
legend('Adatpontok', 'Lineáris illesztés', 'Location', 'best')
grid on

figure; hold on
a = normalize(world_energy.population);
b = normalize(world_energy.energy_per_capita);
plot(world_energy.year, a, 'Color', [0.2 0.6 0.2])
plot(world_energy.year, b, 'Color', [0.8 0.2 0.2])
legend('Population','Energy per Capita')
