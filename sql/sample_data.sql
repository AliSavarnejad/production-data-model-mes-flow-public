-- Sample data for IT/OT portfolio demonstration
-- Scenario: Machine M001 packaging line, 2026-06-01
-- ALM-304 fault event at 08:30, cleared at 08:42
-- Dataset is intentionally small and synthetic
-- Not intended to represent real production performance

PRAGMA foreign_keys = ON;

INSERT INTO machines (
id,
machine_id,
machine_name,
line_name,
area_name,
plc_type,
opcua_endpoint,
is_active
) VALUES
(
1,
'M001',
'Packaging Machine 1',
'Packaging Line',
'Production Area A',
'Siemens S7-1500',
'opc.tcp://machine01.local:4840',
1
),
(
2,
'M002',
'Assembly Station 1',
'Assembly Line',
'Production Area B',
'Siemens S7-1200',
'opc.tcp://machine02.local:4840',
1
);

INSERT INTO production_orders (
id,
order_number,
machine_db_id,
product_code,
product_name,
planned_quantity,
order_status,
planned_start_utc,
planned_end_utc,
actual_start_utc,
actual_end_utc
) VALUES
(
1,
'ORD-2026-001',
1,
'PKG-A',
'Packaging Part A',
1000,
'running',
'2026-06-01 06:00:00+00:00',
'2026-06-01 14:00:00+00:00',
'2026-06-01 06:05:00+00:00',
NULL
),
(
2,
'ORD-2026-002',
2,
'ASM-B',
'Assembly Part B',
500,
'planned',
'2026-06-01 14:00:00+00:00',
'2026-06-01 22:00:00+00:00',
NULL,
NULL
);

INSERT INTO cycle_records (
id,
machine_db_id,
order_db_id,
cycle_counter,
cycle_start_utc,
cycle_end_utc,
cycle_time_ms,
produced_quantity,
source_tag,
description
) VALUES
(
1,
1,
1,
15241,
'2026-06-01 06:05:05+00:00',
'2026-06-01 06:05:10+00:00',
5000,
1,
'Machine01.Production.CycleCounter',
'Normal production cycle for ORD-2026-001.'
),
(
2,
1,
1,
15242,
'2026-06-01 06:05:10+00:00',
'2026-06-01 06:05:15+00:00',
5000,
1,
'Machine01.Production.CycleCounter',
'Normal production cycle for ORD-2026-001.'
),
(
3,
1,
1,
15243,
'2026-06-01 08:28:55+00:00',
'2026-06-01 08:29:01+00:00',
6000,
1,
'Machine01.Production.CycleCounter',
'Slower production cycle before the ALM-304 fault window.'
),
(
4,
2,
2,
41001,
'2026-06-01 13:45:00+00:00',
'2026-06-01 13:45:03+00:00',
3000,
0,
'Machine02.Production.CycleCounter',
'Setup or test cycle with no produced output.'
);

INSERT INTO alarm_events (
id,
machine_db_id,
order_db_id,
alarm_code,
alarm_message,
alarm_category,
severity,
alarm_start_utc,
alarm_end_utc,
acknowledged_at_utc,
acknowledged_by,
source_tag,
description
) VALUES
(
1,
1,
1,
'ALM-120',
'Low air pressure warning',
'process',
'warning',
'2026-06-01 07:15:00+00:00',
'2026-06-01 07:18:00+00:00',
NULL,
NULL,
'Machine01.Alarms.ActiveAlarmCode',
'Temporary low air pressure warning during production.'
),
(
2,
1,
1,
'ALM-304',
'Jam detected at packaging station',
'process',
'critical',
'2026-06-01 08:30:00+00:00',
'2026-06-01 08:42:00+00:00',
'2026-06-01 08:31:00+00:00',
'operator_01',
'Machine01.Alarms.ActiveAlarmCode',
'Critical process alarm during production order ORD-2026-001.'
),
(
3,
2,
2,
'ALM-010',
'Safety gate warning',
'safety',
'warning',
'2026-06-01 13:45:00+00:00',
'2026-06-01 13:48:00+00:00',
'2026-06-01 13:46:00+00:00',
'operator_02',
'Machine02.Alarms.ActiveAlarmCode',
'Safety warning during setup before planned production.'
);

INSERT INTO energy_readings (
id,
machine_db_id,
order_db_id,
reading_start_utc,
reading_end_utc,
power_kw_avg,
energy_kwh,
reading_source,
source_tag,
description
) VALUES
(
1,
1,
1,
'2026-06-01 06:05:00+00:00',
'2026-06-01 06:10:00+00:00',
12.5,
1.04,
'opcua',
'Machine01.Energy.Power_kW',
'Normal production energy reading for ORD-2026-001.'
),
(
2,
1,
1,
'2026-06-01 08:25:00+00:00',
'2026-06-01 08:30:00+00:00',
14.2,
1.18,
'opcua',
'Machine01.Energy.Power_kW',
'Higher power reading shortly before ALM-304.'
),
(
3,
1,
1,
'2026-06-01 08:30:00+00:00',
'2026-06-01 08:35:00+00:00',
2.0,
0.17,
'opcua',
'Machine01.Energy.Power_kW',
'Lower power reading during the ALM-304 fault window.'
),
(
4,
2,
2,
'2026-06-01 13:45:00+00:00',
'2026-06-01 13:55:00+00:00',
1.75,
0.29,
'opcua',
'Machine02.Energy.Power_kW',
'Low energy reading during setup activity.'
);

INSERT INTO machine_events (
id,
machine_db_id,
order_db_id,
event_time_utc,
event_type,
event_value,
event_source,
severity,
source_tag,
description
) VALUES
(
1,
1,
1,
'2026-06-01 06:05:00+00:00',
'state_change',
'automatic_production',
'PLC',
'info',
'Machine01.State.Mode',
'Machine changed to automatic production mode for ORD-2026-001.'
),
(
2,
1,
1,
'2026-06-01 08:30:00+00:00',
'fault',
'ALM-304',
'PLC',
'critical',
'Machine01.Events.FaultCode',
'Packaging jam fault event corresponding to ALM-304.'
),
(
3,
1,
1,
'2026-06-01 08:31:00+00:00',
'operator_action',
'alarm_acknowledged',
'HMI',
'info',
'Machine01.Operator.Action',
'Operator acknowledged ALM-304.'
),
(
4,
1,
1,
'2026-06-01 08:42:00+00:00',
'state_change',
'automatic_production_restarted',
'PLC',
'info',
'Machine01.State.Mode',
'Machine returned to automatic production after the ALM-304 fault window.'
),
(
5,
2,
2,
'2026-06-01 13:45:00+00:00',
'state_change',
'setup_mode',
'PLC',
'warning',
'Machine02.State.Mode',
'Assembly station setup state detected before planned production order ORD-2026-002.'
);
