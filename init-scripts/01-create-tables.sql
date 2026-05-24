CREATE TABLE IF NOT EXISTS wells (
    well_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    field_name TEXT,
    region TEXT,
    start_date DATE,
    operator TEXT,
    status TEXT
);

CREATE TABLE IF NOT EXISTS production (
    prod_id SERIAL PRIMARY KEY,
    well_id INT REFERENCES wells(well_id),
    date DATE NOT NULL,
    oil_ton NUMERIC(10,2),
    gas_m3 NUMERIC(12,2),
    water_m3 NUMERIC(12,2),
    energy_kwh NUMERIC(12,2),
    downtime_hours NUMERIC(5,2),
    temperature NUMERIC(5,2),
    pressure NUMERIC(5,2)
);

CREATE TABLE IF NOT EXISTS well_telemetry (
    record_id SERIAL PRIMARY KEY,
    well_id INT REFERENCES wells(well_id),
    timestamp TIMESTAMP,
    pump_speed_rpm NUMERIC(8,2),
    pump_current NUMERIC(8,2),
    pressure_in NUMERIC(8,2),
    pressure_out NUMERIC(8,2),
    temperature NUMERIC(5,2),
    vibration NUMERIC(5,2),
    oil_flow_rate NUMERIC(8,2)
);

CREATE TABLE IF NOT EXISTS well_targets (
    well_id INT REFERENCES wells(well_id),
    date DATE,
    daily_oil_ton NUMERIC(10,2),
    PRIMARY KEY (well_id, date)
);

CREATE TABLE IF NOT EXISTS pumps (
    pump_id SERIAL PRIMARY KEY,
    well_id INT REFERENCES wells(well_id),
    type TEXT,
    install_date DATE,
    manufacturer TEXT,
    model TEXT
);

CREATE TABLE IF NOT EXISTS pump_sensors (
    record_id SERIAL PRIMARY KEY,
    pump_id INT REFERENCES pumps(pump_id),
    timestamp TIMESTAMP,
    temperature NUMERIC(5,2),
    vibration NUMERIC(5,2),
    current NUMERIC(8,2),
    rpm NUMERIC(8,2),
    pressure NUMERIC(8,2)
);

CREATE TABLE IF NOT EXISTS pump_failures (
    failure_id SERIAL PRIMARY KEY,
    pump_id INT REFERENCES pumps(pump_id),
    failure_date TIMESTAMP,
    failure_type TEXT,
    downtime_hours NUMERIC(5,2)
);

CREATE TABLE IF NOT EXISTS deliveries (
    delivery_id SERIAL PRIMARY KEY,
    date DATE,
    source TEXT,
    destination TEXT,
    product_type TEXT,
    volume_ton NUMERIC(10,2),
    cost_usd NUMERIC(10,2),
    delay_hours NUMERIC(6,2),
    distance_km NUMERIC(8,2),
    weather_conditions TEXT,
    driver_id INT,
    vehicle_id INT
);

CREATE TABLE IF NOT EXISTS drivers (
    driver_id SERIAL PRIMARY KEY,
    name TEXT,
    experience_years INT,
    region TEXT
);

CREATE TABLE IF NOT EXISTS vehicles (
    vehicle_id SERIAL PRIMARY KEY,
    plate_number TEXT,
    capacity_ton NUMERIC(8,2),
    fuel_type TEXT
);

CREATE TABLE IF NOT EXISTS oil_stations (
    station_id SERIAL PRIMARY KEY,
    station_name VARCHAR(100),
    latitude FLOAT,
    longitude FLOAT,
    oil_flow_per_day FLOAT
);