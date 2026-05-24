CREATE OR REPLACE VIEW production_dashboard AS
SELECT 
    p.prod_id,
    p.well_id,
    w.name AS well_name,
    w.field_name,
    w.region,
    w.operator,
    w.status,
    p.date,
    p.oil_ton,
    p.gas_m3,
    p.water_m3,
    p.energy_kwh,
    p.downtime_hours,
    ROUND((p.downtime_hours / 24 * 100), 2) AS downtime_percent,
    p.temperature,
    p.pressure,
    AVG(p.oil_ton) OVER (PARTITION BY p.well_id ORDER BY p.date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS oil_ma_3d,
    CASE 
        WHEN t.daily_oil_ton IS NOT NULL AND p.oil_ton >= t.daily_oil_ton THEN 'Achieved'
        WHEN t.daily_oil_ton IS NOT NULL THEN 'Below Target'
        ELSE 'No Target'
    END AS target_status,
    ROUND((p.oil_ton / NULLIF(t.daily_oil_ton, 0) * 100), 2) AS target_completion_pct
FROM production p
JOIN wells w ON p.well_id = w.well_id
LEFT JOIN well_targets t ON p.well_id = t.well_id AND p.date = t.date
WHERE p.oil_ton > 0 OR (p.oil_ton = 0 AND w.status = 'suspended');


CREATE OR REPLACE VIEW well_statistics AS
SELECT 
    w.well_id,
    w.name,
    w.field_name,
    w.region,
    w.operator,
    w.status,
    COUNT(p.date) AS days_producing,
    ROUND(AVG(p.oil_ton), 2) AS avg_daily_oil,
    ROUND(STDDEV(p.oil_ton), 2) AS std_daily_oil,
    ROUND(SUM(p.oil_ton), 2) AS total_oil,
    ROUND(AVG(p.gas_m3), 2) AS avg_gas,
    ROUND(AVG(p.water_m3), 2) AS avg_water,
    ROUND(AVG(p.energy_kwh), 2) AS avg_energy,
    ROUND(AVG(p.downtime_hours), 2) AS avg_downtime,
    ROUND(AVG(p.downtime_hours) / 24 * 100, 2) AS avg_downtime_pct,
    ROUND(AVG(p.temperature), 2) AS avg_temperature,
    ROUND(AVG(p.pressure), 2) AS avg_pressure,
    ROUND(AVG(p.oil_ton) / NULLIF(AVG(p.energy_kwh), 0) * 1000, 4) AS oil_per_energy_kwh
FROM wells w
LEFT JOIN production p ON w.well_id = p.well_id
WHERE p.date IS NOT NULL
GROUP BY w.well_id, w.name, w.field_name, w.region, w.operator, w.status;


CREATE OR REPLACE VIEW forecast_dashboard AS
SELECT 
    w.well_id,
    w.name AS well_name,
    w.region,
    p.date,
    p.oil_ton AS actual_oil,
    t.daily_oil_ton AS target_oil,
    NULL AS predicted_oil,
    NULL AS prediction_error
FROM production p
JOIN wells w ON p.well_id = w.well_id
LEFT JOIN well_targets t ON p.well_id = t.well_id AND p.date = t.date;


CREATE OR REPLACE VIEW telemetry_analysis AS
SELECT 
    wt.well_id,
    w.name AS well_name,
    DATE(wt.timestamp) AS date,
    EXTRACT(HOUR FROM wt.timestamp) AS hour,
    AVG(wt.pump_speed_rpm) AS avg_pump_speed,
    AVG(wt.pump_current) AS avg_pump_current,
    AVG(wt.pressure_in) AS avg_pressure_in,
    AVG(wt.pressure_out) AS avg_pressure_out,
    AVG(wt.temperature) AS avg_temperature,
    AVG(wt.vibration) AS avg_vibration,
    AVG(wt.oil_flow_rate) AS avg_flow_rate,
    MAX(wt.oil_flow_rate) AS max_flow_rate,
    MIN(wt.oil_flow_rate) AS min_flow_rate,
    STDDEV(wt.oil_flow_rate) AS flow_rate_stddev
FROM well_telemetry wt
JOIN wells w ON wt.well_id = w.well_id
GROUP BY wt.well_id, w.name, DATE(wt.timestamp), EXTRACT(HOUR FROM wt.timestamp);


CREATE OR REPLACE VIEW pump_failure_analysis AS
SELECT 
    p.pump_id,
    p.well_id,
    w.name AS well_name,
    p.type AS pump_type,
    p.manufacturer,
    p.install_date,
    pf.failure_id,
    pf.failure_date,
    pf.failure_type,
    pf.downtime_hours,
    EXTRACT(DAY FROM (pf.failure_date - p.install_date)) AS days_to_failure,
    ps.temperature AS last_temp,
    ps.vibration AS last_vibration,
    ps.current AS last_current,
    ps.rpm AS last_rpm,
    ps.pressure AS last_pressure
FROM pumps p
JOIN wells w ON p.well_id = w.well_id
JOIN pump_failures pf ON p.pump_id = pf.pump_id
LEFT JOIN pump_sensors ps ON p.pump_id = ps.pump_id 
    AND ps.timestamp >= pf.failure_date - INTERVAL '1 hour'
    AND ps.timestamp <= pf.failure_date;


CREATE OR REPLACE VIEW deliveries_analysis AS
SELECT 
    d.delivery_id,
    d.date,
    d.source,
    d.destination,
    d.product_type,
    d.volume_ton,
    d.cost_usd,
    d.delay_hours,
    d.distance_km,
    d.weather_conditions,
    ROUND(d.cost_usd / NULLIF(d.distance_km, 0), 2) AS cost_per_km,
    ROUND(d.volume_ton / NULLIF(d.distance_km, 0), 3) AS volume_per_km,
    ROUND(d.delay_hours / NULLIF(d.distance_km, 0) * 100, 2) AS delay_per_100km,
    dr.name AS driver_name,
    dr.experience_years,
    dr.region AS driver_region,
    v.plate_number,
    v.capacity_ton,
    v.fuel_type,
    CASE 
        WHEN d.delay_hours = 0 THEN 'On Time'
        WHEN d.delay_hours <= 1 THEN 'Minor Delay'
        WHEN d.delay_hours <= 3 THEN 'Moderate Delay'
        ELSE 'Severe Delay'
    END AS delay_category
FROM deliveries d
LEFT JOIN drivers dr ON d.driver_id = dr.driver_id
LEFT JOIN vehicles v ON d.vehicle_id = v.vehicle_id;


CREATE OR REPLACE VIEW daily_production_summary AS
SELECT 
    p.date,
    COUNT(DISTINCT p.well_id) AS active_wells,
    ROUND(SUM(p.oil_ton), 2) AS total_oil,
    ROUND(SUM(p.gas_m3), 2) AS total_gas,
    ROUND(SUM(p.water_m3), 2) AS total_water,
    ROUND(SUM(p.energy_kwh), 2) AS total_energy,
    ROUND(AVG(p.downtime_hours), 2) AS avg_downtime,
    ROUND(AVG(p.temperature), 2) AS avg_temperature,
    ROUND(AVG(p.pressure), 2) AS avg_pressure,
    ROUND(SUM(p.oil_ton) / NULLIF(SUM(p.energy_kwh), 0) * 1000, 4) AS oil_efficiency
FROM production p
WHERE p.oil_ton > 0
GROUP BY p.date
ORDER BY p.date;


CREATE OR REPLACE VIEW regional_statistics AS
SELECT 
    w.region,
    COUNT(DISTINCT w.well_id) AS total_wells,
    COUNT(DISTINCT CASE WHEN w.status = 'active' THEN w.well_id END) AS active_wells,
    ROUND(AVG(p.oil_ton), 2) AS avg_daily_oil_per_well,
    ROUND(SUM(p.oil_ton), 2) AS total_oil,
    ROUND(AVG(p.downtime_hours), 2) AS avg_downtime,
    ROUND(AVG(p.downtime_hours) / 24 * 100, 2) AS avg_downtime_pct,
    ROUND(SUM(p.oil_ton) / NULLIF(SUM(p.energy_kwh), 0) * 1000, 4) AS efficiency
FROM wells w
LEFT JOIN production p ON w.well_id = p.well_id
GROUP BY w.region
ORDER BY total_oil DESC;


CREATE OR REPLACE VIEW driver_kpi AS
SELECT 
    d.driver_id,
    d.name,
    d.experience_years,
    d.region,
    COUNT(del.delivery_id) AS total_deliveries,
    ROUND(AVG(del.delay_hours), 2) AS avg_delay_hours,
    ROUND(SUM(del.volume_ton), 2) AS total_volume,
    ROUND(AVG(del.cost_per_km), 2) AS avg_cost_per_km,
    ROUND(SUM(del.cost_usd), 2) AS total_cost,
    ROUND(AVG(del.volume_ton / NULLIF(del.distance_km, 0)), 3) AS avg_volume_per_km,
    ROUND(
        (1 - (AVG(del.delay_hours) / 5)) * 0.6 + 
        (1 - (AVG(del.cost_per_km) / 20)) * 0.4, 
        2
    ) * 100 AS efficiency_score
FROM drivers d
LEFT JOIN deliveries del ON d.driver_id = del.driver_id
GROUP BY d.driver_id, d.name, d.experience_years, d.region
HAVING COUNT(del.delivery_id) > 0
ORDER BY efficiency_score DESC;


CREATE OR REPLACE VIEW failure_statistics AS
SELECT 
    pf.failure_type,
    COUNT(*) AS failure_count,
    ROUND(AVG(pf.downtime_hours), 2) AS avg_downtime,
    ROUND(SUM(pf.downtime_hours), 2) AS total_downtime,
    p.type AS pump_type,
    p.manufacturer
FROM pump_failures pf
JOIN pumps p ON pf.pump_id = p.pump_id
GROUP BY pf.failure_type, p.type, p.manufacturer
ORDER BY failure_count DESC;