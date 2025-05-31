DROP TYPE IF EXISTS equipment_type CASCADE;
DROP TYPE IF EXISTS equipment_status CASCADE;

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
    equipment,
    teams,
    projects,
    employees,
    positions,
    employee_name_history,
    head_departments_history
CASCADE;