figure; hold on
plot(world_energy.year, world_energy.low_carbon_share_energy, 'Color', [0.2 0.6 0.2])
plot(world_energy.year, world_energy.fossil_share_energy, 'Color', [0.8 0.2 0.2])
plot(world_energy.year, world_energy.nuclear_share_energy, 'Color', [0.5 0.0 0.5])
plot(world_energy.year, world_energy.wind_share_energy, 'Color', [0.0 0.6 0.8])
plot(world_energy.year, world_energy.solar_share_energy, 'Color', [1.0 0.8 0.0])
plot(world_energy.year, world_energy.hydro_share_energy, 'Color', [0.0 0.3 0.8])

xlabel('Year')
ylabel('Percentage')
legend('Low-carbon share', 'Fossil share','Nuclear share','Wind share','Solar share','Hydro share')

%%
% Low carbon
figure; hold on
plot(world_energy.year, world_energy.low_carbon_share_energy, 'Color', [0.2 0.6 0.2])
%plot(world_energy.year, world_energy.fossil_share_energy, 'Color', [0.8 0.2 0.2])
plot(world_energy.year, world_energy.nuclear_share_energy, 'Color', [0.5 0.0 0.5])
plot(world_energy.year, world_energy.wind_share_energy, 'Color', [0.0 0.6 0.8])
plot(world_energy.year, world_energy.solar_share_energy, 'Color', [1.0 0.8 0.0])
plot(world_energy.year, world_energy.hydro_share_energy, 'Color', [0.0 0.3 0.8])

xlabel('Year')
ylabel('Percentage')
%legend('Low-carbon share', 'Fossil share','Nuclear share','Wind share','Solar share','Hydro share')
legend('Low-carbon share', 'Nuclear share','Wind share','Solar share','Hydro share')
