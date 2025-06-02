DROP TYPE IF EXISTS equipment_type CASCADE;
DROP TYPE IF EXISTS equipment_status CASCADE;

DROP VIEW IF EXISTS employees_view;

DROP TRIGGER IF EXISTS pesel_check ON employees CASCADE;
DROP FUNCTION IF EXISTS pesel_check CASCADE;

DROP TABLE IF EXISTS
    employee_departments_history,
    employee_positions_history,
    employee_teams_history,
    departments,
    addresses,
    cities,
    regions,
    countries,
    schedule_exceptions,
    position_schedules,
    employee_days,
    vacations,
    tasks,
    teams,
    projects,
    employees,
    positions,
    employee_name_history,
    head_departments_history,
    equipment,
    equipment_status_history,
    employee_equipment_history
CASCADE;

