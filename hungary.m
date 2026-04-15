figure; hold on
plot(hungary_data.year, hungary_data.low_carbon_share_energy, 'Color', [0.2 0.6 0.2])
plot(hungary_data.year, hungary_data.fossil_share_energy, 'Color', [0.8 0.2 0.2])
plot(hungary_data.year, hungary_data.nuclear_share_energy, 'Color', [0.2 1.0 0.2])
plot(hungary_data.year, hungary_data.wind_share_energy, 'Color', [0.0 0.6 0.8])
plot(hungary_data.year, hungary_data.solar_share_energy, 'Color', [1.0 0.8 0.0])
plot(hungary_data.year, hungary_data.hydro_share_energy, 'Color', [0.0 0.3 0.8])
plot(hungary_data.year, hungary_data.coal_share_energy, 'Color', [0.4 0.2 0.0])
plot(hungary_data.year, hungary_data.gas_share_energy, 'Color', [1.0 0.5 0.0])
plot(hungary_data.year, hungary_data.oil_share_energy, 'Color', [0.7 0.6 0.0])

xlabel('Year')
ylabel('Percentage')
legend('Low-carbon share', 'Fossil share','Nuclear share','Wind share','Solar share','Hydro share','Coal share','Gas share','Oil share')
